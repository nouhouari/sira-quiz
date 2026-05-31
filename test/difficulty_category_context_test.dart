// Widget regression test — Difficulty screen shows selected category name.
//
// Feature guard: when the user navigates to the Difficulty screen after picking
// a category, the category's localized name must be visible above the three
// difficulty cards so the user knows which category they are choosing a
// difficulty for.
//
// This test seeds one category ("test_cat", nameFr "Catégorie Test"), navigates
// to /difficulty?cat=test_cat in French locale, and asserts the name is rendered
// with the Key 'difficulty_category_name'.
//
// Setup mirrors quiz_render_regression_test.dart (in-memory Drift + FTheme shell).

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:sira_quiz/core/l10n/arb/app_localizations.dart';
import 'package:sira_quiz/core/router/app_router.dart';
import 'package:sira_quiz/core/theme/app_theme.dart';
import 'package:sira_quiz/data/db/app_database.dart';
import 'package:sira_quiz/data/repositories/quiz_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

AppDatabase _openMemoryDb() => AppDatabase(NativeDatabase.memory());

/// Seeds one category and a minimal question so the difficulty cards load.
Future<void> _seedCategory(AppDatabase db) async {
  await db.seedAll(
    cats: [
      CategoriesCompanion.insert(
        slug: 'test_cat',
        iconKey: 'star',
        nameFr: 'Catégorie Test',
        nameEn: 'Test Category',
        sortOrder: const Value(1),
      ),
    ],
    qs: [
      QuestionsCompanion.insert(
        id: const Value(1),
        categorySlug: 'test_cat',
        difficulty: 1,
        type: 'mcq',
        promptFr: 'Q1 FR',
        promptEn: 'Q1 EN',
        explanationFr: 'Exp 1',
        explanationEn: 'Exp 1 EN',
        sourceArabic: const Value(null),
        sourceReference: 'Ref 1',
      ),
    ],
    opts: [
      QuestionOptionsCompanion.insert(
        id: const Value(1),
        questionId: 1,
        textFr: 'Opt FR',
        textEn: 'Opt EN',
        isCorrect: const Value(true),
        sortOrder: const Value(1),
      ),
      QuestionOptionsCompanion.insert(
        id: const Value(2),
        questionId: 1,
        textFr: 'Opt2 FR',
        textEn: 'Opt2 EN',
        isCorrect: const Value(false),
        sortOrder: const Value(2),
      ),
    ],
  );
}

/// Pumps the full app shell and navigates to the Difficulty screen for
/// the given [categorySlug].
Future<void> _pumpDifficultyShell(
  WidgetTester tester,
  AppDatabase db, {
  String categorySlug = 'test_cat',
  String locale = 'fr',
}) async {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: appRouter,
        locale: Locale(locale),
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
        theme: getForUiTheme(Brightness.light).toApproximateMaterialTheme(),
        builder: (context, child) => FTheme(
          data: getForUiTheme(Brightness.light),
          child: child!,
        ),
      ),
    ),
  );

  // Navigate directly to the difficulty route for the seeded category.
  appRouter.go('/difficulty?cat=$categorySlug');
  // Allow FutureProvider DB queries + widget rebuild.
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('DifficultyScreen category context block', () {
    late AppDatabase db;

    setUp(() async {
      db = _openMemoryDb();
      await _seedCategory(db);
    });

    tearDown(() async => db.close());

    testWidgets(
        'shows the category localized name (FR) above the difficulty cards',
        (tester) async {
      await _pumpDifficultyShell(tester, db, locale: 'fr');

      // No crash on render.
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);

      // The category name widget must be present via its stable Key.
      expect(
        find.byKey(const Key('difficulty_category_name')),
        findsOneWidget,
        reason:
            'difficulty_category_name widget must be rendered for a known slug',
      );

      // The actual localized name text (FR) must appear on screen.
      expect(
        find.text('Catégorie Test'),
        findsOneWidget,
        reason:
            'The French category name must be visible on the Difficulty screen',
      );

      // The three difficulty cards must still be present.
      expect(
        find.byKey(const Key('difficulty_card_beginner')),
        findsOneWidget,
        reason: 'Difficulty cards must still render alongside the context block',
      );
    });

    testWidgets(
        'shows the category localized name (EN) when locale is English',
        (tester) async {
      await _pumpDifficultyShell(tester, db, locale: 'en');

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);

      expect(
        find.text('Test Category'),
        findsOneWidget,
        reason:
            'The English category name must be visible when locale is "en"',
      );
    });

    testWidgets(
        'renders cleanly for an unknown slug — no category block, no crash',
        (tester) async {
      await _pumpDifficultyShell(
        tester,
        db,
        categorySlug: 'unknown_slug',
        locale: 'fr',
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);

      // Context block must be absent for an unknown slug.
      expect(
        find.byKey(const Key('difficulty_category_name')),
        findsNothing,
        reason:
            'Category block must be omitted when the slug is not found — '
            'no crash, no widget',
      );
    });
  });
}
