import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/download_task.dart';
import '../../providers/download_provider.dart';
import '../../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class AddDownloadDialog extends StatefulWidget {
  final String? initialUrl;

  const AddDownloadDialog({super.key, this.initialUrl});

  @override
  State<AddDownloadDialog> createState() => _AddDownloadDialogState();
}

class _AddDownloadDialogState extends State<AddDownloadDialog> {
  late final TextEditingController _urlController;
  final TextEditingController _filenameController = TextEditingController();
  final TextEditingController _checksumController = TextEditingController();

  int _connections = 8;
  DownloadPriority _priority = DownloadPriority.normal;
  bool _wifiOnly = false;
  bool _isScheduled = false;
  TimeOfDay? _scheduledTime;
  final String _checksumType = 'sha256';

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      final uri = Uri.tryParse(widget.initialUrl!);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        final lastSeg = uri.pathSegments.last.split('?').first;
        if (lastSeg.isNotEmpty) {
          try {
            _filenameController.text = Uri.decodeComponent(lastSeg);
          } catch (_) {
            _filenameController.text = lastSeg;
          }
        }
      }
    }

    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
    _connections = settings.defaultConnections;
    _wifiOnly = settings.wifiOnly;

    _urlController.addListener(() {
      if (_filenameController.text.isEmpty && _urlController.text.isNotEmpty) {
        final uri = Uri.tryParse(_urlController.text);
        if (uri != null && uri.pathSegments.isNotEmpty) {
          final lastSeg = uri.pathSegments.last.split('?').first;
          if (lastSeg.isNotEmpty) {
            try {
              _filenameController.text = Uri.decodeComponent(lastSeg);
            } catch (_) {
              _filenameController.text = lastSeg;
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _filenameController.dispose();
    _checksumController.dispose();
    super.dispose();
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      setState(() {
        _urlController.text = data!.text!.trim();
      });
    }
  }

  void _pickScheduleTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _scheduledTime = picked;
        _isScheduled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF192231),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
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
                    color: AppTheme.primaryCyan.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_link_rounded, color: AppTheme.primaryCyan, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'NEW DOWNLOAD',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // URL input with Paste button
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Download URL',
                hintText: 'https://...',
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste_rounded, color: AppTheme.primaryCyan),
                  onPressed: _pasteFromClipboard,
                  tooltip: 'Paste from clipboard',
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filename input
            TextField(
              controller: _filenameController,
              decoration: InputDecoration(
                labelText: 'Filename (Optional)',
                hintText: 'Auto-detected from URL',
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Connections selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Connections:', style: TextStyle(color: Colors.white70)),
                DropdownButton<int>(
                  value: _connections,
                  dropdownColor: const Color(0xFF1E283A),
                  items: [1, 2, 4, 8, 16, 32].map((c) {
                    return DropdownMenuItem<int>(
                      value: c,
                      child: Text('$c Connections', style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _connections = val);
                  },
                ),
              ],
            ),

            // Priority selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Priority:', style: TextStyle(color: Colors.white70)),
                DropdownButton<DownloadPriority>(
                  value: _priority,
                  dropdownColor: const Color(0xFF1E283A),
                  items: DownloadPriority.values.map((p) {
                    return DropdownMenuItem<DownloadPriority>(
                      value: p,
                      child: Text(
                        p.name.toUpperCase(),
                        style: TextStyle(
                          color: p == DownloadPriority.critical
                              ? AppTheme.dangerRed
                              : p == DownloadPriority.high
                                  ? Colors.amberAccent
                                  : Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _priority = val);
                  },
                ),
              ],
            ),

            const Divider(color: Colors.white12, height: 24),

            // Toggles: Wi-Fi Only & Scheduler
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Wi-Fi Only', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Pause automatically when on mobile data', style: TextStyle(fontSize: 11, color: Colors.white38)),
              value: _wifiOnly,
              activeThumbColor: AppTheme.primaryCyan,
              onChanged: (val) => setState(() => _wifiOnly = val),
            ),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Schedule Download', style: TextStyle(fontSize: 14)),
              subtitle: Text(
                _scheduledTime != null
                    ? 'Starts at ${_scheduledTime!.format(context)}'
                    : 'Download later at specific time',
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
              value: _isScheduled,
              activeThumbColor: AppTheme.primaryCyan,
              onChanged: (val) {
                if (val) {
                  _pickScheduleTime();
                } else {
                  setState(() {
                    _isScheduled = false;
                    _scheduledTime = null;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    final url = _urlController.text.trim();
                    if (url.isEmpty) return;

                    DateTime? schedDateTime;
                    if (_isScheduled && _scheduledTime != null) {
                      final now = DateTime.now();
                      schedDateTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        _scheduledTime!.hour,
                        _scheduledTime!.minute,
                      );
                      if (schedDateTime.isBefore(now)) {
                        schedDateTime = schedDateTime.add(const Duration(days: 1));
                      }
                    }

                    Provider.of<DownloadProvider>(context, listen: false).addNewDownload(
                      url: url,
                      customFilename: _filenameController.text.trim().isNotEmpty
                          ? _filenameController.text.trim()
                          : null,
                      connections: _connections,
                      priority: _priority,
                      wifiOnly: _wifiOnly,
                      isScheduled: _isScheduled,
                      scheduledTime: schedDateTime,
                      checksumExpected: _checksumController.text.trim().isNotEmpty
                          ? _checksumController.text.trim()
                          : null,
                      checksumType: _checksumType,
                    );

                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('START DOWNLOAD', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
