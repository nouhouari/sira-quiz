import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/arb/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;

    return FScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Calligraphic / geometric header block
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: theme.colors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(44),
                        border: Border.all(
                          color: theme.colors.primary.withAlpha(60),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 48,
                        color: theme.colors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.home_title,
                      style: theme.typography.xl2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colors.foreground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.home_subtitle,
                      style: theme.typography.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Button group
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FButton(
                    key: const Key('home_start_btn'),
                    onPress: () => context.push('/categories'),
                    child: Text(l10n.home_start),
                  ),
                  const SizedBox(height: 12),
                  FButton(
                    key: const Key('home_settings_btn'),
                    variant: FButtonVariant.outline,
                    onPress: () => context.push('/settings'),
                    child: Text(l10n.home_settings),
                  ),
                  const SizedBox(height: 12),
                  FButton(
                    key: const Key('home_about_btn'),
                    variant: FButtonVariant.ghost,
                    onPress: () => context.push('/about'),
                    child: Text(l10n.home_about),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
