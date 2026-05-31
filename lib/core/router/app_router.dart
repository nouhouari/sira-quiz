import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/about/about_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/difficulty/difficulty_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/result/result_screen.dart';
import '../../features/settings/settings_screen.dart';

/// Gentle fade + upward slide — 220 ms, respects reduced-motion by checking
/// the animation controller duration at build time (Flutter skips animations
/// when AccessibilityFeatures.disableAnimations is true via platform channel).
Page<void> _fadeSlidePage(BuildContext context, GoRouterState state,
    Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Respect system reduced-motion flag.
      final reduceMotion =
          MediaQuery.of(context).disableAnimations;

      if (reduceMotion) return child;

      final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
        CurveTween(curve: Curves.easeInOut),
      );
      final slideTween =
          Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).chain(
        CurveTween(curve: Curves.easeOutCubic),
      );

      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: SlideTransition(
          position: animation.drive(slideTween),
          child: child,
        ),
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          _fadeSlidePage(context, state, const HomeScreen()),
    ),
    GoRoute(
      path: '/categories',
      pageBuilder: (context, state) =>
          _fadeSlidePage(context, state, const CategoriesScreen()),
    ),
    GoRoute(
      path: '/difficulty',
      pageBuilder: (context, state) {
        final cat = state.uri.queryParameters['cat'] ?? '';
        return _fadeSlidePage(
            context, state, DifficultyScreen(categorySlug: cat));
      },
    ),
    GoRoute(
      path: '/quiz',
      pageBuilder: (context, state) =>
          _fadeSlidePage(context, state, const QuizScreen()),
    ),
    GoRoute(
      path: '/result',
      pageBuilder: (context, state) =>
          _fadeSlidePage(context, state, const ResultScreen()),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) =>
          _fadeSlidePage(context, state, const SettingsScreen()),
    ),
    GoRoute(
      path: '/about',
      pageBuilder: (context, state) =>
          _fadeSlidePage(context, state, const AboutScreen()),
    ),
  ],
);
