import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../core/constants/quran_ayat.dart';
import '../../core/l10n/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_widgets.dart';
import '../../core/theme/islamic_pattern_painter.dart';

// ── Public entry-point ────────────────────────────────────────────────────────

/// Opens the welcome sheet as a modal bottom sheet.
///
/// Height is capped at 85% of the screen so that long French text and
/// the two Qur'anic verses never overflow on a ≈390 px phone.
Future<void> showWelcomeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: false,
    backgroundColor: Colors.transparent,
    builder: (context) => const _WelcomeSheet(),
  );
}

// ── Sheet widget ──────────────────────────────────────────────────────────────

class _WelcomeSheet extends StatelessWidget {
  const _WelcomeSheet();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.colors.background.computeLuminance() < 0.2;
    final l10n = AppLocalizations.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;

    final bg = isDark ? darkBg : sandBg;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        // Center + ConstrainedBox caps content width at 640px on tablet/desktop
        // while leaving mobile (≤640px) completely unchanged.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Drag handle ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 0),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: gold.withAlpha(110),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                // ── Scrollable content (verses, du'a, etc.) ─────────────
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: _WelcomeScrollableContent(
                      l10n: l10n,
                      theme: theme,
                      isDark: isDark,
                    ),
                  ),
                ),

                // ── Pinned Begin button — always visible ─────────────────
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: Semantics(
                      button: true,
                      label: l10n.welcome_begin,
                      child: _BeginButton(
                        label: l10n.welcome_begin,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Scrollable content column ─────────────────────────────────────────────────
// Does NOT include the Begin button — it is pinned outside the scroll area.

class _WelcomeScrollableContent extends StatelessWidget {
  final AppLocalizations l10n;
  final FThemeData theme;
  final bool isDark;

  const _WelcomeScrollableContent({
    required this.l10n,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Header: icon chip + title ──────────────────────────────────
        _HeaderZone(l10n: l10n, theme: theme, isDark: isDark),
        const SizedBox(height: 4),

        // Decorative band below header (matches app's transition pattern)
        const DecorativeBand(),
        const SizedBox(height: 20),

        // ── 2. Intro paragraph ────────────────────────────────────────────
        Text(
          l10n.welcome_intro,
          style: TextStyle(
            fontFamily: kReadFont,
            fontFamilyFallback: kFontFallback,
            fontSize: 16,
            color: isDark ? darkText : ink,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 24),

        // ── 3. Verse 1 — Al-Aḥzāb 33:21 ─────────────────────────────────
        _VerseBlock(
          arabicText: kAyahAhzab33_21,
          translation: l10n.welcome_verse_ahzab_translation,
          reference: l10n.welcome_verse_ahzab_ref,
          theme: theme,
          isDark: isDark,
        ),
        const SizedBox(height: 20),

        // ── 4. Verse 2 — Âl ʿImrān 3:31 ─────────────────────────────────
        _VerseBlock(
          arabicText: kAyahImran3_31,
          translation: l10n.welcome_verse_imran_translation,
          reference: l10n.welcome_verse_imran_ref,
          theme: theme,
          isDark: isDark,
        ),
        const SizedBox(height: 24),

        // ── 5. Ornamental divider ─────────────────────────────────────────
        _OrnamentalDivider(isDark: isDark),
        const SizedBox(height: 16),

        // ── 6. Closing line ───────────────────────────────────────────────
        Text(
          l10n.welcome_closing,
          style: TextStyle(
            fontFamily: kReadFont,
            fontFamilyFallback: kFontFallback,
            fontSize: 15,
            fontStyle: FontStyle.italic,
            color: isDark
                ? darkText.withAlpha(180)
                : inkSoft,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // ── 7. Gold-bordered disclaimer card ─────────────────────────────
        _DisclaimerCard(l10n: l10n, theme: theme, isDark: isDark),
        const SizedBox(height: 28),

        // ── 8. Du'a block ─────────────────────────────────────────────────
        _DuaBlock(l10n: l10n, isDark: isDark),
        // Extra bottom padding so the last item clears the pinned button bar.
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Header zone ───────────────────────────────────────────────────────────────

class _HeaderZone extends StatelessWidget {
  final AppLocalizations l10n;
  final FThemeData theme;
  final bool isDark;

  const _HeaderZone({
    required this.l10n,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Chip uses the dark gradient in dark mode (E-fix: was hardcoded false).
        AppIconChip(size: 48, dark: isDark),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.welcome_title,
              style: TextStyle(
                fontFamily: kDisplayFont,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? darkText : ink,
                letterSpacing: -0.3,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            // Thin gold hairline ornament beneath the title.
            Container(
              width: 60,
              height: 1,
              color: gold.withAlpha(160),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Verse block ───────────────────────────────────────────────────────────────

/// Renders a single Qur'anic verse: Arabic in a styled RTL container (matching
/// the quiz_screen.dart sourceArabic pattern), followed by the italic
/// translation and a gold-tinted reference line.
class _VerseBlock extends StatelessWidget {
  final String arabicText;
  final String translation;
  final String reference;
  final FThemeData theme;
  final bool isDark;

  const _VerseBlock({
    required this.arabicText,
    required this.translation,
    required this.reference,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // 12px left-indent makes the block read as a block-quote relative to
    // the intro text, matching the "illuminated manuscript" design direction.
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Arabic text (EXACT pattern from quiz_screen.dart ──────────
          // Directionality + ClipRRect + Stack with gold right-border overlay.
          Directionality(
            textDirection: TextDirection.rtl,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  // Base container: uniform subtle border + background.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colors.card
                          .withAlpha(isDark ? 80 : 220),
                      border: Border.all(
                        color: theme.colors.border.withAlpha(60),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      arabicText,
                      style: TextStyle(
                        fontFamily: kDisplayFont,
                        fontFamilyFallback: kFontFallback,
                        fontSize: 19,
                        color: theme.colors.foreground,
                        height: 1.9,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  // Gold right-border overlay (visual right in RTL = start).
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 2,
                      color: gold.withAlpha(150),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Translation (CrimsonPro italic) ──────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              translation,
              style: TextStyle(
                fontFamily: kReadFont,
                fontFamilyFallback: kFontFallback,
                fontStyle: FontStyle.italic,
                fontSize: 15,
                color: isDark
                    ? darkText.withAlpha(200)
                    : inkSoft,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // ── Reference (Inter small, gold-tinted) ─────────────────────
          // WCAG AA: goldDeep (#A9842F) is ~3.8:1 on sandBg — fails AA.
          // goldText (#7A5E1A) is ~5.2:1 — passes AA for normal text.
          // Dark mode retains darkGold which is fine on the dark surface.
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              reference,
              style: TextStyle(
                fontFamily: kBodyFont,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? darkGold : goldText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ornamental divider ────────────────────────────────────────────────────────

/// A classic star-between-rules ornament used in Islamic manuscript typography.
class _OrnamentalDivider extends StatelessWidget {
  final bool isDark;

  const _OrnamentalDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final lineColor = gold.withAlpha(isDark ? 70 : 50);
    final starColor = gold.withAlpha(isDark ? 130 : 110);

    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: lineColor),
        ),
        const SizedBox(width: 12),
        Icon(Icons.star_outlined, size: 12, color: starColor),
        const SizedBox(width: 12),
        Expanded(
          child: Container(height: 1, color: lineColor),
        ),
      ],
    );
  }
}

// ── Disclaimer card ───────────────────────────────────────────────────────────

/// Gold-bordered card — identical in style to the About screen disclaimer (E-9).
class _DisclaimerCard extends StatelessWidget {
  final AppLocalizations l10n;
  final FThemeData theme;
  final bool isDark;

  const _DisclaimerCard({
    required this.l10n,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGold = isDark ? darkGold : gold;
    return Container(
      decoration: BoxDecoration(
        color: effectiveGold.withAlpha(isDark ? 18 : 12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: effectiveGold.withAlpha(150),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Free & ad-free line with info icon.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: isDark ? darkGold : goldDeep,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.welcome_free_disclaimer,
                  style: TextStyle(
                    fontFamily: kReadFont,
                    fontFamilyFallback: kFontFallback,
                    fontSize: 14,
                    color: theme.colors.foreground,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Report mistakes line — rendered as SelectableText so the email
          // address can be long-pressed and copied on both platforms.
          // Splits the localized string at the email so the address gets an
          // underline hint; the full paragraph remains selectable.
          _SelectableReportLine(l10n: l10n, theme: theme),
        ],
      ),
    );
  }
}

// ── Selectable report-mistakes line ──────────────────────────────────────────

/// Renders the report-mistakes paragraph as a [SelectableText.rich] so users
/// can long-press and copy the GitHub issues URL. The URL is underlined as a
/// visual affordance; no tap handler is added (avoids url_launcher dependency).
/// Wraps safely at 360 px because [SelectableText] obeys normal text wrapping.
class _SelectableReportLine extends StatelessWidget {
  final AppLocalizations l10n;
  final FThemeData theme;

  const _SelectableReportLine({required this.l10n, required this.theme});

  // GitHub issues URL — kept in sync with app_*.arb welcome_report_mistakes.
  static const _issuesUrl = 'https://github.com/nouhouari/sira-quiz/issues';

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontFamily: kReadFont,
      fontFamilyFallback: kFontFallback,
      fontSize: 14,
      color: theme.colors.foreground,
      height: 1.55,
    );

    // Split the localized string at the URL so we can style it.
    final full = l10n.welcome_report_mistakes;
    final idx = full.indexOf(_issuesUrl);
    if (idx < 0) {
      // Fallback: URL not found in translation — render as plain selectable text.
      return SelectableText(full, style: baseStyle);
    }

    final before = full.substring(0, idx);
    final after = full.substring(idx + _issuesUrl.length);

    return SelectableText.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: _issuesUrl,
            style: baseStyle.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: theme.colors.foreground.withAlpha(160),
            ),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
    );
  }
}

// ── Du'a block ────────────────────────────────────────────────────────────────

/// Closing invocation — floats above the button in a barely-there radial
/// gold glow, set in Amiri italic centered, like a manuscript colophon.
class _DuaBlock extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isDark;

  const _DuaBlock({required this.l10n, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            gold.withAlpha(isDark ? 22 : 14),
            Colors.transparent,
          ],
          radius: 1.2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      // WCAG AA: goldDeep (#A9842F) is ~3.8:1 on sandBg — fails AA for text.
      // goldText (#7A5E1A) is ~5.2:1 — passes AA. Dark mode uses darkGold.
      child: Text(
        l10n.welcome_dua,
        style: TextStyle(
          fontFamily: kDisplayFont,
          fontStyle: FontStyle.italic,
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: isDark ? darkGold : goldText,
          height: 1.7,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Begin button ──────────────────────────────────────────────────────────────

/// Full-width emerald primary button — matches the style of _EmeraldPrimaryButton
/// in home_screen.dart and _EmeraldNextButton in quiz_screen.dart.
class _BeginButton extends StatelessWidget {
  final String label;
  final bool isDark;

  const _BeginButton({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // H-2: darkEmeraldButton (#0F7A63) in dark mode gives white text ≥4.5:1.
    final bg = isDark ? darkEmeraldButton : emerald;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: IslamicPatternOverlay(
        patternColor: Colors.white,
        alpha: 12,
        cellSize: 18,
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
              label,
              style: const TextStyle(
                fontFamily: kBodyFont,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
