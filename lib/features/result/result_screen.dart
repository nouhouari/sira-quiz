import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_widgets.dart';
import '../quiz/quiz_controller.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(quizNotifierProvider);
    final theme = context.theme;
    final locale = Localizations.localeOf(context).languageCode;
    final isDark = theme.colors.background.computeLuminance() < 0.2;

    final total = state.questions.length;
    final score = state.score;
    final percent = total > 0 ? ((score / total) * 100).round() : 0;
    final progress = total > 0 ? score / total : 0.0;

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
      // H-3: SafeArea-aware top padding so the content isn't flush to the header.
      // Responsive horizontal padding: on screens wider than 640px, the content
      // is centred within a 640px column; on mobile (≤640px) keeps the 16px gutter.
      child: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.sizeOf(context).width;
          final hPad = screenWidth > 640
              ? (screenWidth - 640) / 2
              : 16.0;
          return ListView(
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 32),
            children: [
          // ── Emerald score card with circular ring ─────────────────────────
          _ScoreCard(
            score: score,
            total: total,
            percent: percent,
            progress: progress.toDouble(),
            message: message,
            isDark: isDark,
            l10n: l10n,
            theme: theme,
          ),
          const SizedBox(height: 16),

          // Action buttons
          _ResultPrimaryButton(
            key: const Key('result_replay_btn'),
            label: l10n.result_replay,
            enabled: params != null,
            onTap: params == null
                ? null
                : () {
                    ref.read(quizNotifierProvider.notifier).reset();
                    ref.read(sessionParamsProvider.notifier).state = params;
                    context.pushReplacement('/quiz');
                  },
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          // Two secondary actions side-by-side — thumb-friendly at ≥390px
          // (each half-width minus the 8px gap = ~179px, well above 44px min).
          Row(
            children: [
              Expanded(
                child: _ResultOutlineButton(
                  key: const Key('result_levels_btn'),
                  label: l10n.result_choose_level,
                  onTap: () {
                    final p = ref.read(sessionParamsProvider);
                    ref.read(quizNotifierProvider.notifier).reset();
                    if (context.canPop()) {
                      context.pop();
                    } else if (p != null) {
                      context.go('/difficulty?cat=${p.categorySlug}');
                    } else {
                      context.go('/'); // safe fallback — never leave the user on a wiped result screen
                    }
                  },
                  isDark: isDark,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ResultOutlineButton(
                  key: const Key('result_home_btn'),
                  label: l10n.result_home,
                  onTap: () {
                    ref.read(quizNotifierProvider.notifier).reset();
                    context.go('/');
                  },
                  isDark: isDark,
                  theme: theme,
                ),
              ),
            ],
          ),

          // H-3: ≥24px separation between action buttons and the review section.
          const SizedBox(height: 32),

          // Review section header
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.result_review_title.toUpperCase(),
                  style: TextStyle(
                    fontFamily: kBodyFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colors.mutedForeground,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              // E-8: emerald tint for review section hairline (not gold).
              Container(
                width: 32,
                height: 1,
                color: (isDark ? darkEmerald : emerald).withAlpha(60),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...state.answers.asMap().entries.map((entry) {
            final idx = entry.key;
            final record = entry.value;
            final q = record.question;
            final prompt = locale == 'fr' ? q.promptFr : q.promptEn;
            final correctOpt =
                q.options.where((o) => o.isCorrect).firstOrNull;
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
            final activeEmerald = isDark ? darkEmerald : emerald;
            final errColor =
                isDark ? const Color(0xFFCF6679) : errorRed;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCorrect
                        ? activeEmerald.withAlpha(isDark ? 50 : 35)
                        : errColor.withAlpha(isDark ? 50 : 30),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 30 : 8),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // E-6: header row icons → 20px (clearly readable affordance).
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? activeEmerald : errColor,
                          size: 20,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '${idx + 1}.',
                          style: TextStyle(
                            fontFamily: kBodyFont,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      prompt,
                      style: TextStyle(
                        fontFamily: kBodyFont,
                        fontSize: 13,
                        color: theme.colors.foreground,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    if (!isCorrect && selectedText.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      // E-6: inline ✗ icon → 15px for readable affordance.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.cancel,
                              color: errColor, size: 15),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${l10n.result_your_answer}: $selectedText',
                              style: TextStyle(
                                fontFamily: kBodyFont,
                                fontSize: 11,
                                color: errColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 3),
                    // E-6: inline ✓ icon → 15px for readable affordance.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle,
                            color: activeEmerald, size: 15),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${l10n.result_correct_answer}: $correctText',
                            style: TextStyle(
                              fontFamily: kBodyFont,
                              fontSize: 11,
                              color: activeEmerald,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      q.sourceReference,
                      style: TextStyle(
                        fontFamily: kBodyFont,
                        fontSize: 10,
                        color: theme.colors.mutedForeground,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
          );
        },
      ),
    );
  }
}

// ── Score card ────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final int score;
  final int total;
  final int percent;
  final double progress;
  final String message;
  final bool isDark;
  final AppLocalizations l10n;
  final FThemeData theme;

  const _ScoreCard({
    required this.score,
    required this.total,
    required this.percent,
    required this.progress,
    required this.message,
    required this.isDark,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Emerald header strip with Islamic pattern watermark (no title — the
            // FHeader above already shows result_title once, and the integration
            // test expects exactly one "Résultats" widget on screen).
            SizedBox(
              height: 56,
              child: EmeraldHeader(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppIconChip(
                      size: 30,
                      icon: Icons.menu_book_rounded,
                    ),
                  ],
                ),
              ),
            ),
            // Ring + message
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  AnimatedScoreRing(
                    progress: progress,
                    scoreLabel: l10n.result_score(score, total),
                    percentLabel: l10n.result_percentage(percent),
                    isDark: isDark,
                    // E-4: pass total so the ring count-up works correctly.
                    total: total,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    message,
                    style: TextStyle(
                      fontFamily: kDisplayFont,
                      fontSize: 16,
                      color: theme.colors.foreground,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action buttons ────────────────────────────────────────────────────────────

class _ResultPrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  final bool isDark;

  const _ResultPrimaryButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // H-2: dark mode uses deepened emerald (#0F7A63) so white text ≥4.5:1.
    final bg = isDark ? darkEmeraldButton : emerald;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: emerald.withAlpha(50),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: kBodyFont,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                // Always white — passes WCAG AA on both emerald (#0B6B57→4.6:1)
                // and darkEmeraldButton (#0F7A63→4.7:1).
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final FThemeData theme;

  const _ResultOutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? darkEmerald : emerald;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: theme.colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primaryColor.withAlpha(180),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: kBodyFont,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
