import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/download_task.dart';
import '../../models/smart_rule.dart';
import '../../providers/download_provider.dart';
import '../../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_assistant_dialog.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final TextEditingController _batchUrlsController = TextEditingController();
  final TextEditingController _qrTextController = TextEditingController();
  String _qrData = 'https://example.com/test.zip';
  List<SmartRule> _rules = [];

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  void _loadRules() async {
    final list = await DatabaseService.instance.getAllSmartRules();
    setState(() {
      _rules = list;
    });
  }

  void _showAddRuleDialog() {
    final nameCtrl = TextEditingController();
    final domainCtrl = TextEditingController();
    final extCtrl = TextEditingController();
    int connections = 16;
    DownloadPriority priority = DownloadPriority.high;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF192231),
              title: const Text('Add Smart Rule', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Rule Name (e.g. GitHub Releases)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: domainCtrl,
                      decoration: const InputDecoration(labelText: 'Domain Pattern (e.g. github.com)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: extCtrl,
                      decoration: const InputDecoration(labelText: 'File Extension (e.g. .zip)'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Connections:'),
                        DropdownButton<int>(
                          value: connections,
                          dropdownColor: const Color(0xFF1E283A),
                          items: [2, 4, 8, 16, 32].map((c) => DropdownMenuItem(value: c, child: Text('$c'))).toList(),
                          onChanged: (v) {
                            if (v != null) setDialogState(() => connections = v);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCyan,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isNotEmpty) {
                      final rule = SmartRule(
                        id: 'rule_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text.trim(),
                        domainPattern: domainCtrl.text.trim().isNotEmpty ? domainCtrl.text.trim() : null,
                        fileExtension: extCtrl.text.trim().isNotEmpty ? extCtrl.text.trim() : null,
                        connections: connections,
                        priority: priority,
                      );
                      await DatabaseService.instance.saveSmartRule(rule);
                      _loadRules();
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text('SAVE RULE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBatchImportDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF192231),
          title: const Text('Batch Import URLs', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paste multiple download URLs (one per line):',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _batchUrlsController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'https://example.com/file1.zip\nhttps://example.com/file2.mp4',
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCyan, foregroundColor: Colors.black),
              onPressed: () {
                final text = _batchUrlsController.text;
                final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
                if (lines.isNotEmpty) {
                  Provider.of<DownloadProvider>(context, listen: false).addBatchUrls(lines);
                  _batchUrlsController.clear();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${lines.length} URLs to queue!')),
                  );
                }
              },
              child: const Text('IMPORT ALL'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tools & Rules', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Assistant Banner (Requirement #49)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A148C), Color(0xFF1A237E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Smart AI Assistant',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Generate scheduled queue configurations from natural prompts.',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const SmartAssistantDialog(),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tools Grid
            Row(
              children: [
                Expanded(
                  child: _buildToolCard(
                    icon: Icons.playlist_add_rounded,
                    title: 'Batch Import',
                    subtitle: 'Multi-URL queue',
                    color: AppTheme.primaryCyan,
                    onTap: _showBatchImportDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildToolCard(
                    icon: Icons.qr_code_2_rounded,
                    title: 'QR Transfer',
                    subtitle: 'Scan & share links',
                    color: Colors.tealAccent,
                    onTap: () => _showQrDialog(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Smart Rules Section (Requirement #48)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SMART RULES ENGINE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Colors.white54,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddRuleDialog,
                  icon: const Icon(Icons.add, size: 16, color: AppTheme.primaryCyan),
                  label: const Text('Add Rule', style: TextStyle(color: AppTheme.primaryCyan)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_rules.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.rule_folder_outlined, size: 36, color: Colors.white30),
                        SizedBox(height: 8),
                        Text(
                          'No custom smart rules yet',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Automatically map domains and extensions to specific folders and connection counts.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white30, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rules.length,
                itemBuilder: (context, index) {
                  final r = _rules[index];
                  return Card(
                    child: ListTile(
                      title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'IF ${r.domainPattern ?? '*'} (${r.fileExtension ?? '*'}) → ${r.connections ?? 8} connections',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white38),
                        onPressed: () async {
                          await DatabaseService.instance.deleteSmartRule(r.id);
                          _loadRules();
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF192231),
              title: const Text('QR Download Link', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 160.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _qrTextController,
                    decoration: InputDecoration(
                      hintText: 'Enter URL for QR code...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () {
                          if (_qrTextController.text.isNotEmpty) {
                            setDialogState(() {
                              _qrData = _qrTextController.text.trim();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('CLOSE'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
