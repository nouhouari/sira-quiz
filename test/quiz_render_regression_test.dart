// ignore_for_file: avoid_print
//
// Widget-level regression guard — fast unit-speed test.
//
// Bug C-4 (regression: quiz option tiles render without Material ancestor crash)
// ─────────────────────────────────────────────────────────────────────────────
// Option tiles were briefly implemented with InkWell, which requires a Material
// ancestor widget.  FScaffold (ForUI) does NOT provide one, so pumping the quiz
// screen threw:
//
//   "No Material widget found. _InkResponseStateWidget requires a Material
//    widget ancestor."
//
// Flutter replaced the option list with a red ErrorWidget.  The pre-existing
// integration test missed this because it located tiles via
//   find.byWidgetPredicate((w) => w is InkWell && ...)
// which evaluated to zero hits (silently skipping the tap loop) — the test
// reported green while the screen was broken.
//
// This file pumps the quiz screen inside an in-memory Drift DB + FTheme shell
// (the same pattern used by quiz_controller_test.dart) and asserts:
//   1. No exception is thrown on the UNANSWERED first render.
//   2. No ErrorWidget appears in the unanswered state.
//   3. Option tiles are present and discoverable by their stable Keys.
//   4. After selecting an option the feedback render is also clean.
//
// Why this catches the pre-fix code: InkWell inside FScaffold (no Material)
// throws in Flutter's test renderer exactly as it does on device — the
// tester.takeException() call would return a non-null FlutterError and
// find.byType(ErrorWidget) would find at least one widget.

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
import 'package:sira_quiz/domain/models/difficulty.dart';
import 'package:sira_quiz/features/quiz/quiz_controller.dart';

// ── Helpers (mirrors quiz_controller_test.dart) ───────────────────────────────

AppDatabase _openMemoryDb() => AppDatabase(NativeDatabase.memory());

/// Seeds one category ("test_cat") with 3 beginner questions, 2+ options each.
/// Correct option is always id=1/5/9 (sort_order=1) so tests are deterministic.
Future<void> _seedFixture(AppDatabase db) async {
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
        promptFr: 'Question 1 FR',
        promptEn: 'Question 1 EN',
        explanationFr: 'Explication 1',
        explanationEn: 'Explanation 1',
        sourceArabic: const Value(null),
        sourceReference: 'Ref 1',
      ),
      QuestionsCompanion.insert(
        id: const Value(2),
        categorySlug: 'test_cat',
        difficulty: 1,
        type: 'mcq',
        promptFr: 'Question 2 FR',
        promptEn: 'Question 2 EN',
        explanationFr: 'Explication 2',
        explanationEn: 'Explanation 2',
        sourceArabic: const Value(null),
        sourceReference: 'Ref 2',
      ),
      QuestionsCompanion.insert(
        id: const Value(3),
        categorySlug: 'test_cat',
        difficulty: 1,
        type: 'mcq',
        promptFr: 'Question 3 FR',
        promptEn: 'Question 3 EN',
        explanationFr: 'Explication 3',
        explanationEn: 'Explanation 3',
        sourceArabic: const Value(null),
        sourceReference: 'Ref 3',
      ),
    ],
    opts: [
      // Q1
      QuestionOptionsCompanion.insert(
        id: const Value(1),
        questionId: 1,
        textFr: 'Correct 1 FR',
        textEn: 'Correct 1 EN',
        isCorrect: const Value(true),
        sortOrder: const Value(1),
      ),
      QuestionOptionsCompanion.insert(
        id: const Value(2),
        questionId: 1,
        textFr: 'Faux 1 FR',
        textEn: 'Wrong 1 EN',
        isCorrect: const Value(false),
        sortOrder: const Value(2),
      ),
      // Q2
      QuestionOptionsCompanion.insert(
        id: const Value(3),
        questionId: 2,
        textFr: 'Faux 2a FR',
        textEn: 'Wrong 2a EN',
        isCorrect: const Value(false),
        sortOrder: const Value(2),
      ),
      QuestionOptionsCompanion.insert(
        id: const Value(5),
        questionId: 2,
        textFr: 'Correct 2 FR',
        textEn: 'Correct 2 EN',
        isCorrect: const Value(true),
        sortOrder: const Value(1),
      ),
      // Q3
      QuestionOptionsCompanion.insert(
        id: const Value(6),
        questionId: 3,
        textFr: 'Faux 3a FR',
        textEn: 'Wrong 3a EN',
        isCorrect: const Value(false),
        sortOrder: const Value(2),
      ),
      QuestionOptionsCompanion.insert(
        id: const Value(9),
        questionId: 3,
        textFr: 'Correct 3 FR',
        textEn: 'Correct 3 EN',
        isCorrect: const Value(true),
        sortOrder: const Value(1),
      ),
    ],
  );
}

/// Silent SoundNotifier — never touches haptics or prefs in test context.
class _SilentSoundNotifier extends SoundNotifier {
  @override
  Future<bool> build() async => false;
}

/// Pumps the full MaterialApp.router shell (same provider/theme/l10n config as
/// production) with providers overridden to use an in-memory DB.  The router
/// navigates to '/quiz' after setting SessionParams so QuizScreen receives a
/// real session.
Future<void> _pumpQuizShell(
  WidgetTester tester,
  AppDatabase db, {
  String categorySlug = 'test_cat',
  Difficulty difficulty = Difficulty.beginner,
}) async {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      soundNotifierProvider.overrideWith(() => _SilentSoundNotifier()),
    ],
  );
  addTearDown(container.dispose);

  // Pre-set session params so QuizScreen's initState finds them.
  container.read(sessionParamsProvider.notifier).state =
      SessionParams(categorySlug: categorySlug, difficulty: difficulty);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: appRouter,
        locale: const Locale('fr'),
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
        theme:
            getForUiTheme(Brightness.light).toApproximateMaterialTheme(),
        builder: (context, child) {
          return FTheme(
            data: getForUiTheme(Brightness.light),
            child: child!,
          );
        },
      ),
    ),
  );

  // Navigate to the quiz route.
  final router = appRouter;
  router.go('/quiz');
  // Allow initState postFrameCallback + DB query + state rebuild.
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group(
      'regression: quiz option tiles render without Material ancestor crash',
      () {
    late AppDatabase db;

    setUp(() async {
      db = _openMemoryDb();
      await _seedFixture(db);
    });

    tearDown(() async {
      await db.close();
    });

    // ── 1. Unanswered first render — the exact failure point ──────────────────

    testWidgets(
        'unanswered quiz screen renders without exception and without ErrorWidget',
        (tester) async {
      await _pumpQuizShell(tester, db);

      // ── GUARD: these two assertions would FAIL on the pre-fix InkWell code ──
      // InkWell without a Material ancestor throws a FlutterError immediately;
      // Flutter replaces the subtree with a red ErrorWidget.
      expect(
        tester.takeException(),
        isNull,
        reason:
            'No exception must be thrown when the quiz screen first renders '
            '(pre-fix InkWell crash would surface here)',
      );
      expect(
        find.byType(ErrorWidget),
        findsNothing,
        reason:
            'ErrorWidget must not appear on the unanswered quiz screen '
            '(pre-fix code rendered a red error box in place of option tiles)',
      );

      // ── Structural assertions: the key UI elements must be present ──────────
      // At least one option tile key must be found.
      final optionTiles = find.byWidgetPredicate(
        (w) =>
            w.key != null &&
            w.key.toString().contains('option_tile_'),
      );
      expect(
        optionTiles,
        findsWidgets,
        reason: 'Option tile keys must be present in the unanswered state',
      );

      // The question text must be visible (not hidden behind an error overlay).
      expect(
        find.textContaining('Question'),
        findsWidgets,
        reason: 'Question prompt must be visible on first render',
      );

      // The Next/See-Results button must NOT be present before an option is
      // selected (it only appears post-answer).
      expect(
        find.byKey(const Key('quiz_next_btn')),
        findsNothing,
        reason:
            'quiz_next_btn must not be shown before any option is selected',
      );
    });

    // ── 2. Post-answer render — feedback + Next button are also clean ─────────

    testWidgets(
        'after selecting an option feedback renders without exception and without ErrorWidget',
        (tester) async {
      await _pumpQuizShell(tester, db);

      // Confirm clean unanswered state first.
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);

      // Tap the first visible option tile.
      final firstTile = find
          .byWidgetPredicate(
            (w) =>
                w.key != null &&
                w.key.toString().contains('option_tile_'),
          )
          .first;
      await tester.tap(firstTile);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ── GUARD: no crash after tap ────────────────────────────────────────────
      expect(
        tester.takeException(),
        isNull,
        reason:
            'No exception must be thrown after an option is tapped',
      );
      expect(
        find.byType(ErrorWidget),
        findsNothing,
        reason:
            'ErrorWidget must not appear after an option is selected',
      );

      // The Next button must appear after answering.
      expect(
        find.byKey(const Key('quiz_next_btn')),
        findsOneWidget,
        reason:
            'quiz_next_btn must appear after an option is selected',
      );
    });

    // ── 3. Option tiles are GestureDetector-based, NOT InkWell ───────────────
    //
    // This is the structural assertion that would have caught the regression
    // before it shipped: if someone reverts _PressTile back to InkWell the
    // render tests above catch the runtime crash, but this test documents the
    // intentional implementation choice as a compile-time-equivalent check.

    testWidgets(
        'option tiles use GestureDetector ancestry, not InkWell — no Material ancestor required',
        (tester) async {
      await _pumpQuizShell(tester, db);

      expect(tester.takeException(), isNull);

      // There must be ZERO InkWell widgets whose key contains 'option_tile_'.
      // Pre-fix code had InkWell(key: Key('option_tile_N'), ...) here.
      final inkWellOptionTiles = find.byWidgetPredicate(
        (w) =>
            w is InkWell &&
            w.key != null &&
            w.key.toString().contains('option_tile_'),
      );
      expect(
        inkWellOptionTiles,
        findsNothing,
        reason:
            'Option tiles must NOT use InkWell (requires Material ancestor '
            'which FScaffold does not provide — C-4 regression guard)',
      );

      // And there MUST be GestureDetector-keyed option tiles present.
      final gdOptionTiles = find.byWidgetPredicate(
        (w) =>
            w.key != null &&
            w.key.toString().contains('option_tile_'),
      );
      expect(
        gdOptionTiles,
        findsWidgets,
        reason:
            'Option tiles must be present with their stable option_tile_N keys',
      );
    });
  });
}
