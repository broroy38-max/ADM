import '../models/download_task.dart';

class AssistantConfigProposal {
  final List<String> urls;
  final DateTime? scheduledTime;
  final bool wifiOnly;
  final DownloadPriority priority;
  final int connections;
  final String summary;

  AssistantConfigProposal({
    required this.urls,
    this.scheduledTime,
    this.wifiOnly = false,
    this.priority = DownloadPriority.normal,
    this.connections = 8,
    required this.summary,
  });
}

class AssistantService {
  static final AssistantService instance = AssistantService._internal();

  AssistantService._internal();

  AssistantConfigProposal parsePrompt(String userPrompt) {
    final lower = userPrompt.toLowerCase();

    // 1. Extract URLs
    final urlRegex = RegExp(r'https?://[^\s]+');
    final matches = urlRegex.allMatches(userPrompt);
    final urls = matches.map((m) => m.group(0)!).toList();

    // 2. Detect Wi-Fi preference
    bool wifiOnly = false;
    if (lower.contains('wi-fi') ||
        lower.contains('wifi') ||
        lower.contains('ওয়াইফাই') ||
        lower.contains('ওয়াইফাই')) {
      wifiOnly = true;
    }

    // 3. Detect Priority
    DownloadPriority priority = DownloadPriority.normal;
    if (lower.contains('critical') || lower.contains('খুব জরুরি') || lower.contains('সর্বোচ্চ')) {
      priority = DownloadPriority.critical;
    } else if (lower.contains('high') || lower.contains('urgent') || lower.contains('জরুরি') || lower.contains('তাড়াতাড়ি')) {
      priority = DownloadPriority.high;
    } else if (lower.contains('low') || lower.contains('দেরিতে') || lower.contains('কম গুরুত্ব')) {
      priority = DownloadPriority.low;
    }

    // 4. Detect Scheduled Time
    DateTime? scheduledTime;
    final now = DateTime.now();

    // Check Bengali time: "রাত ২টা" / "রাত 2" / "সকাল ৮"
    int? hour;
    int minute = 0;

    final banglaNightRegex = RegExp(r'রাত\s*([০-৯0-9]+)(?:টা|:\s*([০-৯0-9]+))?');
    final banglaMorningRegex = RegExp(r'সকাল\s*([০-৯0-9]+)(?:টা|:\s*([০-৯0-9]+))?');
    final englishTimeRegex = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?');

    if (banglaNightRegex.hasMatch(lower)) {
      final m = banglaNightRegex.firstMatch(lower)!;
      hour = _parseBengaliDigits(m.group(1)!);
      if (hour == 12) hour = 0;
      if (hour < 12) hour = hour; // 2 am night
    } else if (banglaMorningRegex.hasMatch(lower)) {
      final m = banglaMorningRegex.firstMatch(lower)!;
      hour = _parseBengaliDigits(m.group(1)!);
    } else if (englishTimeRegex.hasMatch(lower)) {
      final m = englishTimeRegex.firstMatch(lower)!;
      hour = int.tryParse(m.group(1)!);
      minute = int.tryParse(m.group(2) ?? '0') ?? 0;
      final ampm = m.group(3);
      if (ampm == 'pm' && hour != null && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
    }

    if (hour != null) {
      DateTime candidate = DateTime(now.year, now.month, now.day, hour, minute);
      if (candidate.isBefore(now)) {
        // Schedule for tomorrow
        candidate = candidate.add(const Duration(days: 1));
      }
      scheduledTime = candidate;
    }

    // 5. Build human-readable summary
    final count = urls.isNotEmpty ? urls.length : 1;
    final timeStr = scheduledTime != null
        ? '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}'
        : 'Immediately';
    final netStr = wifiOnly ? 'Wi-Fi Only' : 'Any Network';
    final priorityStr = priority.name.toUpperCase();

    final summary =
        'Configured $count download(s)\n• Start Time: $timeStr\n• Network: $netStr\n• Priority: $priorityStr\n• Connections: 8';

    return AssistantConfigProposal(
      urls: urls,
      scheduledTime: scheduledTime,
      wifiOnly: wifiOnly,
      priority: priority,
      connections: 8,
      summary: summary,
    );
  }

  int _parseBengaliDigits(String input) {
    const bDigits = '০১২৩৪৫৬৭৮৯';
    String normalized = '';
    for (int i = 0; i < input.length; i++) {
      final ch = input[i];
      final idx = bDigits.indexOf(ch);
      if (idx != -1) {
        normalized += idx.toString();
      } else {
        normalized += ch;
      }
    }
    return int.tryParse(normalized) ?? 2;
  }
}
