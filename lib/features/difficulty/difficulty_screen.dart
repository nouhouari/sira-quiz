import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/arb/app_localizations.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../domain/models/difficulty.dart';
import '../quiz/quiz_controller.dart';

class DifficultyScreen extends ConsumerWidget {
  final String categorySlug;
  const DifficultyScreen({super.key, required this.categorySlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;

    return FScaffold(
      header: FHeader.nested(
        title: Text(l10n.difficulty_title),
        prefixes: [
          FHeaderAction.back(onPress: () => context.pop()),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: Difficulty.values.map((d) {
          final countAsync = ref.watch(questionCountProvider(
              (slug: categorySlug, difficulty: d)));
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: countAsync.when(
              loading: () => _DifficultyCard(
                difficulty: d,
                l10n: l10n,
                theme: theme,
                count: null,
                onTap: null,
              ),
              error: (_, _) => _DifficultyCard(
                difficulty: d,
                l10n: l10n,
                theme: theme,
                count: 0,
                onTap: null,
              ),
              data: (count) => _DifficultyCard(
                key: Key('difficulty_card_${d.name}'),
                difficulty: d,
                l10n: l10n,
                theme: theme,
                count: count,
                onTap: count > 0
                    ? () {
                        ref.read(sessionParamsProvider.notifier).state =
                            SessionParams(
                                categorySlug: categorySlug,
                                difficulty: d);
                        context.push('/quiz');
                      }
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final Difficulty difficulty;
  final AppLocalizations l10n;
  final FThemeData theme;
  final int? count;
  final VoidCallback? onTap;

  const _DifficultyCard({
    super.key,
    required this.difficulty,
    required this.l10n,
    required this.theme,
    required this.count,
    required this.onTap,
  });

  String get _label => switch (difficulty) {
        Difficulty.beginner => l10n.difficulty_beginner,
        Difficulty.intermediate => l10n.difficulty_intermediate,
        Difficulty.advanced => l10n.difficulty_advanced,
      };

  String get _desc => switch (difficulty) {
        Difficulty.beginner => l10n.difficulty_beginner_desc,
        Difficulty.intermediate => l10n.difficulty_intermediate_desc,
        Difficulty.advanced => l10n.difficulty_advanced_desc,
      };

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: onTap,
        child: FCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label,
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _desc,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        count == null
                            ? '...'
                            : count! == 0
                                ? l10n.difficulty_no_questions
                                : l10n.difficulty_questions_available(count!),
                        style: theme.typography.xs.copyWith(
                          color: enabled
                              ? theme.colors.primary
                              : theme.colors.mutedForeground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
