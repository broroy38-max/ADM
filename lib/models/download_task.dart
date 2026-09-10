import 'dart:convert';
import 'download_segment.dart';

enum DownloadCategory {
  video,
  music,
  document,
  archive,
  app,
  image,
  other,
}

enum DownloadStatus {
  queued,
  connecting,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

enum DownloadPriority {
  critical,
  high,
  normal,
  low,
}

class DownloadTask {
  final String id;
  final String url;
  String filename;
  String savePath;
  DownloadCategory category;
  DownloadStatus status;
  int totalBytes;
  int downloadedBytes;
  double speed; // bytes per second
  int etaSeconds;
  int connections;
  List<DownloadSegment> segments;
  DownloadPriority priority;
  final DateTime createdAt;
  DateTime? completedAt;
  String? etag;
  String? lastModified;
  bool supportsRange;
  int retryCount;
  String? failureReason;
  String? failureDetails;
  String? suggestedAction;
  String? checksumExpected;
  String? checksumActual;
  String? checksumType;
  Map<String, String> customHeaders;
  int? speedLimitBytesPerSec;
  bool isScheduled;
  DateTime? scheduledTime;
  bool wifiOnly;

  DownloadTask({
    required this.id,
    required this.url,
    required this.filename,
    required this.savePath,
    this.category = DownloadCategory.other,
    this.status = DownloadStatus.queued,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.speed = 0.0,
    this.etaSeconds = 0,
    this.connections = 8,
    List<DownloadSegment>? segments,
    this.priority = DownloadPriority.normal,
    DateTime? createdAt,
    this.completedAt,
    this.etag,
    this.lastModified,
    this.supportsRange = true,
    this.retryCount = 0,
    this.failureReason,
    this.failureDetails,
    this.suggestedAction,
    this.checksumExpected,
    this.checksumActual,
    this.checksumType,
    Map<String, String>? customHeaders,
    this.speedLimitBytesPerSec,
    this.isScheduled = false,
    this.scheduledTime,
    this.wifiOnly = false,
  })  : segments = segments ?? [],
        createdAt = createdAt ?? DateTime.now(),
        customHeaders = customHeaders ?? {};

  double get progress {
    if (totalBytes <= 0) return 0.0;
    return (downloadedBytes / totalBytes).clamp(0.0, 1.0);
  }

  bool get isDone => status == DownloadStatus.completed;
  bool get isActive => status == DownloadStatus.downloading || status == DownloadStatus.connecting;
  bool get isPaused => status == DownloadStatus.paused;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isQueued => status == DownloadStatus.queued;

  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  static String formatSpeed(double bytesPerSec) {
    if (bytesPerSec <= 0) return '0 KB/s';
    if (bytesPerSec >= 1024 * 1024) {
      return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
  }

  static String formatDuration(int seconds) {
    if (seconds <= 0) return '--';
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) {
      int m = seconds ~/ 60;
      int s = seconds % 60;
      return '${m}m ${s}s';
    }
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    return '${h}h ${m}m';
  }

  String get formattedTotalSize => formatBytes(totalBytes);
  String get formattedDownloadedSize => formatBytes(downloadedBytes);
  String get formattedSpeed => formatSpeed(speed);
  String get formattedEta => formatDuration(etaSeconds);

  static DownloadCategory detectCategory(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.flv') ||
        lower.endsWith('.webm')) {
      return DownloadCategory.video;
    }
    if (lower.endsWith('.mp3') ||
        lower.endsWith('.flac') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.m4a')) {
      return DownloadCategory.music;
    }
    if (lower.endsWith('.pdf') ||
        lower.endsWith('.doc') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.ppt') ||
        lower.endsWith('.pptx') ||
        lower.endsWith('.xls') ||
        lower.endsWith('.xlsx') ||
        lower.endsWith('.txt')) {
      return DownloadCategory.document;
    }
    if (lower.endsWith('.zip') ||
        lower.endsWith('.rar') ||
        lower.endsWith('.7z') ||
        lower.endsWith('.tar') ||
        lower.endsWith('.gz') ||
        lower.endsWith('.iso')) {
      return DownloadCategory.archive;
    }
    if (lower.endsWith('.apk') ||
        lower.endsWith('.ipa') ||
        lower.endsWith('.exe') ||
        lower.endsWith('.dmg') ||
        lower.endsWith('.deb')) {
      return DownloadCategory.app;
    }
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.svg')) {
      return DownloadCategory.image;
    }
    return DownloadCategory.other;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'filename': filename,
      'savePath': savePath,
      'category': category.index,
      'status': status.index,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'connections': connections,
      'segments': jsonEncode(segments.map((s) => s.toMap()).toList()),
      'priority': priority.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'etag': etag,
      'lastModified': lastModified,
      'supportsRange': supportsRange ? 1 : 0,
      'retryCount': retryCount,
      'failureReason': failureReason,
      'failureDetails': failureDetails,
      'suggestedAction': suggestedAction,
      'checksumExpected': checksumExpected,
      'checksumActual': checksumActual,
      'checksumType': checksumType,
      'customHeaders': jsonEncode(customHeaders),
      'speedLimitBytesPerSec': speedLimitBytesPerSec,
      'isScheduled': isScheduled ? 1 : 0,
      'scheduledTime': scheduledTime?.millisecondsSinceEpoch,
      'wifiOnly': wifiOnly ? 1 : 0,
    };
  }

  factory DownloadTask.fromMap(Map<String, dynamic> map) {
    List<DownloadSegment> loadedSegments = [];
    if (map['segments'] != null && map['segments'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['segments'] as String) as List;
        loadedSegments = decoded.map((e) => DownloadSegment.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    Map<String, String> headers = {};
    if (map['customHeaders'] != null && map['customHeaders'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['customHeaders'] as String) as Map<String, dynamic>;
        headers = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {}
    }

    return DownloadTask(
      id: map['id'] as String,
      url: map['url'] as String,
      filename: map['filename'] as String,
      savePath: map['savePath'] as String,
      category: DownloadCategory.values[map['category'] as int? ?? DownloadCategory.other.index],
      status: DownloadStatus.values[map['status'] as int? ?? DownloadStatus.queued.index],
      totalBytes: map['totalBytes'] as int? ?? 0,
      downloadedBytes: map['downloadedBytes'] as int? ?? 0,
      connections: map['connections'] as int? ?? 8,
      segments: loadedSegments,
      priority: DownloadPriority.values[map['priority'] as int? ?? DownloadPriority.normal.index],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      completedAt: map['completedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int) : null,
      etag: map['etag'] as String?,
      lastModified: map['lastModified'] as String?,
      supportsRange: (map['supportsRange'] as int? ?? 1) == 1,
      retryCount: map['retryCount'] as int? ?? 0,
      failureReason: map['failureReason'] as String?,
      failureDetails: map['failureDetails'] as String?,
      suggestedAction: map['suggestedAction'] as String?,
      checksumExpected: map['checksumExpected'] as String?,
      checksumActual: map['checksumActual'] as String?,
      checksumType: map['checksumType'] as String?,
      customHeaders: headers,
      speedLimitBytesPerSec: map['speedLimitBytesPerSec'] as int?,
      isScheduled: (map['isScheduled'] as int? ?? 0) == 1,
      scheduledTime: map['scheduledTime'] != null ? DateTime.fromMillisecondsSinceEpoch(map['scheduledTime'] as int) : null,
      wifiOnly: (map['wifiOnly'] as int? ?? 0) == 1,
    );
  }
}
