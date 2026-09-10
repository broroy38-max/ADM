import 'package:flutter/material.dart';
import '../../models/download_segment.dart';
import '../theme/app_theme.dart';

class SegmentProgressBar extends StatelessWidget {
  final List<DownloadSegment> segments;
  final double overallProgress;
  final double height;

  const SegmentProgressBar({
    super.key,
    required this.segments,
    required this.overallProgress,
    this.height = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty || segments.length <= 1) {
      // Standard linear progress bar
      return ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: LinearProgressIndicator(
            value: overallProgress,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryCyan),
          ),
        ),
      );
    }

    // Multi-segment visualized chunk bar
    return Row(
      children: List.generate(segments.length, (index) {
        final segment = segments[index];
        final prog = segment.progress;
        final isCompleted = segment.isDone;

        Color segColor;
        if (isCompleted) {
          segColor = AppTheme.neonGreen;
        } else if (segment.status == SegmentStatus.downloading) {
          segColor = AppTheme.primaryCyan;
        } else if (segment.status == SegmentStatus.failed) {
          segColor = AppTheme.dangerRed;
        } else {
          segColor = Colors.white24;
        }

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < segments.length - 1 ? 2.5 : 0),
            height: height,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(height / 2),
              child: LinearProgressIndicator(
                value: prog,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(segColor),
              ),
            ),
          ),
        );
      }),
    );
  }
}
