import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
                            final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
                            if (res != null && res.files.single.path != null) {
                              final success = await BackupService.instance.importBackup(res.files.single.path!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(success ? 'Backup restored!' : 'Failed to parse backup')),
                                );
                              }
                            }
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
