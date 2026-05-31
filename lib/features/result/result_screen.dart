import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../quiz/quiz_controller.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(quizNotifierProvider);
    final theme = context.theme;
    final locale = Localizations.localeOf(context).languageCode;

    final total = state.questions.length;
    final score = state.score;
    final percent = total > 0 ? ((score / total) * 100).round() : 0;

    final message = percent >= 80
        ? l10n.result_message_excellent
        : percent >= 50
            ? l10n.result_message_good
            : l10n.result_message_keep_going;

    final params = ref.read(sessionParamsProvider);

    return FScaffold(
      header: FHeader(
        title: Text(l10n.result_title),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Score card
          FCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    l10n.result_score(score, total),
                    style: theme.typography.xl2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colors.foreground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.result_percentage(percent),
                    style: theme.typography.xl.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: total > 0 ? score / total : 0,
                    backgroundColor: theme.colors.secondary,
                    color: theme.colors.primary,
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: theme.typography.md.copyWith(
                      color: theme.colors.foreground,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          FButton(
            key: const Key('result_replay_btn'),
            onPress: params == null
                ? null
                : () {
                    ref.read(quizNotifierProvider.notifier).reset();
                    ref.read(sessionParamsProvider.notifier).state = params;
                    context.pushReplacement('/quiz');
                  },
            child: Text(l10n.result_replay),
          ),
          const SizedBox(height: 10),
          FButton(
            key: const Key('result_home_btn'),
            variant: FButtonVariant.outline,
            onPress: () {
              ref.read(quizNotifierProvider.notifier).reset();
              context.go('/');
            },
            child: Text(l10n.result_home),
          ),

          const SizedBox(height: 24),
          // Review section
          Text(
            l10n.result_review_title,
            style: theme.typography.lg.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(height: 12),
          ...state.answers.asMap().entries.map((entry) {
            final idx = entry.key;
            final record = entry.value;
            final q = record.question;
            final prompt = locale == 'fr' ? q.promptFr : q.promptEn;
            final correctOpt = q.options.where((o) => o.isCorrect).firstOrNull;
            final selectedOpt = q.options
                .where((o) => o.id == record.selectedOptionId)
                .firstOrNull;
            final correctText = correctOpt == null
                ? ''
                : (locale == 'fr' ? correctOpt.textFr : correctOpt.textEn);
            final selectedText = selectedOpt == null
                ? ''
                : (locale == 'fr' ? selectedOpt.textFr : selectedOpt.textEn);
            final isCorrect = record.isCorrect;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: isCorrect
                                ? successGreen
                                : theme.colors.destructive,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${idx + 1}.',
                            style: theme.typography.sm.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        prompt,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.foreground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!isCorrect && selectedText.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${l10n.result_your_answer}: $selectedText',
                          style: theme.typography.xs.copyWith(
                            color: theme.colors.destructive,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.result_correct_answer}: $correctText',
                        style: theme.typography.xs.copyWith(
                          color: successGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        q.sourceReference,
                        style: theme.typography.xs.copyWith(
                          color: theme.colors.mutedForeground,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
