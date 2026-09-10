import 'dart:async';
import '../models/download_task.dart';
import 'queue_manager.dart';

class SchedulerService {
  static final SchedulerService instance = SchedulerService._internal();
  Timer? _timer;

  SchedulerService._internal();

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _checkScheduledTasks());
  }

  void stop() {
    _timer?.cancel();
  }

  void _checkScheduledTasks() {
    final now = DateTime.now();
    final tasks = QueueManager.instance.tasks;

    for (final task in tasks) {
      if (task.isScheduled && task.scheduledTime != null) {
        if (now.isAfter(task.scheduledTime!) &&
            (task.status == DownloadStatus.paused || task.status == DownloadStatus.queued)) {
          task.isScheduled = false; // triggered
          QueueManager.instance.resumeTask(task.id);
        }
      }
    }
  }
}
