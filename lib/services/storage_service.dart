import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/app_settings.dart';
import '../models/download_task.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();

  StorageService._internal();

  Future<String> getRootDownloadDirectory() async {
    if (Platform.isAndroid) {
      final extDir = Directory('/storage/emulated/0/Download/ADM');
      if (await extDir.exists()) {
        return extDir.path;
      }
      try {
        await extDir.create(recursive: true);
        return extDir.path;
      } catch (_) {
        // Fallback to app documents dir
        final appDir = await getApplicationDocumentsDirectory();
        final admDir = Directory(p.join(appDir.path, 'ADM'));
        if (!await admDir.exists()) await admDir.create(recursive: true);
        return admDir.path;
      }
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final admDir = Directory(p.join(appDir.path, 'ADM'));
      if (!await admDir.exists()) await admDir.create(recursive: true);
      return admDir.path;
    }
  }

  Future<String> getCategorySubfolder(DownloadCategory category, {bool isInbox = false}) async {
    final root = await getRootDownloadDirectory();
    if (isInbox) {
      final inboxDir = Directory(p.join(root, 'Inbox'));
      if (!await inboxDir.exists()) await inboxDir.create(recursive: true);
      return inboxDir.path;
    }

    String subName;
    switch (category) {
      case DownloadCategory.video:
        subName = 'Movies';
        break;
      case DownloadCategory.music:
        subName = 'Music';
        break;
      case DownloadCategory.document:
        subName = 'Documents';
        break;
      case DownloadCategory.archive:
        subName = 'Archives';
        break;
      case DownloadCategory.app:
        subName = 'Apps';
        break;
      case DownloadCategory.image:
        subName = 'Images';
        break;
      case DownloadCategory.other:
        subName = 'Others';
        break;
    }

    final targetDir = Directory(p.join(root, subName));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    return targetDir.path;
  }

  Future<String> resolveTargetFilePath(
    String targetDirectory,
    String originalFilename,
    CollisionStrategy strategy,
  ) async {
    final sanitized = sanitizeFilename(originalFilename);
    final targetPath = p.join(targetDirectory, sanitized);
    final file = File(targetPath);

    if (!await file.exists()) {
      return targetPath;
    }

    if (strategy == CollisionStrategy.overwrite || strategy == CollisionStrategy.resume) {
      return targetPath;
    }

    // Rename strategy: "photo (1).jpg"
    final nameWithoutExt = p.basenameWithoutExtension(sanitized);
    final ext = p.extension(sanitized);
    int count = 1;

    while (true) {
      final newCandidate = p.join(targetDirectory, '$nameWithoutExt ($count)$ext');
      if (!await File(newCandidate).exists()) {
        return newCandidate;
      }
      count++;
    }
  }

  String sanitizeFilename(String filename) {
    // Remove query params or trailing invalid chars
    var clean = filename.split('?').first.split('#').first;
    clean = clean.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (clean.isEmpty) {
      clean = 'download_${DateTime.now().millisecondsSinceEpoch}';
    }
    return clean;
  }

  Future<String> calculateChecksum(String filePath, String type) async {
    final file = File(filePath);
    if (!await file.exists()) return '';

    final stream = file.openRead();
    if (type.toLowerCase() == 'md5') {
      final digest = await md5.bind(stream).first;
      return digest.toString();
    } else {
      // Default to SHA-256
      final digest = await sha256.bind(stream).first;
      return digest.toString();
    }
  }

  Future<bool> verifyFileIntegrity(String filePath, String expectedChecksum, String type) async {
    final calculated = await calculateChecksum(filePath, type);
    return calculated.toLowerCase() == expectedChecksum.trim().toLowerCase();
  }
}
