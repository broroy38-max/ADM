enum SegmentStatus {
  idle,
  connecting,
  downloading,
  completed,
  failed,
}

class DownloadSegment {
  final int id;
  final int startByte;
  final int endByte;
  int downloadedBytes;
  double speed; // bytes per second
  SegmentStatus status;
  String? error;

  DownloadSegment({
    required this.id,
    required this.startByte,
    required this.endByte,
    this.downloadedBytes = 0,
    this.speed = 0.0,
    this.status = SegmentStatus.idle,
    this.error,
  });

  int get totalBytes => endByte >= startByte ? (endByte - startByte + 1) : 0;
  double get progress => totalBytes > 0 ? (downloadedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
  bool get isDone => downloadedBytes >= totalBytes && totalBytes > 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startByte': startByte,
      'endByte': endByte,
      'downloadedBytes': downloadedBytes,
      'speed': speed,
      'status': status.index,
      'error': error,
    };
  }

  factory DownloadSegment.fromMap(Map<String, dynamic> map) {
    return DownloadSegment(
      id: map['id'] as int,
      startByte: map['startByte'] as int,
      endByte: map['endByte'] as int,
      downloadedBytes: map['downloadedBytes'] as int? ?? 0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      status: SegmentStatus.values[map['status'] as int? ?? 0],
      error: map['error'] as String?,
    );
  }
}
