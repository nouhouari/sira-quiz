import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/islamic_pattern_painter.dart';
import '../../data/repositories/quiz_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;
    final isDark = theme.colors.background.computeLuminance() < 0.2;

    final localeAsync = ref.watch(localeNotifierProvider);
    final themeModeAsync = ref.watch(themeModeNotifierProvider);
    final soundAsync = ref.watch(soundNotifierProvider);

    final currentLocale = localeAsync.valueOrNull ?? 'fr';
    final currentTheme = themeModeAsync.valueOrNull ?? 'system';
    final soundEnabled = soundAsync.valueOrNull ?? false;

    final activeEmerald = isDark ? darkEmerald : emerald;

    return FScaffold(
      header: FHeader.nested(
        title: Text(l10n.settings_title),
        prefixes: [
          FHeaderAction.back(onPress: () => context.pop()),
        ],
      ),
      // E-1: gold khatam motif at alpha 8, cellSize 44 behind settings content.
      child: IslamicPatternOverlay(
        patternColor: gold,
        alpha: 8,
        cellSize: 44,
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language section
          _SectionLabel(label: l10n.settings_language, isDark: isDark),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            theme: theme,
            children: [
              _SettingsTile(
                key: const Key('settings_lang_fr'),
                title: l10n.settings_lang_fr,
                trailing: currentLocale == 'fr'
                    ? Icon(Icons.check, color: activeEmerald, size: 18)
                    : null,
                onTap: () =>
                    ref.read(localeNotifierProvider.notifier).setLocale('fr'),
                theme: theme,
              ),
              _Divider(theme: theme),
              _SettingsTile(
                key: const Key('settings_lang_en'),
                title: l10n.settings_lang_en,
                trailing: currentLocale == 'en'
                    ? Icon(Icons.check, color: activeEmerald, size: 18)
                    : null,
                onTap: () =>
                    ref.read(localeNotifierProvider.notifier).setLocale('en'),
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Theme section
          _SectionLabel(label: l10n.settings_theme, isDark: isDark),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            theme: theme,
            children: [
              _SettingsTile(
                title: l10n.settings_theme_light,
                trailing: currentTheme == 'light'
                    ? Icon(Icons.check, color: activeEmerald, size: 18)
                    : null,
                onTap: () => ref
                    .read(themeModeNotifierProvider.notifier)
                    .setThemeMode('light'),
                theme: theme,
              ),
              _Divider(theme: theme),
              _SettingsTile(
                title: l10n.settings_theme_dark,
                trailing: currentTheme == 'dark'
                    ? Icon(Icons.check, color: activeEmerald, size: 18)
                    : null,
                onTap: () => ref
                    .read(themeModeNotifierProvider.notifier)
                    .setThemeMode('dark'),
                theme: theme,
              ),
              _Divider(theme: theme),
              _SettingsTile(
                title: l10n.settings_theme_system,
                trailing: currentTheme == 'system'
                    ? Icon(Icons.check, color: activeEmerald, size: 18)
                    : null,
                onTap: () => ref
                    .read(themeModeNotifierProvider.notifier)
                    .setThemeMode('system'),
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Haptic feedback section
          _SectionLabel(label: l10n.settingsHaptic, isDark: isDark),
          const SizedBox(height: 8),
          _SettingsCard(
            isDark: isDark,
            theme: theme,
            children: [
              Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.settingsHaptic,
                              style: TextStyle(
                                fontFamily: kBodyFont,
                                fontSize: 15,
                                color: theme.colors.foreground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.settingsHapticDesc,
                              style: TextStyle(
                                fontFamily: kBodyFont,
                                fontSize: 12,
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // E-5: clear ON/OFF distinction with padded tap target.
                      // OFF = #B0B0B0 track + white thumb.
                      // ON  = solid emerald #0B6B57 (dark: darkEmerald) + white thumb.
                      // materialTapTargetSize.padded ensures ≥44px touch target.
                      Switch(
                        value: soundEnabled,
                        onChanged: (val) => ref
                            .read(soundNotifierProvider.notifier)
                            .setSoundEnabled(val),
                        // Thumb is always white.
                        activeThumbColor: Colors.white,
                        inactiveThumbColor: Colors.white,
                        // Active track: solid emerald #0B6B57 (or darkEmerald in dark).
                        activeTrackColor: isDark ? darkEmerald : emerald,
                        // Inactive track: #B0B0B0 so OFF state is clearly visible.
                        inactiveTrackColor: const Color(0xFFB0B0B0),
                        trackOutlineColor:
                            WidgetStateProperty.all(Colors.transparent),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

// ── Shared settings components ────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // L-5: section labels were too faint (mutedForeground). Use inkSoft in
    // light mode and a brighter muted in dark mode so they anchor sections.
    final labelColor = isDark
        ? const Color(0xFF9AB5A8)
        : inkSoft;
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: kBodyFont,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: labelColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        // E-8: use emerald tint (not gold) for section hairlines — reserve
        // gold for the four "precious" spots (icon ring, score arc, header, motif).
        Expanded(
          child: Container(
            height: 1,
            color: (isDark ? darkEmerald : emerald).withAlpha(40),
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final FThemeData theme;
  final List<Widget> children;

  const _SettingsCard({
    required this.isDark,
    required this.theme,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final FThemeData theme;
  const _Divider({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.colors.border.withAlpha(120),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;
  final FThemeData theme;

  const _SettingsTile({
    super.key,
    required this.title,
    required this.trailing,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: kBodyFont,
                  fontSize: 15,
                  color: theme.colors.foreground,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
