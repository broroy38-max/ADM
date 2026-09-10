import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/download_provider.dart';
import '../../services/assistant_service.dart';
import '../theme/app_theme.dart';

class SmartAssistantDialog extends StatefulWidget {
  const SmartAssistantDialog({super.key});

  @override
  State<SmartAssistantDialog> createState() => _SmartAssistantDialogState();
}

class _SmartAssistantDialogState extends State<SmartAssistantDialog> {
  final TextEditingController _promptController = TextEditingController();
  AssistantConfigProposal? _proposal;

  void _analyzePrompt() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final result = AssistantService.instance.parsePrompt(prompt);
    setState(() {
      _proposal = result;
    });
  }

  void _confirmProposal() {
    if (_proposal == null) return;
    final provider = Provider.of<DownloadProvider>(context, listen: false);

    if (_proposal!.urls.isNotEmpty) {
      for (final url in _proposal!.urls) {
        provider.addNewDownload(
          url: url,
          connections: _proposal!.connections,
          priority: _proposal!.priority,
          wifiOnly: _proposal!.wifiOnly,
          isScheduled: _proposal!.scheduledTime != null,
          scheduledTime: _proposal!.scheduledTime,
        );
      }
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scheduled ${_proposal!.urls.length} downloads successfully!'),
        backgroundColor: AppTheme.neonGreen,
      ),
    );
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
                    color: Colors.purpleAccent.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI DOWNLOAD ASSISTANT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Natural Language Task Parser',
                      style: TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Describe your download request in Bengali or English:',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _promptController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Example: "https://example.com/file.zip রাত ২টায় Wi-Fi দিয়ে download করো urgent"',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.white30),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: _analyzePrompt,
                icon: const Icon(Icons.psychology, size: 18),
                label: const Text('GENERATE CONFIG'),
              ),
            ),

            if (_proposal != null) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryCyan.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PROPOSED CONFIGURATION:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryCyan,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _proposal!.summary,
                      style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
                    ),
                    if (_proposal!.urls.isEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '⚠️ No URLs detected. Please include https:// links in your prompt.',
                        style: TextStyle(fontSize: 11, color: Colors.amberAccent),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonGreen,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _proposal!.urls.isNotEmpty ? _confirmProposal : null,
                    child: const Text('CONFIRM & QUEUE', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
