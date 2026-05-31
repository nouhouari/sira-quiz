import 'package:go_router/go_router.dart';

import '../../features/about/about_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/difficulty/difficulty_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/result/result_screen.dart';
import '../../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/difficulty',
      builder: (context, state) {
        final cat = state.uri.queryParameters['cat'] ?? '';
        return DifficultyScreen(categorySlug: cat);
      },
    ),
    GoRoute(
      path: '/quiz',
      builder: (context, state) => const QuizScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) => const ResultScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutScreen(),
    ),
  ],
);
