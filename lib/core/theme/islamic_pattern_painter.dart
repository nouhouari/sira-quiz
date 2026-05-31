import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A CustomPainter that draws a subtle 8-point-star / interlaced-lattice
/// (khatam) pattern as a low-opacity geometric watermark.
///
/// Use at ~3-6% opacity (`color.withAlpha(10..15)`) behind header areas and
/// score cards so text readability is preserved.
class IslamicPatternPainter extends CustomPainter {
  /// The colour of the pattern lines (usually gold or emerald at low alpha).
  final Color color;

  /// The size of each star cell (distance from centre to outer point).
  final double cellSize;

  /// Stroke width of pattern lines. Default 0.8; use 1.2 on larger headers
  /// where the motif should read as watermark paper (E-1).
  final double strokeWidth;

  const IslamicPatternPainter({
    required this.color,
    this.cellSize = 36,
    this.strokeWidth = 0.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // Tile the 8-point star pattern across the canvas.
    // The horizontal step is 2 * cellSize, vertical step is 2 * cellSize,
    // with a half-step offset on alternating rows to form a lattice.
    final stepX = cellSize * 2;
    final stepY = cellSize * 2;

    final cols = (size.width / stepX).ceil() + 2;
    final rows = (size.height / stepY).ceil() + 2;

    for (var row = -1; row <= rows; row++) {
      for (var col = -1; col <= cols; col++) {
        final cx = col * stepX + (row.isOdd ? stepX / 2 : 0);
        final cy = row * stepY;
        _drawStar(canvas, paint, Offset(cx, cy), cellSize);
      }
    }
  }

  /// Draws a single 8-point star centred at [centre] with outer radius [r].
  void _drawStar(Canvas canvas, Paint paint, Offset centre, double r) {
    const points = 8;
    const innerRatio = 0.42; // ratio of inner radius to outer
    final inner = r * innerRatio;
    final path = Path();

    for (var i = 0; i < points * 2; i++) {
      // Alternate between outer and inner points.
      final radius = i.isEven ? r : inner;
      // Start at the top, rotate by half a step for orientation.
      final angle = (math.pi / points) * i - math.pi / 2;
      final x = centre.dx + radius * math.cos(angle);
      final y = centre.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Draw the inner octagon (connecting inner points) — gives the
    // interlaced-lattice look typical of khatam patterns.
    final octPath = Path();
    for (var i = 0; i < points; i++) {
      final angle = (math.pi / points) * (i * 2 + 1) - math.pi / 2;
      final x = centre.dx + inner * math.cos(angle);
      final y = centre.dy + inner * math.sin(angle);
      if (i == 0) {
        octPath.moveTo(x, y);
      } else {
        octPath.lineTo(x, y);
      }
    }
    octPath.close();
    canvas.drawPath(octPath, paint);
  }

  @override
  bool shouldRepaint(IslamicPatternPainter old) =>
      old.color != color || old.cellSize != cellSize || old.strokeWidth != strokeWidth;
}

/// A widget that overlays the Islamic lattice pattern at very low opacity.
///
/// Wrap it around any background/header to add the geometric motif without
/// affecting text readability.
class IslamicPatternOverlay extends StatelessWidget {
  final Widget child;

  /// Pattern line colour before opacity. Typically [gold] or [emerald].
  final Color patternColor;

  /// Alpha 0-255 applied to [patternColor]. Default = 12 (~5%).
  final int alpha;

  /// Cell size passed to [IslamicPatternPainter].
  final double cellSize;

  /// Stroke width forwarded to [IslamicPatternPainter]. Default = 0.8.
  /// Use 1.2 on the emerald header for the "watermark paper" E-1 look.
  final double strokeWidth;

  const IslamicPatternOverlay({
    super.key,
    required this.child,
    required this.patternColor,
    this.alpha = 12,
    this.cellSize = 36,
    this.strokeWidth = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: IslamicPatternPainter(
                color: patternColor.withAlpha(alpha),
                cellSize: cellSize,
                strokeWidth: strokeWidth,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
