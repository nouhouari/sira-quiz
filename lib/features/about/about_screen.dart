import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/arb/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;

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
          // App info
          FCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.about_app_name,
                    style: theme.typography.xl.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.about_description,
                    style: theme.typography.sm.copyWith(
                        color: theme.colors.foreground),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.about_version('1.0.0'),
                    style: theme.typography.xs.copyWith(
                        color: theme.colors.mutedForeground),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sources
          _SectionCard(
            title: l10n.about_sources_title,
            theme: theme,
            children: [
              l10n.about_source_quran,
              l10n.about_source_bukhari,
              l10n.about_source_muslim,
              l10n.about_source_ibn_hisham,
            ]
                .map(
                  (s) => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ',
                            style: theme.typography.sm.copyWith(
                                color: theme.colors.foreground)),
                        Expanded(
                          child: Text(
                            s,
                            style: theme.typography.sm.copyWith(
                                color: theme.colors.foreground),
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
          _SectionCard(
            title: l10n.about_methodology_title,
            theme: theme,
            children: [
              Text(
                l10n.about_methodology_text,
                style: theme.typography.sm
                    .copyWith(color: theme.colors.foreground),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Disclaimer
          Container(
            decoration: BoxDecoration(
              color: theme.colors.destructive.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: theme.colors.destructive.withAlpha(60), width: 1),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: theme.colors.destructive, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      l10n.about_disclaimer_title,
                      style: theme.typography.md.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colors.destructive,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.about_disclaimer_text,
                  style: theme.typography.sm
                      .copyWith(color: theme.colors.foreground),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final FThemeData theme;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.theme,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.typography.md.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
