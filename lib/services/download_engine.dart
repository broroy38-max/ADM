import 'dart:async';
import 'dart:io';
import '../models/app_settings.dart';
import '../models/download_segment.dart';
import '../models/download_task.dart';
import 'database_service.dart';
import 'storage_service.dart';

typedef TaskProgressCallback = void Function(DownloadTask task);
typedef TaskCompletedCallback = void Function(DownloadTask task);
typedef TaskErrorCallback = void Function(DownloadTask task, dynamic error, int? statusCode);

class ActiveDownloadHandle {
  final DownloadTask task;
  final HttpClient httpClient;
  final List<StreamSubscription> subscriptions = [];
  final List<RandomAccessFile> fileHandles = [];
  bool isCancelled = false;
  Timer? speedTimer;
  int bytesSinceLastTick = 0;
  DateTime lastSpeedCheck = DateTime.now();

  ActiveDownloadHandle({
    required this.task,
    required this.httpClient,
  });

  void cancel() {
    isCancelled = true;
    speedTimer?.cancel();
    for (final sub in subscriptions) {
      sub.cancel();
    }
    for (final handle in fileHandles) {
      try {
        handle.closeSync();
      } catch (_) {}
    }
    httpClient.close(force: true);
  }
}

class MultiSegmentEngine {
  static final MultiSegmentEngine instance = MultiSegmentEngine._internal();

  final Map<String, ActiveDownloadHandle> _activeHandles = {};

  MultiSegmentEngine._internal();

  bool isDownloading(String taskId) => _activeHandles.containsKey(taskId);

  Future<void> startDownload(
    DownloadTask task, {
    required TaskProgressCallback onProgress,
    required TaskCompletedCallback onCompleted,
    required TaskErrorCallback onError,
    AppSettings? settings,
  }) async {
    if (_activeHandles.containsKey(task.id)) {
      return;
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    client.idleTimeout = const Duration(seconds: 15);

    final handle = ActiveDownloadHandle(task: task, httpClient: client);
    _activeHandles[task.id] = handle;

    task.status = DownloadStatus.connecting;
    task.speed = 0;
    onProgress(task);

    try {
      // Step 1: Probe server with HEAD or Range GET to retrieve Content-Length & Accept-Ranges
      await _probeUrl(task, client);

      if (handle.isCancelled) return;

      // Step 2: Ensure destination directory and file exist
      final saveFile = File(task.savePath);
      if (!await saveFile.parent.exists()) {
        await saveFile.parent.create(recursive: true);
      }

      // Step 3: Segment preparation
      if (!task.supportsRange || task.totalBytes <= 0) {
        // Single-stream fallback
        await _startSingleStreamDownload(handle, onProgress, onCompleted, onError);
      } else {
        // Multi-segment parallel download
        await _startMultiSegmentDownload(handle, onProgress, onCompleted, onError);
      }
    } catch (e) {
      if (handle.isCancelled) return;
      _cleanupHandle(task.id);
      task.status = DownloadStatus.failed;
      task.failureReason = e.toString();
      onError(task, e, null);
    }
  }

  Future<void> _probeUrl(DownloadTask task, HttpClient client) async {
    final uri = Uri.parse(task.url);

    // Try HEAD request first
    try {
      final req = await client.headUrl(uri);
      _applyCustomHeaders(req, task.customHeaders);
      final resp = await req.close().timeout(const Duration(seconds: 10));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        _parseHeaders(resp, task);
        return;
      }
    } catch (_) {
      // HEAD may be blocked by some CDNs (e.g. Cloudflare / S3), fallback to Range GET
    }

    // Range GET test (bytes=0-0)
    try {
      final req = await client.getUrl(uri);
      _applyCustomHeaders(req, task.customHeaders);
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=0-0');
      final resp = await req.close().timeout(const Duration(seconds: 10));

      if (resp.statusCode == HttpStatus.partialContent) {
        // 206 Partial Content: Range supported!
        task.supportsRange = true;
        final contentRange = resp.headers.value(HttpHeaders.contentRangeHeader);
        if (contentRange != null && contentRange.contains('/')) {
          final totalStr = contentRange.split('/').last.trim();
          final parsed = int.tryParse(totalStr);
          if (parsed != null && parsed > 0) {
            task.totalBytes = parsed;
          }
        }
        _parseHeaders(resp, task);
        // Drain stream
        await resp.drain();
        return;
      } else if (resp.statusCode == HttpStatus.ok) {
        // 200 OK: Range NOT supported, server returned entire file
        task.supportsRange = false;
        if (resp.contentLength > 0) {
          task.totalBytes = resp.contentLength;
        }
        _parseHeaders(resp, task);
        await resp.drain();
        return;
      } else {
        throw HttpException('Server returned HTTP ${resp.statusCode}', uri: uri);
      }
    } catch (e) {
      rethrow;
    }
  }

  void _applyCustomHeaders(HttpClientRequest req, Map<String, String> headers) {
    req.headers.set(HttpHeaders.userAgentHeader, 'ADM/2.0 (Android; Next-Gen Download Manager)');
    req.headers.set(HttpHeaders.acceptHeader, '*/*');
    for (final entry in headers.entries) {
      req.headers.set(entry.key, entry.value);
    }
  }

  void _parseHeaders(HttpClientResponse resp, DownloadTask task) {
    if (task.totalBytes <= 0 && resp.contentLength > 0) {
      task.totalBytes = resp.contentLength;
    }

    final acceptRanges = resp.headers.value(HttpHeaders.acceptRangesHeader);
    if (acceptRanges != null && acceptRanges.toLowerCase().contains('bytes')) {
      task.supportsRange = true;
    }

    final etag = resp.headers.value(HttpHeaders.etagHeader);
    if (etag != null) task.etag = etag;

    final lastMod = resp.headers.value(HttpHeaders.lastModifiedHeader);
    if (lastMod != null) task.lastModified = lastMod;

    // Filename from Content-Disposition if not set or generic
    final disposition = resp.headers.value('content-disposition');
    if (disposition != null && disposition.toLowerCase().contains('filename')) {
      try {
        String name = '';
        if (disposition.contains("filename*=")) {
          name = disposition.split('filename*=').last.split(';').first.trim();
          if (name.contains("''")) {
            name = name.split("''").last;
          }
        } else if (disposition.contains('filename=')) {
          name = disposition.split('filename=').last.split(';').first.trim();
        }
        name = name.replaceAll('"', '').replaceAll("'", '').trim();
        if (name.isNotEmpty) {
          name = Uri.decodeComponent(name);
          task.filename = StorageService.instance.sanitizeFilename(name);
          task.category = DownloadTask.detectCategory(task.filename);
        }
      } catch (_) {}
    }
  }

  Future<void> _startMultiSegmentDownload(
    ActiveDownloadHandle handle,
    TaskProgressCallback onProgress,
    TaskCompletedCallback onCompleted,
    TaskErrorCallback onError,
  ) async {
    final task = handle.task;
    final file = File(task.savePath);

    // If segments not initialized, create them
    if (task.segments.isEmpty) {
      task.segments = _calculateSegments(task.totalBytes, task.connections);
      // Preallocate file
      final raf = await file.open(mode: FileMode.writeOnly);
      await raf.truncate(task.totalBytes);
      await raf.close();
    } else {
      // Resuming existing segments
      if (!await file.exists()) {
        final raf = await file.open(mode: FileMode.writeOnly);
        await raf.truncate(task.totalBytes);
        await raf.close();
      }
    }

    task.status = DownloadStatus.downloading;
    _startSpeedMonitor(handle, onProgress);

    final List<Future<void>> segmentFutures = [];
    int completedSegments = 0;

    for (int i = 0; i < task.segments.length; i++) {
      final seg = task.segments[i];
      if (seg.isDone) {
        completedSegments++;
        continue;
      }

      segmentFutures.add(_downloadSegment(handle, seg, () {
        completedSegments++;
        if (completedSegments == task.segments.length && !handle.isCancelled) {
          _finalizeDownload(handle, onProgress, onCompleted);
        }
      }, (err, statusCode) {
        if (!handle.isCancelled) {
          _cleanupHandle(task.id);
          task.status = DownloadStatus.failed;
          task.failureReason = err.toString();
          onError(task, err, statusCode);
        }
      }));
    }

    if (completedSegments == task.segments.length) {
      _finalizeDownload(handle, onProgress, onCompleted);
    }
  }

  List<DownloadSegment> _calculateSegments(int totalBytes, int connectionCount) {
    final List<DownloadSegment> segments = [];
    final count = connectionCount.clamp(1, 32);
    final chunkSize = totalBytes ~/ count;

    for (int i = 0; i < count; i++) {
      final start = i * chunkSize;
      final end = (i == count - 1) ? (totalBytes - 1) : ((i + 1) * chunkSize - 1);
      segments.add(DownloadSegment(
        id: i,
        startByte: start,
        endByte: end,
        downloadedBytes: 0,
      ));
    }
    return segments;
  }

  Future<void> _downloadSegment(
    ActiveDownloadHandle handle,
    DownloadSegment segment,
    void Function() onSegmentDone,
    void Function(dynamic error, int? statusCode) onSegmentError,
  ) async {
    final task = handle.task;
    final file = File(task.savePath);
    RandomAccessFile? raf;

    try {
      raf = await file.open(mode: FileMode.writeOnlyAppend);
      handle.fileHandles.add(raf);

      final currentOffset = segment.startByte + segment.downloadedBytes;
      if (currentOffset > segment.endByte) {
        segment.status = SegmentStatus.completed;
        onSegmentDone();
        return;
      }

      final uri = Uri.parse(task.url);
      final req = await handle.httpClient.getUrl(uri);
      _applyCustomHeaders(req, task.customHeaders);
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=$currentOffset-${segment.endByte}');

      if (task.etag != null && task.etag!.isNotEmpty) {
        req.headers.set(HttpHeaders.ifRangeHeader, task.etag!);
      }

      final resp = await req.close();

      if (resp.statusCode != HttpStatus.partialContent && resp.statusCode != HttpStatus.ok) {
        segment.status = SegmentStatus.failed;
        onSegmentError(HttpException('Segment failed: ${resp.statusCode}', uri: uri), resp.statusCode);
        return;
      }

      segment.status = SegmentStatus.downloading;
      int segmentOffset = currentOffset;

      final fileHandle = raf;
      final subscription = resp.listen(
        (chunk) async {
          if (handle.isCancelled) return;

          try {
            await fileHandle.setPosition(segmentOffset);
            await fileHandle.writeFrom(chunk);
            segmentOffset += chunk.length;
            segment.downloadedBytes += chunk.length;
            task.downloadedBytes += chunk.length;
            handle.bytesSinceLastTick += chunk.length;
          } catch (e) {
            segment.status = SegmentStatus.failed;
            onSegmentError(e, null);
          }
        },
        onDone: () {
          segment.status = SegmentStatus.completed;
          onSegmentDone();
        },
        onError: (err) {
          segment.status = SegmentStatus.failed;
          onSegmentError(err, null);
        },
        cancelOnError: true,
      );

      handle.subscriptions.add(subscription);
    } catch (e) {
      segment.status = SegmentStatus.failed;
      onSegmentError(e, null);
    }
  }

  Future<void> _startSingleStreamDownload(
    ActiveDownloadHandle handle,
    TaskProgressCallback onProgress,
    TaskCompletedCallback onCompleted,
    TaskErrorCallback onError,
  ) async {
    final task = handle.task;
    final file = File(task.savePath);
    RandomAccessFile? raf;

    try {
      final uri = Uri.parse(task.url);
      final req = await handle.httpClient.getUrl(uri);
      _applyCustomHeaders(req, task.customHeaders);

      if (task.downloadedBytes > 0 && task.supportsRange) {
        req.headers.set(HttpHeaders.rangeHeader, 'bytes=${task.downloadedBytes}-');
        if (task.etag != null) req.headers.set(HttpHeaders.ifRangeHeader, task.etag!);
      }

      final resp = await req.close();
      if (resp.statusCode != HttpStatus.ok && resp.statusCode != HttpStatus.partialContent) {
        _cleanupHandle(task.id);
        task.status = DownloadStatus.failed;
        onError(task, HttpException('HTTP ${resp.statusCode}', uri: uri), resp.statusCode);
        return;
      }

      final appendMode = (resp.statusCode == HttpStatus.partialContent);
      raf = await file.open(mode: appendMode ? FileMode.append : FileMode.writeOnly);
      handle.fileHandles.add(raf);

      if (!appendMode) {
        task.downloadedBytes = 0;
      }

      task.status = DownloadStatus.downloading;
      _startSpeedMonitor(handle, onProgress);

      final fileHandle = raf;
      final subscription = resp.listen(
        (chunk) async {
          if (handle.isCancelled) return;
          try {
            await fileHandle.writeFrom(chunk);
            task.downloadedBytes += chunk.length;
            handle.bytesSinceLastTick += chunk.length;
          } catch (e) {
            _cleanupHandle(task.id);
            task.status = DownloadStatus.failed;
            onError(task, e, null);
          }
        },
        onDone: () {
          _finalizeDownload(handle, onProgress, onCompleted);
        },
        onError: (e) {
          _cleanupHandle(task.id);
          task.status = DownloadStatus.failed;
          onError(task, e, null);
        },
        cancelOnError: true,
      );

      handle.subscriptions.add(subscription);
    } catch (e) {
      _cleanupHandle(task.id);
      task.status = DownloadStatus.failed;
      onError(task, e, null);
    }
  }

  void _startSpeedMonitor(ActiveDownloadHandle handle, TaskProgressCallback onProgress) {
    handle.lastSpeedCheck = DateTime.now();
    handle.speedTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (handle.isCancelled) return;

      final now = DateTime.now();
      final diffMs = now.difference(handle.lastSpeedCheck).inMilliseconds;
      if (diffMs > 0) {
        final currentSpeed = (handle.bytesSinceLastTick * 1000.0) / diffMs;
        // EMA smoothing: 0.7 * current + 0.3 * previous
        handle.task.speed = (0.7 * currentSpeed) + (0.3 * handle.task.speed);

        // Daily bandwidth update
        DatabaseService.instance.addDownloadedBytesToday(handle.bytesSinceLastTick);
        handle.bytesSinceLastTick = 0;
        handle.lastSpeedCheck = now;

        // Calculate ETA
        if (handle.task.speed > 0 && handle.task.totalBytes > handle.task.downloadedBytes) {
          final remainingBytes = handle.task.totalBytes - handle.task.downloadedBytes;
          handle.task.etaSeconds = (remainingBytes / handle.task.speed).round();
        } else {
          handle.task.etaSeconds = 0;
        }

        onProgress(handle.task);
      }
    });
  }

  Future<void> _finalizeDownload(
    ActiveDownloadHandle handle,
    TaskProgressCallback onProgress,
    TaskCompletedCallback onCompleted,
  ) async {
    final task = handle.task;
    _cleanupHandle(task.id);

    task.status = DownloadStatus.completed;
    task.completedAt = DateTime.now();
    task.speed = 0;
    task.etaSeconds = 0;

    // Checksum verification if provided
    if (task.checksumExpected != null && task.checksumExpected!.isNotEmpty) {
      final type = task.checksumType ?? 'sha256';
      task.checksumActual = await StorageService.instance.calculateChecksum(task.savePath, type);
    }

    await DatabaseService.instance.updateTask(task);
    onCompleted(task);
  }

  void pauseDownload(String taskId) {
    final handle = _activeHandles[taskId];
    if (handle != null) {
      handle.task.status = DownloadStatus.paused;
      handle.task.speed = 0;
      handle.task.etaSeconds = 0;
      handle.cancel();
      _activeHandles.remove(taskId);
      DatabaseService.instance.updateTask(handle.task);
    }
  }

  void cancelDownload(String taskId) {
    final handle = _activeHandles[taskId];
    if (handle != null) {
      handle.task.status = DownloadStatus.cancelled;
      handle.task.speed = 0;
      handle.task.etaSeconds = 0;
      handle.cancel();
      _activeHandles.remove(taskId);
      DatabaseService.instance.updateTask(handle.task);
    }
  }

  void _cleanupHandle(String taskId) {
    final handle = _activeHandles.remove(taskId);
    handle?.cancel();
  }
}
