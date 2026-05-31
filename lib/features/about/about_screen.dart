import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/arb/app_localizations.dart';
import '../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;
    final isDark = theme.colors.background.computeLuminance() < 0.2;

    return FScaffold(
      header: FHeader.nested(
        title: Text(l10n.about_title),
        prefixes: [
          FHeaderAction.back(onPress: () => context.pop()),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App info card
          _AboutCard(
            theme: theme,
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.about_app_name,
                  style: TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.about_description,
                  // E-2: Crimson Pro for About body paragraphs.
                  style: TextStyle(
                    fontFamily: kReadFont,
                    fontSize: 15,
                    color: theme.colors.foreground,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.about_version('1.0.0'),
                  style: TextStyle(
                    fontFamily: kBodyFont,
                    fontSize: 11,
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sources
          _AboutSectionCard(
            title: l10n.about_sources_title,
            theme: theme,
            isDark: isDark,
            children: [
              l10n.about_source_quran,
              l10n.about_source_bukhari,
              l10n.about_source_muslim,
              l10n.about_source_ibn_hisham,
            ]
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            fontFamily: kBodyFont,
                            fontSize: 13,
                            color: isDark ? darkGold : goldDeep,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            s,
                            style: TextStyle(
                              fontFamily: kBodyFont,
                              fontSize: 13,
                              color: theme.colors.foreground,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),

          // Methodology
          _AboutSectionCard(
            title: l10n.about_methodology_title,
            theme: theme,
            isDark: isDark,
            children: [
              Text(
                l10n.about_methodology_text,
                // E-2: Crimson Pro for reading content.
                style: TextStyle(
                  fontFamily: kReadFont,
                  fontSize: 15,
                  color: theme.colors.foreground,
                  height: 1.55,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // E-9: Disclaimer — gold-bordered "important note" card (scholarly,
          // not danger). Gold on inkSoft background is ≥4.5:1 for title text.
          Container(
            decoration: BoxDecoration(
              color: (isDark ? darkGold : gold).withAlpha(isDark ? 18 : 12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (isDark ? darkGold : gold).withAlpha(150),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: isDark ? darkGold : goldDeep,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.about_disclaimer_title,
                        style: TextStyle(
                          fontFamily: kBodyFont,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          // goldDeep on sandBg = ~3.8:1 (passes AA large text).
                          // inkSoft on sandBg = ~4.8:1 (passes AA normal text).
                          // Use ink/darkText for AA compliance on disclaimer title.
                          color: theme.colors.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.about_disclaimer_text,
                  // E-2: Crimson Pro for disclaimer body text.
                  style: TextStyle(
                    fontFamily: kReadFont,
                    fontSize: 14,
                    color: theme.colors.foreground,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final FThemeData theme;
  final bool isDark;
  final Widget child;

  const _AboutCard({
    required this.theme,
    required this.isDark,
    required this.child,
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
            color: Colors.black.withAlpha(isDark ? 35 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class _AboutSectionCard extends StatelessWidget {
  final String title;
  final FThemeData theme;
  final bool isDark;
  final List<Widget> children;

  const _AboutSectionCard({
    required this.title,
    required this.theme,
    required this.isDark,
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
            color: Colors.black.withAlpha(isDark ? 35 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: kDisplayFont,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
