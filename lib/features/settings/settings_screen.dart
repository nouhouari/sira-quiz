import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/arb/app_localizations.dart';
import '../../data/repositories/quiz_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;

    final localeAsync = ref.watch(localeNotifierProvider);
    final themeModeAsync = ref.watch(themeModeNotifierProvider);
    final soundAsync = ref.watch(soundNotifierProvider);

    final currentLocale = localeAsync.valueOrNull ?? 'fr';
    final currentTheme = themeModeAsync.valueOrNull ?? 'system';
    final soundEnabled = soundAsync.valueOrNull ?? false;

    return FScaffold(
      header: FHeader.nested(
        title: Text(l10n.settings_title),
        prefixes: [
          FHeaderAction.back(onPress: () => context.pop()),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language
          _SectionLabel(label: l10n.settings_language, theme: theme),
          const SizedBox(height: 8),
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  _SettingsTile(
                    key: const Key('settings_lang_fr'),
                    title: l10n.settings_lang_fr,
                    trailing: currentLocale == 'fr'
                        ? Icon(Icons.check, color: theme.colors.primary)
                        : null,
                    onTap: () => ref
                        .read(localeNotifierProvider.notifier)
                        .setLocale('fr'),
                    theme: theme,
                  ),
                  Divider(height: 1, color: theme.colors.border),
                  _SettingsTile(
                    key: const Key('settings_lang_en'),
                    title: l10n.settings_lang_en,
                    trailing: currentLocale == 'en'
                        ? Icon(Icons.check, color: theme.colors.primary)
                        : null,
                    onTap: () => ref
                        .read(localeNotifierProvider.notifier)
                        .setLocale('en'),
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Theme
          _SectionLabel(label: l10n.settings_theme, theme: theme),
          const SizedBox(height: 8),
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  _SettingsTile(
                    title: l10n.settings_theme_light,
                    trailing: currentTheme == 'light'
                        ? Icon(Icons.check, color: theme.colors.primary)
                        : null,
                    onTap: () => ref
                        .read(themeModeNotifierProvider.notifier)
                        .setThemeMode('light'),
                    theme: theme,
                  ),
                  Divider(height: 1, color: theme.colors.border),
                  _SettingsTile(
                    title: l10n.settings_theme_dark,
                    trailing: currentTheme == 'dark'
                        ? Icon(Icons.check, color: theme.colors.primary)
                        : null,
                    onTap: () => ref
                        .read(themeModeNotifierProvider.notifier)
                        .setThemeMode('dark'),
                    theme: theme,
                  ),
                  Divider(height: 1, color: theme.colors.border),
                  _SettingsTile(
                    title: l10n.settings_theme_system,
                    trailing: currentTheme == 'system'
                        ? Icon(Icons.check, color: theme.colors.primary)
                        : null,
                    onTap: () => ref
                        .read(themeModeNotifierProvider.notifier)
                        .setThemeMode('system'),
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Haptic feedback
          _SectionLabel(label: l10n.settingsHaptic, theme: theme),
          const SizedBox(height: 8),
          FCard.raw(
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            style: theme.typography.md
                                .copyWith(color: theme.colors.foreground),
                          ),
                          Text(
                            l10n.settingsHapticDesc,
                            style: theme.typography.xs.copyWith(
                                color: theme.colors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: soundEnabled,
                      onChanged: (val) => ref
                          .read(soundNotifierProvider.notifier)
                          .setSoundEnabled(val),
                      activeThumbColor: theme.colors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final FThemeData theme;
  const _SectionLabel({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: theme.typography.xs.copyWith(
        color: theme.colors.mutedForeground,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.typography.md
                    .copyWith(color: theme.colors.foreground),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
