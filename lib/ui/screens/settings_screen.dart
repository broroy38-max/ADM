import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SettingsProvider>(context);
    final settings = provider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Engine & Performance
          _buildSectionHeader('DOWNLOAD ENGINE'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Performance Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<EnginePerformanceMode>(
                    segments: const [
                      ButtonSegment(value: EnginePerformanceMode.turbo, label: Text('⚡ Turbo')),
                      ButtonSegment(value: EnginePerformanceMode.balanced, label: Text('Balanced')),
                      ButtonSegment(value: EnginePerformanceMode.batterySaver, label: Text('🔋 Saver')),
                    ],
                    selected: {settings.performanceMode},
                    onSelectionChanged: (set) {
                      provider.setPerformanceMode(set.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Default Connections'),
                      DropdownButton<int>(
                        value: settings.defaultConnections,
                        dropdownColor: const Color(0xFF1E283A),
                        items: [1, 2, 4, 8, 16, 32].map((c) {
                          return DropdownMenuItem(value: c, child: Text('$c Connections'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) provider.setDefaultConnections(val);
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Max Concurrent Downloads'),
                      DropdownButton<int>(
                        value: settings.maxConcurrentDownloads,
                        dropdownColor: const Color(0xFF1E283A),
                        items: List.generate(10, (i) => i + 1).map((c) {
                          return DropdownMenuItem(value: c, child: Text('$c Active Tasks'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            settings.maxConcurrentDownloads = val;
                            provider.updateSettings(settings);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section: Network & Battery
          _buildSectionHeader('NETWORK & BATTERY'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Wi-Fi Only Downloads'),
                  subtitle: const Text('Only download files when connected to Wi-Fi'),
                  value: settings.wifiOnly,
                  activeThumbColor: AppTheme.primaryCyan,
                  onChanged: (v) {
                    settings.wifiOnly = v;
                    provider.updateSettings(settings);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Auto-Resume on Wi-Fi'),
                  subtitle: const Text('Resume paused downloads when Wi-Fi is restored'),
                  value: settings.autoResumeOnWifi,
                  activeThumbColor: AppTheme.primaryCyan,
                  onChanged: (v) {
                    settings.autoResumeOnWifi = v;
                    provider.updateSettings(settings);
                  },
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Battery Saver Cutoff'),
                      DropdownButton<int>(
                        value: settings.batterySaverThreshold,
                        dropdownColor: const Color(0xFF1E283A),
                        items: [10, 15, 20, 25].map((b) => DropdownMenuItem(value: b, child: Text('$b%'))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            settings.batterySaverThreshold = val;
                            provider.updateSettings(settings);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section: Appearance (Light, Dark, AMOLED Black)
          _buildSectionHeader('APPEARANCE & THEME'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SegmentedButton<ADMThemeMode>(
                    segments: const [
                      ButtonSegment(value: ADMThemeMode.dark, label: Text('Dark')),
                      ButtonSegment(value: ADMThemeMode.amoled, label: Text('AMOLED')),
                      ButtonSegment(value: ADMThemeMode.light, label: Text('Light')),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (set) {
                      provider.setThemeMode(set.first);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section: Storage & Collisions
          _buildSectionHeader('STORAGE & FILES'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Auto-Categorize Folders'),
                  subtitle: const Text('Sort files into Movies, Music, Documents, Apps'),
                  value: settings.autoCategorize,
                  activeThumbColor: AppTheme.primaryCyan,
                  onChanged: (v) {
                    settings.autoCategorize = v;
                    provider.updateSettings(settings);
                  },
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Duplicate File Action'),
                      DropdownButton<CollisionStrategy>(
                        value: settings.collisionStrategy,
                        dropdownColor: const Color(0xFF1E283A),
                        items: const [
                          DropdownMenuItem(value: CollisionStrategy.rename, child: Text('Auto Rename')),
                          DropdownMenuItem(value: CollisionStrategy.overwrite, child: Text('Overwrite')),
                          DropdownMenuItem(value: CollisionStrategy.resume, child: Text('Resume')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            settings.collisionStrategy = val;
                            provider.updateSettings(settings);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section: Backup & Restore
          _buildSectionHeader('BACKUP & RESTORE'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final path = await BackupService.instance.exportBackup(settings);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Backup saved to: $path')),
                              );
                            }
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Export Backup'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final backups = await BackupService.instance.getAvailableBackups();
                            if (!context.mounted) return;
                            if (backups.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No backup files found yet. Export one first!')),
                              );
                              return;
                            }
                            showDialog(
                              context: context,
                              builder: (ctx) {
                                return AlertDialog(
                                  backgroundColor: const Color(0xFF192231),
                                  title: const Text('Select Backup to Restore'),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: backups.length,
                                      itemBuilder: (context, index) {
                                        final b = backups[index];
                                        return ListTile(
                                          leading: const Icon(Icons.history_rounded, color: AppTheme.primaryCyan),
                                          title: Text(p.basename(b.path), style: const TextStyle(fontSize: 12)),
                                          subtitle: Text(
                                            'Modified: ${b.lastModifiedSync().toString().substring(0, 16)}',
                                            style: const TextStyle(fontSize: 10, color: Colors.white54),
                                          ),
                                          onTap: () async {
                                            Navigator.pop(ctx);
                                            final ok = await BackupService.instance.importBackup(b.path);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(ok ? 'Backup successfully restored!' : 'Failed to parse backup')),
                                              );
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.download_for_offline),
                          label: const Text('Restore Backup'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // App info
          const Center(
            child: Text(
              'ADM — Advanced Download Manager v2.0.0\nHigh-Speed Multi-Threaded Engine',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white30, height: 1.5),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: Colors.white54,
        ),
      ),
    );
  }
}
