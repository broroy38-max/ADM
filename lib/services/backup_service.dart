import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/app_settings.dart';
import '../models/download_task.dart';
import '../models/site_profile.dart';
import '../models/smart_rule.dart';
import 'database_service.dart';

class BackupService {
  static final BackupService instance = BackupService._internal();

  BackupService._internal();

  Future<String> exportBackup(AppSettings settings) async {
    final tasks = await DatabaseService.instance.getAllTasks();
    final profiles = await DatabaseService.instance.getAllSiteProfiles();
    final rules = await DatabaseService.instance.getAllSmartRules();

    final data = {
      'version': '2.0.0',
      'timestamp': DateTime.now().toIso8601String(),
      'settings': settings.toMap(),
      'downloads': tasks.map((t) => t.toMap()).toList(),
      'site_profiles': profiles.map((p) => p.toMap()).toList(),
      'smart_rules': rules.map((r) => r.toMap()).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    final docDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docDir.path, 'ADM_Backups'));
    if (!await backupDir.exists()) await backupDir.create(recursive: true);

    final filename = 'adm_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(p.join(backupDir.path, filename));
    await file.writeAsString(jsonStr);

    return file.path;
  }

  Future<bool> importBackup(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;

    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    // Restore tasks
    if (data['downloads'] != null) {
      final taskList = data['downloads'] as List;
      for (final t in taskList) {
        final task = DownloadTask.fromMap(t as Map<String, dynamic>);
        await DatabaseService.instance.insertTask(task);
      }
    }

    // Restore site profiles
    if (data['site_profiles'] != null) {
      final profiles = data['site_profiles'] as List;
      for (final p in profiles) {
        final profile = SiteProfile.fromMap(p as Map<String, dynamic>);
        await DatabaseService.instance.saveSiteProfile(profile);
      }
    }

    // Restore smart rules
    if (data['smart_rules'] != null) {
      final rules = data['smart_rules'] as List;
      for (final r in rules) {
        final rule = SmartRule.fromMap(r as Map<String, dynamic>);
        await DatabaseService.instance.saveSmartRule(rule);
      }
    }

    return true;
  }

  Future<List<File>> getAvailableBackups() async {
    final docDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docDir.path, 'ADM_Backups'));
    if (!await backupDir.exists()) return [];
    final entities = backupDir.listSync();
    return entities
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  }
}
