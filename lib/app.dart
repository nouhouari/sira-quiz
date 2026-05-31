import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/l10n/arb/app_localizations.dart';
import 'data/repositories/quiz_repository.dart';

class SiraQuizApp extends ConsumerWidget {
  const SiraQuizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeNotifierProvider);
    final themeModeAsync = ref.watch(themeModeNotifierProvider);

    final languageCode = localeAsync.valueOrNull ?? 'fr';
    final themeModeStr = themeModeAsync.valueOrNull ?? 'system';

    final themeMode = switch (themeModeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      locale: Locale(languageCode),
      // NOTE: Arabic ('ar') and full RTL locale support are intentionally out of
      // scope for this version (FR + EN only). The local Directionality wrapper
      // on Arabic citation text in quiz_screen.dart is deliberate — it renders
      // the source text RTL without switching the app locale.
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        ...FLocalizations.supportedLocales,
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...FLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeMode,
      theme: getForUiTheme(Brightness.light).toApproximateMaterialTheme(),
      darkTheme: getForUiTheme(Brightness.dark).toApproximateMaterialTheme(),
      builder: (context, child) {
        // Determine resolved brightness
        final brightness =
            themeMode == ThemeMode.dark
            ? Brightness.dark
            : themeMode == ThemeMode.light
                ? Brightness.light
                : MediaQuery.platformBrightnessOf(context);

        final forUiTheme = getForUiTheme(brightness);

        return FTheme(
          data: forUiTheme,
          child: FToaster(
            child: FTooltipGroup(child: child!),
          ),
        );
      },
    );
  }
}
