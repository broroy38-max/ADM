import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/download_task.dart';
import '../theme/app_theme.dart';

class LiveSpeedGraph extends StatelessWidget {
  final List<double> speedHistory; // 30 data points in bytes/s

  const LiveSpeedGraph({super.key, required this.speedHistory});

  @override
  Widget build(BuildContext context) {
    double maxSpeed = speedHistory.fold(0.0, (prev, elem) => max(prev, elem));
    if (maxSpeed < 1024 * 512) {
      maxSpeed = 1024 * 1024; // Default scale 1 MB/s min
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.show_chart_rounded, size: 18, color: AppTheme.primaryCyan),
                    SizedBox(width: 6),
                    Text(
                      'Live Throughput',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Peak: ${DownloadTask.formatSpeed(maxSpeed)}',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              width: double.infinity,
              child: CustomPaint(
                painter: _SmoothSpeedChartPainter(
                  history: speedHistory,
                  maxSpeed: maxSpeed,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('30s ago', style: TextStyle(fontSize: 10, color: Colors.white38)),
                Text('15s', style: TextStyle(fontSize: 10, color: Colors.white38)),
                Text('Now', style: TextStyle(fontSize: 10, color: Colors.white38)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmoothSpeedChartPainter extends CustomPainter {
  final List<double> history;
  final double maxSpeed;

  _SmoothSpeedChartPainter({required this.history, required this.maxSpeed});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    // Background Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(15)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75), gridPaint);

    final points = <Offset>[];
    final stepX = size.width / (history.length - 1);

    for (int i = 0; i < history.length; i++) {
      final x = i * stepX;
      final normalized = (history[i] / maxSpeed).clamp(0.0, 1.0);
      final y = size.height - (normalized * (size.height - 10)) - 5;
      points.add(Offset(x, y));
    }

    // Build smooth cubic bezier path
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final control1 = Offset(current.dx + (next.dx - current.dx) / 2, current.dy);
      final control2 = Offset(current.dx + (next.dx - current.dx) / 2, next.dy);
      path.cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, next.dx, next.dy);
    }

    // Gradient Fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.primaryCyan.withAlpha(70),
          AppTheme.primaryCyan.withAlpha(0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Neon Stroke line
    final linePaint = Paint()
      ..color = AppTheme.primaryCyan
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Glowing head dot
    if (points.isNotEmpty) {
      final lastPoint = points.last;
      final glowPaint = Paint()
        ..color = AppTheme.primaryCyan.withAlpha(150)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(lastPoint, 6, glowPaint);

      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(lastPoint, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SmoothSpeedChartPainter oldDelegate) {
    return true;
  }
}
