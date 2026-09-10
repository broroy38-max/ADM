import 'package:flutter/material.dart';
import '../../models/app_settings.dart';
import '../../models/download_task.dart';
import '../theme/app_theme.dart';

class SpeedCard extends StatelessWidget {
  final double currentSpeed;
  final int activeCount;
  final int queuedCount;
  final int failedCount;
  final int todayBytes;
  final EnginePerformanceMode performanceMode;

  const SpeedCard({
    super.key,
    required this.currentSpeed,
    required this.activeCount,
    required this.queuedCount,
    required this.failedCount,
    required this.todayBytes,
    required this.performanceMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading = currentSpeed > 0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D324D), Color(0xFF1E283A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryCyan.withAlpha(isDownloading ? 40 : 15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDownloading
              ? AppTheme.primaryCyan.withAlpha(100)
              : Colors.white.withAlpha(20),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDownloading ? AppTheme.neonGreen : Colors.white38,
                      boxShadow: isDownloading
                          ? [
                              BoxShadow(
                                color: AppTheme.neonGreen.withAlpha(180),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isDownloading ? 'DOWNLOADING' : 'IDLE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isDownloading ? AppTheme.neonGreen : Colors.white54,
                    ),
                  ),
                ],
              ),
              _buildModeBadge(performanceMode),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Icon(
                Icons.arrow_downward_rounded,
                color: isDownloading ? AppTheme.primaryCyan : Colors.white54,
                size: 32,
              ),
              const SizedBox(width: 6),
              Text(
                DownloadTask.formatSpeed(currentSpeed),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem(
                label: 'Active',
                value: '$activeCount',
                color: AppTheme.primaryCyan,
                icon: Icons.download_rounded,
              ),
              _buildMetricItem(
                label: 'Queued',
                value: '$queuedCount',
                color: Colors.amber,
                icon: Icons.hourglass_top_rounded,
              ),
              _buildMetricItem(
                label: 'Failed',
                value: '$failedCount',
                color: failedCount > 0 ? AppTheme.dangerRed : Colors.white38,
                icon: Icons.error_outline_rounded,
              ),
              _buildMetricItem(
                label: 'Today',
                value: DownloadTask.formatBytes(todayBytes),
                color: AppTheme.neonGreen,
                icon: Icons.data_usage_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeBadge(EnginePerformanceMode mode) {
    String text;
    Color color;
    switch (mode) {
      case EnginePerformanceMode.turbo:
        text = '⚡ TURBO';
        color = AppTheme.primaryCyan;
        break;
      case EnginePerformanceMode.balanced:
        text = '⚖️ BALANCED';
        color = Colors.tealAccent;
        break;
      case EnginePerformanceMode.batterySaver:
        text = '🔋 SAVER';
        color = Colors.greenAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
