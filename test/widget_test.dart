import 'package:flutter_test/flutter_test.dart';
import 'package:adm/models/download_task.dart';
import 'package:adm/services/assistant_service.dart';
import 'package:adm/services/storage_service.dart';

void main() {
  group('ADM Core Tests', () {
    test('Category detection works accurately', () {
      expect(DownloadTask.detectCategory('movie.mp4'), DownloadCategory.video);
      expect(DownloadTask.detectCategory('song.mp3'), DownloadCategory.music);
      expect(DownloadTask.detectCategory('manual.pdf'), DownloadCategory.document);
      expect(DownloadTask.detectCategory('archive.zip'), DownloadCategory.archive);
      expect(DownloadTask.detectCategory('app.apk'), DownloadCategory.app);
    });

    test('Filename sanitization removes illegal characters', () {
      final sanitized = StorageService.instance.sanitizeFilename('report/2026?v=1&t=10.pdf');
      expect(sanitized, 'report_2026');
    });

    test('Smart Assistant parses Bengali prompt properly', () {
      const prompt = 'https://example.com/test.zip রাত ২টায় Wi-Fi দিয়ে download করো urgent';
      final proposal = AssistantService.instance.parsePrompt(prompt);

      expect(proposal.urls.length, 1);
      expect(proposal.urls.first, 'https://example.com/test.zip');
      expect(proposal.wifiOnly, isTrue);
      expect(proposal.priority, DownloadPriority.high);
      expect(proposal.scheduledTime, isNotNull);
      expect(proposal.scheduledTime!.hour, 2);
    });
  });
}
