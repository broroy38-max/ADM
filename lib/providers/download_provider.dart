import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/app_settings.dart';
import '../models/download_task.dart';
import '../services/database_service.dart';
import '../services/queue_manager.dart';
import '../services/storage_service.dart';

class DownloadProvider extends ChangeNotifier {
  List<DownloadTask> _tasks = [];
  double _globalSpeed = 0.0;
  List<double> _speedHistory = List.filled(30, 0.0);
  int _todayDownloadedBytes = 0;
  String _searchQuery = '';
  DownloadCategory? _selectedCategoryFilter;

  StreamSubscription? _tasksSub;
  StreamSubscription? _speedSub;
  StreamSubscription? _historySub;

  List<DownloadTask> get tasks => _tasks;
  double get globalSpeed => _globalSpeed;
  List<double> get speedHistory => _speedHistory;
  int get todayDownloadedBytes => _todayDownloadedBytes;
  String get searchQuery => _searchQuery;
  DownloadCategory? get selectedCategoryFilter => _selectedCategoryFilter;

  int get activeCount => _tasks.where((t) => t.isActive).length;
  int get queuedCount => _tasks.where((t) => t.isQueued).length;
  int get failedCount => _tasks.where((t) => t.isFailed).length;
  int get completedCount => _tasks.where((t) => t.isDone).length;

  List<DownloadTask> get filteredTasks {
    return _tasks.where((t) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!t.filename.toLowerCase().contains(q) && !t.url.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_selectedCategoryFilter != null) {
        if (t.category != _selectedCategoryFilter) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> init(AppSettings settings) async {
    await QueueManager.instance.init(settings);
    _tasks = List.from(QueueManager.instance.tasks);
    _todayDownloadedBytes = await DatabaseService.instance.getTodayDownloadedBytes();

    _tasksSub = QueueManager.instance.onTasksChanged.listen((updatedTasks) async {
      _tasks = List.from(updatedTasks);
      _todayDownloadedBytes = await DatabaseService.instance.getTodayDownloadedBytes();
      notifyListeners();
    });

    _speedSub = QueueManager.instance.onGlobalSpeedChanged.listen((speed) {
      _globalSpeed = speed;
      notifyListeners();
    });

    _speedSub = QueueManager.instance.onSpeedHistoryChanged.listen((history) {
      _speedHistory = List.from(history);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _tasksSub?.cancel();
    _speedSub?.cancel();
    _historySub?.cancel();
    super.dispose();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(DownloadCategory? category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  Future<void> addNewDownload({
    required String url,
    String? customFilename,
    int? connections,
    DownloadPriority priority = DownloadPriority.normal,
    bool wifiOnly = false,
    bool isScheduled = false,
    DateTime? scheduledTime,
    Map<String, String>? customHeaders,
    String? checksumExpected,
    String? checksumType,
    bool isInbox = false,
  }) async {
    // 1. Determine filename
    String filename = customFilename?.trim() ?? '';
    if (filename.isEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        filename = uri.pathSegments.last;
      }
      if (filename.isEmpty) {
        filename = 'download_${DateTime.now().millisecondsSinceEpoch}';
      }
    }
    filename = StorageService.instance.sanitizeFilename(filename);
    var category = DownloadTask.detectCategory(filename);

    // 2. Check Smart Rules
    final rules = await DatabaseService.instance.getAllSmartRules();
    int activeConnections = connections ?? QueueManager.instance.settings.defaultConnections;
    DownloadPriority activePriority = priority;
    bool activeWifiOnly = wifiOnly;

    for (final rule in rules) {
      if (rule.matches(url, filename)) {
        if (rule.targetCategory != null) category = rule.targetCategory!;
        if (rule.connections != null) activeConnections = rule.connections!;
        if (rule.priority != null) activePriority = rule.priority!;
        if (rule.wifiOnly != null) activeWifiOnly = rule.wifiOnly!;
        break;
      }
    }

    // 3. Resolve destination folder
    final targetFolder = await StorageService.instance.getCategorySubfolder(category, isInbox: isInbox);
    final resolvedPath = await StorageService.instance.resolveTargetFilePath(
      targetFolder,
      filename,
      QueueManager.instance.settings.collisionStrategy,
    );

    // 4. Create Task
    final task = DownloadTask(
      id: 'task_${DateTime.now().microsecondsSinceEpoch}',
      url: url,
      filename: p.basename(resolvedPath),
      savePath: resolvedPath,
      category: category,
      status: isScheduled ? DownloadStatus.paused : DownloadStatus.queued,
      connections: activeConnections,
      priority: activePriority,
      wifiOnly: activeWifiOnly,
      isScheduled: isScheduled,
      scheduledTime: scheduledTime,
      customHeaders: customHeaders,
      checksumExpected: checksumExpected,
      checksumType: checksumType ?? 'sha256',
    );

    await QueueManager.instance.addTask(task);
  }

  Future<void> addBatchUrls(List<String> urls, {bool wifiOnly = false, DateTime? scheduledTime}) async {
    for (final url in urls) {
      final trimmed = url.trim();
      if (trimmed.isNotEmpty && (trimmed.startsWith('http://') || trimmed.startsWith('https://'))) {
        await addNewDownload(
          url: trimmed,
          wifiOnly: wifiOnly,
          isScheduled: scheduledTime != null,
          scheduledTime: scheduledTime,
        );
      }
    }
  }

  void pauseTask(String taskId) => QueueManager.instance.pauseTask(taskId);
  void resumeTask(String taskId) => QueueManager.instance.resumeTask(taskId);
  void cancelTask(String taskId) => QueueManager.instance.cancelTask(taskId);
  void deleteTask(String taskId, {bool deleteFile = false}) =>
      QueueManager.instance.deleteTask(taskId, deleteFile: deleteFile);
  void retryTask(String taskId) => QueueManager.instance.retryTask(taskId);
}
