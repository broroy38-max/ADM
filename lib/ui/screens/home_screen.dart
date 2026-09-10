import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/download_task.dart';
import '../../providers/download_provider.dart';
import '../../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_download_dialog.dart';
import '../widgets/download_card.dart';
import '../widgets/live_speed_graph.dart';
import '../widgets/smart_assistant_dialog.dart';
import '../widgets/speed_card.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToBrowser;
  final VoidCallback onNavigateToTools;

  const HomeScreen({
    super.key,
    required this.onNavigateToBrowser,
    required this.onNavigateToTools,
  });

  @override
  Widget build(BuildContext context) {
    final downloadProvider = Provider.of<DownloadProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    final activeTasks = downloadProvider.tasks
        .where((t) => t.status == DownloadStatus.downloading || t.status == DownloadStatus.connecting)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt_rounded, color: AppTheme.primaryCyan, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'ADM',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'v2.0 NEXT-GEN',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.purpleAccent),
            tooltip: 'AI Download Assistant',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const SmartAssistantDialog(),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Speed Card (Specification #1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SpeedCard(
                  currentSpeed: downloadProvider.globalSpeed,
                  activeCount: downloadProvider.activeCount,
                  queuedCount: downloadProvider.queuedCount,
                  failedCount: downloadProvider.failedCount,
                  todayBytes: downloadProvider.todayDownloadedBytes,
                  performanceMode: settingsProvider.settings.performanceMode,
                ),
              ),

              // Live Speed Graph (Specification #1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: LiveSpeedGraph(speedHistory: downloadProvider.speedHistory),
              ),

              const SizedBox(height: 12),

              // Quick Actions Grid (Specification #1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QUICK ACTIONS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildQuickActionBtn(
                          context: context,
                          icon: Icons.add_link_rounded,
                          label: 'Add URL',
                          color: AppTheme.primaryCyan,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => const AddDownloadDialog(),
                            );
                          },
                        ),
                        _buildQuickActionBtn(
                          context: context,
                          icon: Icons.content_paste_rounded,
                          label: 'Paste Link',
                          color: Colors.amberAccent,
                          onTap: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null && context.mounted) {
                              showDialog(
                                context: context,
                                builder: (_) => AddDownloadDialog(initialUrl: data!.text),
                              );
                            }
                          },
                        ),
                        _buildQuickActionBtn(
                          context: context,
                          icon: Icons.language_rounded,
                          label: 'Browser',
                          color: Colors.blueAccent,
                          onTap: onNavigateToBrowser,
                        ),
                        _buildQuickActionBtn(
                          context: context,
                          icon: Icons.hub_outlined,
                          label: 'Tools',
                          color: Colors.pinkAccent,
                          onTap: onNavigateToTools,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Active Downloads Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'ACTIVE DOWNLOADS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: activeTasks.isNotEmpty
                                ? AppTheme.primaryCyan.withAlpha(40)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${activeTasks.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: activeTasks.isNotEmpty
                                  ? AppTheme.primaryCyan
                                  : Colors.white38,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              if (activeTasks.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.cloud_download_outlined, size: 48, color: Colors.white24),
                        const SizedBox(height: 12),
                        const Text(
                          'No active downloads',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap + or Quick Actions to start high-speed download',
                          style: TextStyle(color: Colors.white24, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeTasks.length,
                  itemBuilder: (context, index) {
                    return DownloadCard(task: activeTasks[index]);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E283A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
