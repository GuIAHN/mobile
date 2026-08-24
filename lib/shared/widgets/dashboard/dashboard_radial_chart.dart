import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class DashboardRadialSegment {
  const DashboardRadialSegment({required this.value, required this.color});

  final double value;
  final Color color;
}

/// Token-driven radial visualization for compact mobile dashboards.
///
/// It intentionally renders no labels: the caller supplies a visible legend
/// and a semantic summary so color is never the only source of meaning.
class DashboardRadialChart extends StatelessWidget {
  const DashboardRadialChart({
    super.key,
    required this.segments,
    required this.maxValue,
    required this.center,
    required this.semanticLabel,
    this.size = 152,
    this.strokeWidth = 14,
    this.startAngleDegrees = -90,
    this.sweepAngleDegrees = 360,
    this.tickCount = 0,
  });

  final List<DashboardRadialSegment> segments;
  final double maxValue;
  final Widget center;
  final String semanticLabel;
  final double size;
  final double strokeWidth;
  final double startAngleDegrees;
  final double sweepAngleDegrees;
  final int tickCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _DashboardRadialPainter(
                    segments: segments,
                    maxValue: maxValue,
                    strokeWidth: strokeWidth,
                    startAngleDegrees: startAngleDegrees,
                    sweepAngleDegrees: sweepAngleDegrees,
                    tickCount: tickCount,
                  ),
                ),
              ),
              SizedBox.square(
                dimension: size * 0.56,
                child: FittedBox(fit: BoxFit.scaleDown, child: center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardRadialPainter extends CustomPainter {
  const _DashboardRadialPainter({
    required this.segments,
    required this.maxValue,
    required this.strokeWidth,
    required this.startAngleDegrees,
    required this.sweepAngleDegrees,
    required this.tickCount,
  });

  final List<DashboardRadialSegment> segments;
  final double maxValue;
  final double strokeWidth;
  final double startAngleDegrees;
  final double sweepAngleDegrees;
  final int tickCount;

  @override
  void paint(Canvas canvas, Size size) {
    final tickSpace = tickCount > 0 ? 8.0 : 0.0;
    final inset = (strokeWidth / 2) + tickSpace;
    final chartRect = Rect.fromLTWH(
      inset,
      inset,
      size.width - (inset * 2),
      size.height - (inset * 2),
    );
    final startAngle = _radians(startAngleDegrees);
    final sweepAngle = _radians(sweepAngleDegrees);
    final isFullCircle = sweepAngleDegrees.abs() >= 359.9;
    final strokeCap = isFullCircle ? StrokeCap.butt : StrokeCap.round;

    final trackPaint = Paint()
      ..color = AppColors.grey200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = strokeCap;
    canvas.drawArc(chartRect, startAngle, sweepAngle, false, trackPaint);

    if (maxValue > 0 && segments.isNotEmpty) {
      final gap = segments.length > 1 ? _radians(3) : 0.0;
      final availableSweep = math.max(
        0.0,
        sweepAngle - (gap * (segments.length - 1)),
      );
      var cursor = startAngle;

      for (final segment in segments) {
        final fraction = (segment.value / maxValue).clamp(0.0, 1.0);
        final segmentSweep = availableSweep * fraction;
        if (segmentSweep > 0) {
          final segmentPaint = Paint()
            ..color = segment.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = strokeCap;
          canvas.drawArc(
            chartRect,
            cursor,
            segmentSweep,
            false,
            segmentPaint,
          );
        }
        cursor += segmentSweep + gap;
      }
    }

    if (tickCount > 1) {
      final center = chartRect.center;
      final radius = chartRect.width / 2;
      final tickPaint = Paint()
        ..color = AppColors.grey400
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      for (var index = 0; index < tickCount; index++) {
        final fraction = index / (tickCount - 1);
        final angle = startAngle + (sweepAngle * fraction);
        final innerRadius = radius + (strokeWidth / 2) + 3;
        final outerRadius = innerRadius + 4;
        final direction = Offset(math.cos(angle), math.sin(angle));
        canvas.drawLine(
          center + (direction * innerRadius),
          center + (direction * outerRadius),
          tickPaint,
        );
      }
    }
  }

  double _radians(double degrees) => degrees * (math.pi / 180);

  @override
  bool shouldRepaint(_DashboardRadialPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.startAngleDegrees != startAngleDegrees ||
        oldDelegate.sweepAngleDegrees != sweepAngleDegrees ||
        oldDelegate.tickCount != tickCount;
  }
}
