import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/download_task.dart';
import '../../providers/download_provider.dart';
import '../theme/app_theme.dart';
import 'diagnostics_dialog.dart';
import 'segment_progress_bar.dart';

class DownloadCard extends StatelessWidget {
  final DownloadTask task;

  const DownloadCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DownloadProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon, Filename, Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryIcon(task.category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.filename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatusBadge(task.status),
                          const SizedBox(width: 6),
                          if (task.priority == DownloadPriority.critical ||
                              task.priority == DownloadPriority.high)
                            _buildPriorityBadge(task.priority),
                          const SizedBox(width: 6),
                          Text(
                            task.supportsRange
                                ? '${task.connections} Conns'
                                : 'Single Conn',
                            style: const TextStyle(fontSize: 11, color: Colors.white54),
                          ),
                          if (task.wifiOnly) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.wifi, size: 12, color: AppTheme.primaryCyan),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                _buildTrailingAction(context, provider),
              ],
            ),

            const SizedBox(height: 12),

            // Progress Bar (with dynamic segment chunks)
            SegmentProgressBar(
              segments: task.segments,
              overallProgress: task.progress,
              height: 6.0,
            ),

            const SizedBox(height: 10),

            // Stats row: Downloaded / Total • Speed • ETA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${task.formattedDownloadedSize} / ${task.totalBytes > 0 ? task.formattedTotalSize : "Unknown"} (${(task.progress * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                if (task.isActive && task.speed > 0)
                  Text(
                    '${task.formattedSpeed} • ${task.formattedEta}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryCyan,
                    ),
                  ),
                if (task.isDone)
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.neonGreen),
                      SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neonGreen,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Error banner if failed
            if (task.isFailed && task.failureReason != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dangerRed.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.dangerRed),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task.failureReason!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => DiagnosticsDialog(task: task),
                        );
                      },
                      child: const Text(
                        'DIAGNOSE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryCyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(DownloadCategory category) {
    IconData icon;
    Color color;

    switch (category) {
      case DownloadCategory.video:
        icon = Icons.movie_outlined;
        color = Colors.purpleAccent;
        break;
      case DownloadCategory.music:
        icon = Icons.music_note_outlined;
        color = Colors.pinkAccent;
        break;
      case DownloadCategory.document:
        icon = Icons.description_outlined;
        color = Colors.blueAccent;
        break;
      case DownloadCategory.archive:
        icon = Icons.folder_zip_outlined;
        color = Colors.amberAccent;
        break;
      case DownloadCategory.app:
        icon = Icons.android_outlined;
        color = AppTheme.neonGreen;
        break;
      case DownloadCategory.image:
        icon = Icons.image_outlined;
        color = Colors.tealAccent;
        break;
      case DownloadCategory.other:
        icon = Icons.insert_drive_file_outlined;
        color = Colors.white54;
        break;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildStatusBadge(DownloadStatus status) {
    String text;
    Color color;

    switch (status) {
      case DownloadStatus.downloading:
        text = 'Downloading';
        color = AppTheme.primaryCyan;
        break;
      case DownloadStatus.connecting:
        text = 'Connecting';
        color = Colors.cyan;
        break;
      case DownloadStatus.queued:
        text = 'Queued';
        color = Colors.amber;
        break;
      case DownloadStatus.paused:
        text = 'Paused';
        color = Colors.white54;
        break;
      case DownloadStatus.completed:
        text = 'Completed';
        color = AppTheme.neonGreen;
        break;
      case DownloadStatus.failed:
        text = 'Failed';
        color = AppTheme.dangerRed;
        break;
      case DownloadStatus.cancelled:
        text = 'Cancelled';
        color = Colors.white38;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildPriorityBadge(DownloadPriority priority) {
    final isCritical = priority == DownloadPriority.critical;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isCritical ? AppTheme.dangerRed : Colors.orangeAccent).withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isCritical ? 'CRITICAL' : 'HIGH',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isCritical ? AppTheme.dangerRed : Colors.orangeAccent,
        ),
      ),
    );
  }

  Widget _buildTrailingAction(BuildContext context, DownloadProvider provider) {
    if (task.isActive) {
      return IconButton(
        icon: const Icon(Icons.pause_circle_outline_rounded, color: Colors.white70),
        onPressed: () => provider.pauseTask(task.id),
      );
    } else if (task.isPaused || task.status == DownloadStatus.cancelled) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline_rounded, color: AppTheme.primaryCyan),
            onPressed: () => provider.resumeTask(task.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.white38),
            onPressed: () => provider.deleteTask(task.id),
          ),
        ],
      );
    } else if (task.isFailed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.amber),
            onPressed: () => provider.retryTask(task.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.white38),
            onPressed: () => provider.deleteTask(task.id),
          ),
        ],
      );
    } else {
      // Completed
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20, color: Colors.white70),
            onPressed: () {
              Share.shareXFiles([XFile(task.savePath)], text: task.filename);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.white38),
            onPressed: () => provider.deleteTask(task.id),
          ),
        ],
      );
    }
  }
}
