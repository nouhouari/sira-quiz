import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

// ── Light palette ─────────────────────────────────────────────────────────────

/// Brand primary emerald green.
const emerald = Color(0xFF0B6B57);

/// Darker shade of emerald (pressed states, headers).
const emeraldDark = Color(0xFF084D3F);

/// Lighter emerald (hover, accents).
const emeraldLight = Color(0xFF12876E);

/// Gold accent — hairlines, rings, small highlights.
const gold = Color(0xFFC8A24A);

/// Deep gold for pressed/active gold elements.
const goldDeep = Color(0xFFA9842F);

/// Warm off-white application background.
const sandBg = Color(0xFFF7F4EC);

/// Card surface (white).
const surfaceWhite = Color(0xFFFFFFFF);

/// Warm border color.
const warmBorder = Color(0xFFE7E0D0);

/// Primary text.
const ink = Color(0xFF15231E);

/// Secondary / muted text.
const inkSoft = Color(0xFF5C6B64);

/// Correct answer green (aligned to emerald family).
const successGreen = Color(0xFF0B6B57);

/// Incorrect answer red.
const errorRed = Color(0xFFB3261E);

// ── Dark palette ──────────────────────────────────────────────────────────────

const darkBg = Color(0xFF0D1714);

/// Deeper dark background used for the lower/surface panel so the emerald
/// header reads as a distinct hero zone (L-6).
const darkBgDeep = Color(0xFF101814);

const darkSurface = Color(0xFF14211C);
const darkBorder = Color(0xFF24332C);
const darkText = Color(0xFFEAF2EE);

/// Standard dark-mode emerald accent (~2BA98A — used on borders, icons, text).
const darkEmerald = Color(0xFF2BA98A);

/// Deeper dark-mode emerald used for filled button surfaces so white text
/// achieves ≥4.5:1 contrast (H-2). #0F7A63 → white = ~4.7:1.
const darkEmeraldButton = Color(0xFF0F7A63);

const darkGold = Color(0xFFD8B65C);

// ── Legacy aliases kept for backward compatibility ────────────────────────────

/// Sand/warm neutral for card backgrounds in light mode.
const sandLight = Color(0xFFF7F4EC);

// ── Typography helpers ────────────────────────────────────────────────────────

/// The display/heading font family (Amiri — bundled OFL).
const kDisplayFont = 'Amiri';

/// The body/UI font family (Inter — bundled OFL).
const kBodyFont = 'Inter';

/// The reading/body-text font family (Crimson Pro — bundled OFL).
/// Apply to: quiz question text, feedback explanation, result review prompt,
/// About body paragraphs. Keep Inter for UI chrome (labels, buttons, headers).
const kReadFont = 'CrimsonPro';

// ── ForUI theme builder ───────────────────────────────────────────────────────

/// Returns the custom Emerald & Gold ForUI theme for the given brightness.
FThemeData getForUiTheme(Brightness brightness) {
  final isMobile = const {
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.fuchsia,
  }.contains(defaultTargetPlatform);

  if (brightness == Brightness.dark) {
    return _buildTheme(
      brightness: Brightness.dark,
      touch: isMobile,
      // Use the deeper shade so the lower panel is distinct from the emerald
      // header (L-6). Cards still use darkSurface (#14211C) for separation.
      background: darkBgDeep,
      foreground: darkText,
      card: darkSurface,
      // Filled buttons use darkEmeraldButton for ≥4.5:1 white-text contrast (H-2).
      primary: darkEmeraldButton,
      primaryForeground: Colors.white,
      secondary: darkEmerald.withAlpha(30),
      secondaryForeground: darkEmerald,
      muted: darkSurface,
      mutedForeground: const Color(0xFF7A9B8E),
      border: darkBorder,
      destructive: const Color(0xFFCF6679),
      destructiveForeground: darkBg,
    );
  }

  return _buildTheme(
    brightness: Brightness.light,
    touch: isMobile,
    background: sandBg,
    foreground: ink,
    card: surfaceWhite,
    primary: emerald,
    primaryForeground: surfaceWhite,
    secondary: emerald.withAlpha(18),
    secondaryForeground: emerald,
    muted: sandBg,
    mutedForeground: inkSoft,
    border: warmBorder,
    destructive: errorRed,
    destructiveForeground: surfaceWhite,
  );
}

FThemeData _buildTheme({
  required Brightness brightness,
  required bool touch,
  required Color background,
  required Color foreground,
  required Color card,
  required Color primary,
  required Color primaryForeground,
  required Color secondary,
  required Color secondaryForeground,
  required Color muted,
  required Color mutedForeground,
  required Color border,
  required Color destructive,
  required Color destructiveForeground,
}) {
  // Build the colour scheme from the base neutral theme (preserves all
  // secondary fields — barrier, systemOverlayStyle, etc.) and patches our tokens.
  final baseColors = brightness == Brightness.light
      ? FThemes.neutral.light.touch.colors
      : FThemes.neutral.dark.touch.colors;

  final colors = baseColors.copyWith(
    background: background,
    foreground: foreground,
    card: card,
    primary: primary,
    primaryForeground: primaryForeground,
    secondary: secondary,
    secondaryForeground: secondaryForeground,
    muted: muted,
    mutedForeground: mutedForeground,
    border: border,
    destructive: destructive,
    destructiveForeground: destructiveForeground,
  );

  // Build custom typography.
  final typography = _buildTypography(
    FTypography.inherit(colors: colors, touch: touch),
    brightness,
  );

  return FThemeData(
    colors: colors,
    touch: touch,
    typography: typography,
  );
}

/// Applies Inter (body) and Amiri (display) to the ForUI typography scale.
FTypography _buildTypography(FTypography base, Brightness brightness) {
  final textColor = brightness == Brightness.light ? ink : darkText;
  final mutedColor =
      brightness == Brightness.light ? inkSoft : const Color(0xFF7A9B8E);

  // Body styles — Inter, comfortable line-height.
  TextStyle body(TextStyle s) => s.copyWith(
        fontFamily: kBodyFont,
        color: textColor,
        height: 1.45,
      );

  // Display styles — Amiri, slightly tighter letter-spacing.
  TextStyle display(TextStyle s) => s.copyWith(
        fontFamily: kDisplayFont,
        color: textColor,
        letterSpacing: -0.3,
        height: 1.2,
      );

  return base.copyWith(
    xs3: body(base.xs3).copyWith(color: mutedColor),
    xs2: body(base.xs2).copyWith(color: mutedColor),
    xs: body(base.xs).copyWith(color: mutedColor),
    sm: body(base.sm),
    md: body(base.md),
    lg: display(base.lg).copyWith(fontWeight: FontWeight.w600),
    xl: display(base.xl).copyWith(fontWeight: FontWeight.w600),
    xl2: display(base.xl2).copyWith(fontWeight: FontWeight.bold),
    xl3: display(base.xl3).copyWith(fontWeight: FontWeight.bold),
    xl4: display(base.xl4).copyWith(fontWeight: FontWeight.bold),
    xl5: display(base.xl5).copyWith(fontWeight: FontWeight.bold),
  );
}
