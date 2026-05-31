import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/islamic_pattern_painter.dart';
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

    // H-1: vertically center the card group. We build the cards into a Column
    // and wrap in a Center inside a SingleChildScrollView so on larger phones
    // the group is vertically distributed rather than stuck at the top.
    final cards = Difficulty.values.map((d) {
      final countAsync = ref.watch(questionCountProvider(
          (slug: categorySlug, difficulty: d)));
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
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
    }).toList();

    return FScaffold(
      header: FHeader.nested(
        title: Text(l10n.difficulty_title),
        prefixes: [
          FHeaderAction.back(onPress: () => context.pop()),
        ],
      ),
      // E-1: gold khatam motif at alpha 8, cellSize 44 behind difficulty cards.
      child: IslamicPatternOverlay(
        patternColor: gold,
        alpha: 8,
        cellSize: 44,
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    ...cards,
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  /// Number of pip dots (1/2/3) — visual weight indicator for difficulty.
  int get _pips => switch (difficulty) {
        Difficulty.beginner => 1,
        Difficulty.intermediate => 2,
        Difficulty.advanced => 3,
      };

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final isDark = theme.colors.background.computeLuminance() < 0.2;

    // Emerald intensity ramp per difficulty level.
    final emeraldAlpha = switch (difficulty) {
      Difficulty.beginner => 18,
      Difficulty.intermediate => 35,
      Difficulty.advanced => 55,
    };

    final activeEmerald = isDark ? darkEmerald : emerald;
    // C-1: chevron must be emerald on white/sand — gold fails WCAG (~2.7:1).
    final chevronColor = enabled
        ? (isDark ? darkEmerald : emerald)
        : theme.colors.mutedForeground.withAlpha(100);

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? activeEmerald.withAlpha(emeraldAlpha + 20)
                  : theme.colors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 35 : 10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          // H-1: increased vertical padding so cards breathe more.
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Emerald-tinted pip indicator
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: activeEmerald.withAlpha(emeraldAlpha),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _PipRow(
                        count: _pips,
                        color: activeEmerald,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label,
                      style: TextStyle(
                        fontFamily: kDisplayFont,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colors.foreground,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _desc,
                      style: TextStyle(
                        fontFamily: kBodyFont,
                        fontSize: 12,
                        color: theme.colors.mutedForeground,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      count == null
                          ? '...'
                          : count! == 0
                              ? l10n.difficulty_no_questions
                              : l10n.difficulty_questions_available(count!),
                      style: TextStyle(
                        fontFamily: kBodyFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        // C-2: use solid emerald #0B6B57 (5.9:1 on white) in
                        // light mode. Dark uses darkEmerald which is lighter
                        // and passes on the dark card surface (~4.8:1).
                        color: enabled
                            ? (isDark ? darkEmerald : emerald)
                            : theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              // C-1: emerald chevron — ~6:1 on white, passes WCAG AA.
              Icon(
                Icons.chevron_right,
                color: chevronColor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small pip dots indicating difficulty level (1 = beginner, 3 = advanced).
class _PipRow extends StatelessWidget {
  final int count;
  final Color color;

  const _PipRow({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final active = i < count;
        return Padding(
          padding: EdgeInsets.only(right: i < 2 ? 3 : 0),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? color : color.withAlpha(50),
            ),
          ),
        );
      }),
    );
  }
}
