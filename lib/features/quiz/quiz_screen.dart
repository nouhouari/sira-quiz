import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/islamic_pattern_painter.dart';
import '../../domain/models/quiz_question.dart';
import 'quiz_controller.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final params = ref.read(sessionParamsProvider);
      if (params == null) {
        context.go('/');
        return;
      }
      ref
          .read(quizNotifierProvider.notifier)
          .startSession(params.categorySlug, params.difficulty);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;
    final locale = Localizations.localeOf(context).languageCode;

    ref.listen<QuizState>(quizNotifierProvider, (prev, next) {
      if (next.isComplete && !(prev?.isComplete ?? false)) {
        context.pushReplacement('/result');
      }
    });

    final state = ref.watch(quizNotifierProvider);

    if (state.loading) {
      return FScaffold(
        child: Center(
          child: Text(
            l10n.common_loading,
            style: theme.typography.md.copyWith(
                color: theme.colors.mutedForeground),
          ),
        ),
      );
    }

    if (state.hasError) {
      final message = state.error == QuizError.noQuestions
          ? l10n.quizNoQuestions
          : l10n.common_error;
      return FScaffold(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: theme.typography.md.copyWith(color: theme.colors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: () => context.go('/'),
                  child: Text(l10n.result_home),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = state.currentQuestion;
    if (question == null) {
      return FScaffold(
        child: Center(
          child: Text(
            l10n.common_loading,
            style: theme.typography.md.copyWith(
                color: theme.colors.mutedForeground),
          ),
        ),
      );
    }

    final total = state.questions.length;
    final current = state.currentIndex + 1;
    final progress = current / total;
    final isDark = theme.colors.background.computeLuminance() < 0.2;

    return FScaffold(
      header: FHeader.nested(
        title: Text(l10n.quiz_question(current, total)),
        prefixes: [
          FHeaderAction.back(onPress: () => context.go('/')),
        ],
      ),
      // E-1: gold khatam motif at alpha 8, cellSize 44 on the sand/dark canvas
      // so the empty lower regions read as intentional, not unfinished.
      child: IslamicPatternOverlay(
        patternColor: gold,
        alpha: 8,
        cellSize: 44,
        child: Column(
          children: [
            // E-10: progress bar with a 6px gold dot at the filled fraction end.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _ProgressBarWithDot(
                value: progress,
                trackColor: isDark ? darkBorder : warmBorder,
                fillColor: isDark ? darkEmerald : emerald,
                dotColor: gold,
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: _QuizContent(
                  key: ValueKey(state.currentIndex),
                  question: question,
                  state: state,
                  locale: locale,
                  l10n: l10n,
                  theme: theme,
                  isDark: isDark,
                  ref: ref,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The question card + options — keyed by [currentIndex] so AnimatedSwitcher
/// fades between questions.
class _QuizContent extends StatelessWidget {
  final QuizQuestion question;
  final QuizState state;
  final String locale;
  final AppLocalizations l10n;
  final FThemeData theme;
  final bool isDark;
  final WidgetRef ref;

  const _QuizContent({
    super.key,
    required this.question,
    required this.state,
    required this.locale,
    required this.l10n,
    required this.theme,
    required this.isDark,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final prompt = locale == 'fr' ? question.promptFr : question.promptEn;
    final activeEmerald = isDark ? darkEmerald : emerald;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Question card
        Container(
          decoration: BoxDecoration(
            color: theme.colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 40 : 10),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Text(
            prompt,
            // E-2: Crimson Pro for reading content (quiz question text).
            style: TextStyle(
              fontFamily: kReadFont,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colors.foreground,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Options
        ...question.options.map((opt) {
          final text = locale == 'fr' ? opt.textFr : opt.textEn;
          final isSelected = state.selectedOptionId == opt.id;
          final isAnswered = state.answered;

          // Option state colors
          Color bgColor;
          Color borderColor;
          Color textColor;
          Widget? trailingIcon;

          if (isAnswered) {
            if (opt.isCorrect) {
              bgColor = activeEmerald.withAlpha(isDark ? 35 : 25);
              borderColor = activeEmerald;
              textColor = activeEmerald;
              trailingIcon = Icon(Icons.check_circle,
                  color: activeEmerald, size: 18);
            } else if (isSelected && !opt.isCorrect) {
              final errColor = isDark
                  ? const Color(0xFFCF6679)
                  : errorRed;
              bgColor = errColor.withAlpha(isDark ? 35 : 20);
              borderColor = errColor;
              textColor = errColor;
              trailingIcon = Icon(Icons.cancel, color: errColor, size: 18);
            } else {
              bgColor = theme.colors.card;
              borderColor = theme.colors.border.withAlpha(100);
              textColor = theme.colors.mutedForeground;
              trailingIcon = null;
            }
          } else if (isSelected) {
            // Selected-pending: gold ring + faint gold tint
            bgColor = gold.withAlpha(isDark ? 25 : 18);
            borderColor = gold;
            textColor = theme.colors.foreground;
            trailingIcon = null;
          } else {
            bgColor = theme.colors.card;
            borderColor = theme.colors.border;
            textColor = theme.colors.foreground;
            trailingIcon = null;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            // C-4: replaced InkWell (requires Material ancestor, crashes on
            // FScaffold) with GestureDetector + _PressTile animated tint.
            // This matches the GestureDetector+scale pattern used on buttons.
            child: _PressTile(
              key: Key('option_tile_${opt.id}'),
              onTap: (isAnswered || state.isComplete)
                  ? null
                  : () => ref
                      .read(quizNotifierProvider.notifier)
                      .selectOption(opt.id),
              pressColor: (isDark ? darkEmerald : emerald).withAlpha(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected || (isAnswered && opt.isCorrect)
                        ? 2.0
                        : 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontFamily: kBodyFont,
                          fontSize: 14,
                          color: textColor,
                          fontWeight:
                              isSelected || (isAnswered && opt.isCorrect)
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      trailingIcon,
                    ],
                  ],
                ),
              ),
            ),
          );
        }),

        // Feedback section shown after answering — size/fade in
        if (state.answered) ...[
          const SizedBox(height: 8),
          _AnimatedFeedbackCard(
            question: question,
            isCorrect: question.options
                .where((o) => o.isCorrect)
                .any((o) => o.id == state.selectedOptionId),
            locale: locale,
            l10n: l10n,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          if (!state.isComplete)
            _EmeraldNextButton(
              key: const Key('quiz_next_btn'),
              label: state.isLastQuestion
                  ? l10n.quiz_see_results
                  : l10n.quiz_next,
              onTap: () {
                ref.read(quizNotifierProvider.notifier).nextQuestion();
              },
              theme: theme,
              isDark: isDark,
            ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

/// Animated feedback card that fades+scales in after an answer.
class _AnimatedFeedbackCard extends StatefulWidget {
  final QuizQuestion question;
  final bool isCorrect;
  final String locale;
  final AppLocalizations l10n;
  final FThemeData theme;
  final bool isDark;

  const _AnimatedFeedbackCard({
    required this.question,
    required this.isCorrect,
    required this.locale,
    required this.l10n,
    required this.theme,
    required this.isDark,
  });

  @override
  State<_AnimatedFeedbackCard> createState() => _AnimatedFeedbackCardState();
}

class _AnimatedFeedbackCardState extends State<_AnimatedFeedbackCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: _FeedbackCard(
          question: widget.question,
          isCorrect: widget.isCorrect,
          locale: widget.locale,
          l10n: widget.l10n,
          theme: widget.theme,
          isDark: widget.isDark,
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final QuizQuestion question;
  final bool isCorrect;
  final String locale;
  final AppLocalizations l10n;
  final FThemeData theme;
  final bool isDark;

  const _FeedbackCard({
    required this.question,
    required this.isCorrect,
    required this.locale,
    required this.l10n,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final explanation =
        locale == 'fr' ? question.explanationFr : question.explanationEn;
    final sourceArabic = question.sourceArabic;
    final sourceRef = question.sourceReference;

    final activeEmerald = isDark ? darkEmerald : emerald;
    final errColor = isDark ? const Color(0xFFCF6679) : errorRed;
    final borderColor = isCorrect ? activeEmerald : errColor;
    final bgColor = isCorrect
        ? activeEmerald.withAlpha(isDark ? 25 : 15)
        : errColor.withAlpha(isDark ? 25 : 12);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withAlpha(100), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                color: borderColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? l10n.quiz_correct : l10n.quiz_incorrect,
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            // E-2: Crimson Pro for feedback explanation text.
            style: TextStyle(
              fontFamily: kReadFont,
              fontSize: 14,
              color: theme.colors.foreground,
              height: 1.55,
            ),
          ),
          if (sourceArabic != null && sourceArabic.isNotEmpty) ...[
            const SizedBox(height: 12),
            // Directionality is intentional — Arabic citation text is RTL.
            Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colors.card.withAlpha(isDark ? 60 : 180),
                  borderRadius: BorderRadius.circular(10),
                  // E-11: 2px gold left-border (which is right-side in RTL)
                  // signals this is a quotation / citation box.
                  border: Border(
                    right: BorderSide(
                        color: gold.withAlpha(150), width: 2),
                    top: BorderSide(
                        color: theme.colors.border.withAlpha(60), width: 0.5),
                    bottom: BorderSide(
                        color: theme.colors.border.withAlpha(60), width: 0.5),
                    left: BorderSide(
                        color: theme.colors.border.withAlpha(60), width: 0.5),
                  ),
                ),
                child: Text(
                  sourceArabic,
                  style: TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 16,
                    color: theme.colors.foreground,
                    height: 1.9,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.quiz_source}: ',
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colors.mutedForeground,
                ),
              ),
              Expanded(
                child: Text(
                  sourceRef,
                  style: TextStyle(
                    fontFamily: kBodyFont,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Horizontal progress bar with a 6px gold dot at the progress fraction tip
/// (E-10 — mirrors the score ring's gold endpoint).
class _ProgressBarWithDot extends StatelessWidget {
  final double value;
  final Color trackColor;
  final Color fillColor;
  final Color dotColor;

  const _ProgressBarWithDot({
    required this.value,
    required this.trackColor,
    required this.fillColor,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10, // gives room for the dot
      child: CustomPaint(
        painter: _ProgressDotPainter(
          value: value.clamp(0.0, 1.0),
          trackColor: trackColor,
          fillColor: fillColor,
          dotColor: dotColor,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ProgressDotPainter extends CustomPainter {
  final double value;
  final Color trackColor;
  final Color fillColor;
  final Color dotColor;

  const _ProgressDotPainter({
    required this.value,
    required this.trackColor,
    required this.fillColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barHeight = 6.0;
    final barTop = (size.height - barHeight) / 2;
    final radius = Radius.circular(barHeight / 2);

    // Track
    final trackRect = RRect.fromLTRBR(
        0, barTop, size.width, barTop + barHeight, radius);
    canvas.drawRRect(trackRect, Paint()..color = trackColor);

    // Fill
    if (value > 0) {
      final fillWidth = size.width * value;
      final fillRect = RRect.fromLTRBR(
          0, barTop, fillWidth, barTop + barHeight, radius);
      canvas.drawRRect(fillRect, Paint()..color = fillColor);

      // Gold dot at the end
      final dotCx = fillWidth;
      final dotCy = size.height / 2;
      canvas.drawCircle(
          Offset(dotCx, dotCy), 5, Paint()..color = dotColor);
    }
  }

  @override
  bool shouldRepaint(_ProgressDotPainter old) =>
      old.value != value ||
      old.trackColor != trackColor ||
      old.fillColor != fillColor ||
      old.dotColor != dotColor;
}

/// A tap target that tints its child with [pressColor] on press, without
/// requiring a Material ancestor (safe inside FScaffold — fixes C-4 crash).
class _PressTile extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color pressColor;

  const _PressTile({
    super.key,
    required this.child,
    required this.onTap,
    required this.pressColor,
  });

  @override
  State<_PressTile> createState() => _PressTileState();
}

class _PressTileState extends State<_PressTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _pressed = false) : null,
      child: Stack(
        children: [
          widget.child,
          if (_pressed)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ColoredBox(color: widget.pressColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-width emerald primary "Next" button with scale press animation.
class _EmeraldNextButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final FThemeData theme;
  final bool isDark;

  const _EmeraldNextButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.theme,
    required this.isDark,
  });

  @override
  State<_EmeraldNextButton> createState() => _EmeraldNextButtonState();
}

class _EmeraldNextButtonState extends State<_EmeraldNextButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // H-2: dark mode uses darkEmeraldButton (#0F7A63) so white text ≥4.5:1.
    final bg = widget.isDark ? darkEmeraldButton : emerald;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        // L-3: button uses same 16px horizontal margin as option cards.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: emerald.withAlpha(50),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  // H-2: on dark mode, bg is darkEmeraldButton (#0F7A63),
                  // white text gives ~4.7:1 contrast — passes WCAG AA.
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
