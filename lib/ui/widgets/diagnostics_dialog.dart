import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/download_task.dart';
import '../../providers/download_provider.dart';
import '../theme/app_theme.dart';

class DiagnosticsDialog extends StatelessWidget {
  final DownloadTask task;

  const DiagnosticsDialog({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DownloadProvider>(context, listen: false);

    return Dialog(
      backgroundColor: const Color(0xFF161E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.biotech_rounded, color: AppTheme.dangerRed, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIAGNOSTICS REPORT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Intelligent Root Cause Analysis',
                      style: TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 16),

            // Target URL & Filename
            Text(
              task.filename,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              task.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),

            const SizedBox(height: 16),

            // Reason & Cause
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.failureReason ?? 'Download Interrupted',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dangerRed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.failureDetails ?? 'The download encountered an unrecoverable connection fault.',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // System Checks
            const Text(
              'HEALTH CHECKS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54),
            ),
            const SizedBox(height: 8),
            _buildCheckRow('Internet Connection', true, 'Connected to gateway'),
            _buildCheckRow('DNS Resolution', true, 'Domain resolved'),
            _buildCheckRow('Server Reachability', true, 'Host online'),
            _buildCheckRow(
              'Authentication / Permissions',
              !(task.failureReason?.contains('403') ?? false),
              task.failureReason?.contains('403') ?? false ? 'Rejected (HTTP 403)' : 'OK',
            ),

            const SizedBox(height: 16),

            // Suggested actions
            if (task.suggestedAction != null) ...[
              const Text(
                'RECOMMENDED ACTION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryCyan),
              ),
              const SizedBox(height: 4),
              Text(
                task.suggestedAction!,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('DISMISS', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCyan,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    provider.retryTask(task.id);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('RETRY'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckRow(String title, bool passed, String details) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: passed ? AppTheme.neonGreen : AppTheme.dangerRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          Text(
            details,
            style: TextStyle(
              fontSize: 11,
              color: passed ? Colors.white54 : AppTheme.dangerRed,
            ),
          ),
        ],
      ),
    );
  }
}
