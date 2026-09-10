import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/app_settings.dart';
import '../models/download_diagnostics.dart';
import '../models/download_task.dart';
import 'database_service.dart';
import 'download_engine.dart';
import 'network_service.dart';

class QueueManager {
  static final QueueManager instance = QueueManager._internal();

  final List<DownloadTask> _tasks = [];
  AppSettings settings = AppSettings();

  final StreamController<List<DownloadTask>> _tasksController =
      StreamController<List<DownloadTask>>.broadcast();
  final StreamController<double> _globalSpeedController =
      StreamController<double>.broadcast();
  final StreamController<List<double>> _speedHistoryController =
      StreamController<List<double>>.broadcast();

  final List<double> _speedHistory = List.filled(30, 0.0);
  Timer? _graphTickTimer;

  QueueManager._internal() {
    _initEngineListeners();
  }

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);
  Stream<List<DownloadTask>> get onTasksChanged => _tasksController.stream;
  Stream<double> get onGlobalSpeedChanged => _globalSpeedController.stream;
  Stream<List<double>> get onSpeedHistoryChanged => _speedHistoryController.stream;

  double get globalSpeed {
    double total = 0.0;
    for (final t in _tasks) {
      if (t.status == DownloadStatus.downloading) {
        total += t.speed;
      }
    }
    return total;
  }

  int get activeCount =>
      _tasks.where((t) => t.status == DownloadStatus.downloading || t.status == DownloadStatus.connecting).length;
  int get queuedCount => _tasks.where((t) => t.status == DownloadStatus.queued).length;
  int get failedCount => _tasks.where((t) => t.status == DownloadStatus.failed).length;
  int get completedCount => _tasks.where((t) => t.status == DownloadStatus.completed).length;

  Future<void> init(AppSettings appSettings) async {
    settings = appSettings;
    final loaded = await DatabaseService.instance.getAllTasks();
    _tasks.clear();
    _tasks.addAll(loaded);
    _tasksController.add(_tasks);

    _startGraphTicker();
    _checkQueue();
  }

  void _initEngineListeners() {
    // Network listeners
    NetworkService.instance.onConnectivityChanged.listen((results) {
      final isWifi = results.contains(ConnectivityResult.wifi);
      if (!isWifi) {
        // Check if any active task requires Wi-Fi
        for (final task in _tasks) {
          if (task.status == DownloadStatus.downloading && (task.wifiOnly || settings.wifiOnly)) {
            pauseTask(task.id);
            task.failureReason = 'Paused: Wi-Fi connection lost';
          }
        }
      } else {
        // Auto-resume if enabled
        if (settings.autoResumeOnWifi) {
          for (final task in _tasks) {
            if (task.status == DownloadStatus.paused &&
                (task.failureReason?.contains('Wi-Fi') ?? false)) {
              resumeTask(task.id);
            }
          }
        }
      }
    });

    // Battery listeners
    NetworkService.instance.onBatteryChanged.listen((level) {
      if (level <= settings.batterySaverThreshold && !NetworkService.instance.isCharging) {
        // Battery saver: reduce concurrency or pause normal/low priority tasks
        for (final task in _tasks) {
          if (task.status == DownloadStatus.downloading &&
              (task.priority == DownloadPriority.normal || task.priority == DownloadPriority.low)) {
            pauseTask(task.id);
            task.failureReason = 'Paused: Battery saver mode';
          }
        }
      }
    });
  }

  void _startGraphTicker() {
    _graphTickTimer?.cancel();
    _graphTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = globalSpeed;
      _speedHistory.removeAt(0);
      _speedHistory.add(current);
      _globalSpeedController.add(current);
      _speedHistoryController.add(List.from(_speedHistory));
    });
  }

  Future<void> addTask(DownloadTask task) async {
    _tasks.insert(0, task);
    await DatabaseService.instance.insertTask(task);
    _notify();
    _checkQueue();
  }

  Future<void> pauseTask(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final task = _tasks[idx];
      MultiSegmentEngine.instance.pauseDownload(task.id);
      task.status = DownloadStatus.paused;
      task.speed = 0;
      await DatabaseService.instance.updateTask(task);
      _notify();
      _checkQueue();
    }
  }

  Future<void> resumeTask(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final task = _tasks[idx];
      task.status = DownloadStatus.queued;
      task.failureReason = null;
      task.suggestedAction = null;
      await DatabaseService.instance.updateTask(task);
      _notify();
      _checkQueue();
    }
  }

  Future<void> cancelTask(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final task = _tasks[idx];
      MultiSegmentEngine.instance.cancelDownload(task.id);
      task.status = DownloadStatus.cancelled;
      task.speed = 0;
      await DatabaseService.instance.updateTask(task);
      _notify();
      _checkQueue();
    }
  }

  Future<void> deleteTask(String taskId, {bool deleteFile = false}) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final task = _tasks[idx];
      MultiSegmentEngine.instance.cancelDownload(task.id);
      _tasks.removeAt(idx);
      await DatabaseService.instance.deleteTask(taskId);
      _notify();
      _checkQueue();
    }
  }

  Future<void> retryTask(String taskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final task = _tasks[idx];
      task.status = DownloadStatus.queued;
      task.retryCount++;
      task.failureReason = null;
      task.failureDetails = null;
      task.suggestedAction = null;
      await DatabaseService.instance.updateTask(task);
      _notify();
      _checkQueue();
    }
  }

  void _checkQueue() {
    // Count active
    int currentActive = activeCount;
    if (currentActive >= settings.maxConcurrentDownloads) return;

    // Filter queued tasks
    final queuedTasks = _tasks.where((t) => t.status == DownloadStatus.queued).toList();
    if (queuedTasks.isEmpty) return;

    // Sort by priority (critical > high > normal > low)
    queuedTasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    while (currentActive < settings.maxConcurrentDownloads && queuedTasks.isNotEmpty) {
      final nextTask = queuedTasks.removeAt(0);

      // Check Wi-Fi constraint
      if ((nextTask.wifiOnly || settings.wifiOnly) && !NetworkService.instance.isWifiConnected) {
        continue;
      }

      currentActive++;
      _startTask(nextTask);
    }
  }

  void _startTask(DownloadTask task) {
    MultiSegmentEngine.instance.startDownload(
      task,
      settings: settings,
      onProgress: (updated) {
        _notify();
      },
      onCompleted: (completed) async {
        _notify();
        _checkQueue();
      },
      onError: (failedTask, error, statusCode) async {
        _handleTaskError(failedTask, error, statusCode);
        _notify();
        _checkQueue();
      },
    );
  }

  Future<void> _handleTaskError(DownloadTask task, dynamic error, int? statusCode) async {
    // Generate diagnostics
    final hasInternet = NetworkService.instance.hasNetworkConnection;
    final host = Uri.tryParse(task.url)?.host ?? '';
    final dnsPassed = host.isNotEmpty ? await NetworkService.instance.checkDnsResolution(host) : false;
    final serverReachable = host.isNotEmpty ? await NetworkService.instance.checkHostReachable(host) : false;

    final diag = DownloadDiagnostics.fromError(
      taskId: task.id,
      url: task.url,
      error: error,
      statusCode: statusCode,
      hasInternet: hasInternet,
      dnsPassed: dnsPassed,
      serverReachable: serverReachable,
      rangeSupported: task.supportsRange,
    );

    task.failureReason = diag.reason;
    task.failureDetails = diag.possibleCause;
    task.suggestedAction = diag.suggestedActions.join(' • ');

    // Automatic retry with exponential backoff if retryCount < 3 and transient error
    if (task.retryCount < 3 && (statusCode == null || statusCode >= 500 || statusCode == 429)) {
      task.retryCount++;
      final backoffSeconds = (task.retryCount * 3);
      Timer(Duration(seconds: backoffSeconds), () {
        if (task.status == DownloadStatus.failed) {
          task.status = DownloadStatus.queued;
          _notify();
          _checkQueue();
        }
      });
    }

    await DatabaseService.instance.updateTask(task);
  }

  void _notify() {
    _tasksController.add(List.unmodifiable(_tasks));
  }
}
