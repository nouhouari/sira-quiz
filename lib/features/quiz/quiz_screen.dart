import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
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
        // No session params (e.g. deep-link or process-restore).
        // Navigate home rather than showing an infinite loader.
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

    // Navigate to result screen exactly once when the quiz completes.
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
    final prompt = locale == 'fr' ? question.promptFr : question.promptEn;

    return FScaffold(
      header: FHeader.nested(
        title: Text(l10n.quiz_question(current, total)),
        prefixes: [
          FHeaderAction.back(onPress: () => context.go('/')),
        ],
      ),
      child: Column(
        children: [
          // Progress bar — same horizontal padding as question card, tight top
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colors.secondary,
              color: theme.colors.primary,
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // Question card
                FCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      prompt,
                      style: theme.typography.lg.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colors.foreground,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Options
                ...question.options.map((opt) {
                  final text =
                      locale == 'fr' ? opt.textFr : opt.textEn;
                  final isSelected = state.selectedOptionId == opt.id;
                  final isAnswered = state.answered;

                  Color bgColor = theme.colors.card;
                  Color borderColor = theme.colors.border;
                  Color textColor = theme.colors.foreground;

                  if (isAnswered) {
                    if (opt.isCorrect) {
                      bgColor = successGreen.withAlpha(30);
                      borderColor = successGreen;
                      textColor = successGreen;
                    } else if (isSelected && !opt.isCorrect) {
                      bgColor = theme.colors.destructive.withAlpha(25);
                      borderColor = theme.colors.destructive;
                      textColor = theme.colors.destructive;
                    }
                  } else if (isSelected) {
                    bgColor = theme.colors.primary.withAlpha(25);
                    borderColor = theme.colors.primary;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      key: Key('option_tile_${opt.id}'),
                      // Ignore taps once answered or once quiz is complete
                      // (guards against rapid double-tap on the last question).
                      onTap: (isAnswered || state.isComplete)
                          ? null
                          : () => ref
                              .read(quizNotifierProvider.notifier)
                              .selectOption(opt.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: borderColor, width: 1.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Text(
                          text,
                          style: theme.typography.md.copyWith(
                            color: textColor,
                            fontWeight:
                                isSelected ||
                                        (isAnswered && opt.isCorrect)
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // Feedback section shown after answering
                if (state.answered) ...[
                  const SizedBox(height: 8),
                  _FeedbackCard(
                    question: question,
                    isCorrect: question.options
                        .where((o) => o.isCorrect)
                        .any((o) => o.id == state.selectedOptionId),
                    locale: locale,
                    l10n: l10n,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  // Button is disabled once complete (ref.listen navigates away).
                  if (!state.isComplete)
                    FButton(
                      key: const Key('quiz_next_btn'),
                      onPress: () {
                        ref
                            .read(quizNotifierProvider.notifier)
                            .nextQuestion();
                        // Navigation for the last question is handled by the
                        // ref.listen above — no imperative navigate call here.
                      },
                      child: Text(
                        state.isLastQuestion
                            ? l10n.quiz_see_results
                            : l10n.quiz_next,
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final QuizQuestion question; // was `dynamic` — now strongly typed
  final bool isCorrect;
  final String locale;
  final AppLocalizations l10n;
  final FThemeData theme;

  const _FeedbackCard({
    required this.question,
    required this.isCorrect,
    required this.locale,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final explanation =
        locale == 'fr' ? question.explanationFr : question.explanationEn;
    final sourceArabic = question.sourceArabic;
    final sourceRef = question.sourceReference;

    final borderColor = isCorrect ? successGreen : theme.colors.destructive;
    final bgColor = isCorrect
        ? successGreen.withAlpha(15)
        : theme.colors.destructive.withAlpha(15);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withAlpha(80), width: 1),
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
                style: theme.typography.md.copyWith(
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: theme.typography.sm.copyWith(color: theme.colors.foreground),
          ),
          if (sourceArabic != null && sourceArabic.isNotEmpty) ...[
            const SizedBox(height: 12),
            // Directionality is intentional — Arabic citation text is RTL
            // even though the app is FR/EN only (Arabic/RTL locale is out of
            // scope for this version; see app.dart comment).
            Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sourceArabic,
                  style: theme.typography.md.copyWith(
                    color: theme.colors.foreground,
                    height: 1.8,
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
                style: theme.typography.xs.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colors.mutedForeground,
                ),
              ),
              Expanded(
                child: Text(
                  sourceRef,
                  style: theme.typography.xs.copyWith(
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
