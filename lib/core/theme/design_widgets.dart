import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'islamic_pattern_painter.dart';

// ── Emerald gradient header ───────────────────────────────────────────────────

/// Shared emerald gradient header area used on Home and Result screens.
///
/// Renders a gradient from [emeraldDark] to [emerald], with the Islamic pattern
/// as a faint watermark, a thin gold hairline at the bottom, and [child]
/// centred inside.
class EmeraldHeader extends StatelessWidget {
  final Widget child;

  /// If null, uses a fixed height. If non-null, the header will be that height.
  final double? height;

  const EmeraldHeader({
    super.key,
    required this.child,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: IslamicPatternOverlay(
        patternColor: gold,
        // E-1: alpha 45, strokeWidth 1.2, cellSize 28 — the khatam motif reads
        // as watermark paper on the emerald header (subtly perceptible, not noisy).
        alpha: 45,
        cellSize: 28,
        strokeWidth: 1.2,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [emeraldDark, emerald],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Center(child: child),
              ),
              // Gold hairline separator.
              Container(
                height: 1.5,
                color: gold.withAlpha(120),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── App icon chip ─────────────────────────────────────────────────────────────

/// Circular emerald-tinted icon chip with a thin gold ring — used in the
/// Home and Result headers.
class AppIconChip extends StatelessWidget {
  final double size;
  final IconData icon;
  final bool dark;

  const AppIconChip({
    super.key,
    this.size = 80,
    this.icon = Icons.menu_book_rounded,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    // C-3: gold #C8A24A on emerald = ~2.1:1 (fails 3:1 for UI components).
    // Fix: lighter gold ring #E0C070 (≈3.1:1 on emerald) at 2.5px width,
    // plus 1.5px ivory inner separator to create a visible gap.
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Outer lighter gold ring — #E0C070 ≈3.1:1 on emerald.
        border: Border.all(
          color: const Color(0xFFE0C070),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: emeraldDark.withAlpha(80),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // 1.5px ivory inner separator between the gold ring and the fill,
          // ensuring the ring reads clearly as a distinct frame.
          border: Border.all(
            color: Colors.white.withAlpha(160),
            width: 1.5,
          ),
          // Inner fill: semi-transparent white on gradient bg.
          color: Colors.white.withAlpha(dark ? 20 : 35),
        ),
        child: Icon(
          icon,
          size: size * 0.50,
          color: Colors.white.withAlpha(230),
        ),
      ),
    );
  }
}

// ── Animated circular progress ring ──────────────────────────────────────────

/// Animated circular progress ring displayed on the Result screen.
///
/// Animates from 0 to [progress] (0.0 - 1.0) on mount. Shows [scoreLabel]
/// (e.g. "7 / 10") and [percentLabel] (e.g. "70%") in the centre.
///
/// E-4: the displayed integer counts up in sync with the arc animation, and
/// a 0% result tints the track red to signal "needs work".
class AnimatedScoreRing extends StatefulWidget {
  final double progress;
  final String scoreLabel;
  final String percentLabel;
  final bool isDark;

  /// Total question count — used to drive the count-up integer display (E-4).
  final int? total;

  const AnimatedScoreRing({
    super.key,
    required this.progress,
    required this.scoreLabel,
    required this.percentLabel,
    this.isDark = false,
    this.total,
  });

  @override
  State<AnimatedScoreRing> createState() => _AnimatedScoreRingState();
}

class _AnimatedScoreRingState extends State<AnimatedScoreRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // E-4: zero-result tints the track red to signal "needs work".
    final trackColor = widget.progress == 0.0
        ? errorRed.withAlpha(60)
        : (widget.isDark ? darkBorder : warmBorder);
    final progressColor = widget.progress >= 0.5
        ? (widget.isDark ? darkEmerald : emerald)
        : errorRed.withAlpha(200);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final animatedProgress = _anim.value * widget.progress;

        // E-4: count-up integer — derive the displayed score from anim value.
        final String displayedScore;
        if (widget.total != null && widget.total! > 0) {
          final countedScore =
              (animatedProgress * widget.total!).round();
          displayedScore = '$countedScore / ${widget.total}';
        } else {
          displayedScore = widget.scoreLabel;
        }

        return SizedBox(
          width: 170,
          height: 170,
          child: CustomPaint(
            painter: _RingPainter(
              progress: animatedProgress,
              trackColor: trackColor,
              progressColor: progressColor,
              goldColor: gold,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayedScore,
                    style: TextStyle(
                      fontFamily: kDisplayFont,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? darkText : ink,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.percentLabel,
                    style: TextStyle(
                      fontFamily: kBodyFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark ? const Color(0xFF7A9B8E) : inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Color goldColor;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.goldColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 14;
    const strokeWidth = 12.0;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Track (background arc)
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + math.pi * 2 * progress,
          colors: [progressColor, goldColor.withAlpha(220)],
          stops: const [0.0, 1.0],
        ).createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      canvas.drawArc(
          rect, -math.pi / 2, math.pi * 2 * progress, false, progressPaint);
    }

    // Small gold dot at end of progress
    if (progress > 0.02) {
      final angle = -math.pi / 2 + math.pi * 2 * progress;
      final dotX = cx + radius * math.cos(angle);
      final dotY = cy + radius * math.sin(angle);
      final dotPaint = Paint()
        ..color = goldColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dotX, dotY), 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}

// ── Decorative band ───────────────────────────────────────────────────────────

/// A thin decorative horizontal band with an Islamic lattice pattern,
/// used between header and content areas.
class DecorativeBand extends StatelessWidget {
  final Color? backgroundColor;

  const DecorativeBand({super.key, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: IslamicPatternOverlay(
        patternColor: gold,
        alpha: 20,
        cellSize: 10,
        child: Container(
          color: backgroundColor ?? emerald.withAlpha(8),
        ),
      ),
    );
  }
}
