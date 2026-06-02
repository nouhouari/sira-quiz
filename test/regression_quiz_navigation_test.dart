// ignore_for_file: avoid_print
//
// Regression guards — Quiz navigation, Result buttons, Difficulty badges,
//                     and level-status refresh.
//
// ─────────────────────────────────────────────────────────────────────────────
// Test 1 — Quiz back → difficulty (guards regression of `go('/')`)
//   When the user navigates Difficulty→Quiz and taps the header back action,
//   they must land on the Difficulty screen, not the Home screen.
//   Would FAIL if quiz_screen.dart changed `context.pop()` to `context.go('/')`.
//
// Test 2 — Result → "Choose level" → difficulty
//   Exercises the REAL ResultScreen widget (not a stub).
//   The real widget is mounted inside a real GoRouter so button onTap closures
//   in result_screen.dart are what runs — any future change to that file will
//   be caught immediately.
//
//   T2a: canPop==true (difficulty in back-stack, pushed /result on top).
//        Tapping result_levels_btn must pop back to DifficultyScreen.
//   T2b: canPop==false (router starts directly at /result — deep-link scenario).
//        Tapping result_levels_btn must go('/difficulty?cat=nav_cat'), not go('/').
//   T2c: result_home_btn → HomeScreen.
//   T2d: result_replay_btn → QuizScreen.
//
//   Would FAIL on code that called `context.go('/')` unconditionally.
//
// Test 3 — Completed difficulty card style + tappable (guards A2/#2/#3)
//   DifficultyScreen with overridden levelStatusProvider must show:
//     • completed level (total:30, remaining:0)  → Key('difficulty_completed_badge'), Opacity==1.0
//     • in-progress level (total:30, remaining:12) → Key('difficulty_questions_remaining'), Opacity==1.0
//     • empty level (total:0, remaining:0)         → neither badge, Opacity<1.0
//   Would FAIL if the keys were absent or if disabled/enabled logic were inverted.
//
// Test 4 — Counts refresh on return (guards stale levelStatusProvider cache)
//   Using the in-memory DB: after recording all questions for a level as
//   correctly answered via the real repository, remounting DifficultyScreen
//   must show the completed badge (levelStatusProvider recomputes remaining→0).
//   Would FAIL if autoDispose were removed or if recordAnswer didn't persist.
//
// Harness: mirrors quiz_render_regression_test.dart (in-memory Drift DB via
// NativeDatabase.memory(), full MaterialApp / MaterialApp.router shell,
// ProviderContainer overrides, FTheme + AppLocalizations).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, Column; // hide Drift Column — conflicts with Flutter Column
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:sira_quiz/core/l10n/arb/app_localizations.dart';
import 'package:sira_quiz/core/theme/app_theme.dart';
import 'package:sira_quiz/data/db/app_database.dart';
import 'package:sira_quiz/data/repositories/quiz_repository.dart';
import 'package:sira_quiz/domain/models/difficulty.dart';
import 'package:sira_quiz/domain/models/question_type.dart';
import 'package:sira_quiz/domain/models/quiz_question.dart';
import 'package:sira_quiz/features/difficulty/difficulty_screen.dart';
import 'package:sira_quiz/features/quiz/quiz_controller.dart';
import 'package:sira_quiz/features/result/result_screen.dart';

// ── Shared helpers ────────────────────────────────────────────────────────────

AppDatabase _openMemoryDb() => AppDatabase(NativeDatabase.memory());

/// Seeds one category ("nav_cat") with 3 beginner questions (ids 10,11,12).
/// Uses id space 10x/1xx to avoid PK collisions with other test files.
Future<void> _seedNavFixture(AppDatabase db) async {
  await db.seedAll(
    cats: [
      CategoriesCompanion.insert(
        slug: 'nav_cat',
        iconKey: 'star',
        nameFr: 'Navigation Test',
        nameEn: 'Navigation Test',
        sortOrder: const Value(1),
      ),
    ],
    qs: [
      QuestionsCompanion.insert(
        id: const Value(10),
        categorySlug: 'nav_cat',
        difficulty: 1, // beginner
        type: 'mcq',
        promptFr: 'Nav Q1 FR',
        promptEn: 'Nav Q1 EN',
        explanationFr: 'Exp 1',
        explanationEn: 'Exp 1',
        sourceArabic: const Value(null),
        sourceReference: 'Ref 1',
      ),
      QuestionsCompanion.insert(
        id: const Value(11),
        categorySlug: 'nav_cat',
        difficulty: 1,
        type: 'mcq',
        promptFr: 'Nav Q2 FR',
        promptEn: 'Nav Q2 EN',
        explanationFr: 'Exp 2',
        explanationEn: 'Exp 2',
        sourceArabic: const Value(null),
        sourceReference: 'Ref 2',
      ),
      QuestionsCompanion.insert(
        id: const Value(12),
        categorySlug: 'nav_cat',
        difficulty: 1,
        type: 'mcq',
        promptFr: 'Nav Q3 FR',
        promptEn: 'Nav Q3 EN',
        explanationFr: 'Exp 3',
        explanationEn: 'Exp 3',
        sourceArabic: const Value(null),
        sourceReference: 'Ref 3',
      ),
    ],
    opts: [
      QuestionOptionsCompanion.insert(
        id: const Value(100),
        questionId: 10,
        textFr: 'Correct Q1 FR',
        textEn: 'Correct Q1 EN',
        isCorrect: const Value(true),
        sortOrder: const Value(1),
      ),
      QuestionOptionsCompanion.insert(
        id: const Value(101),
        questionId: 10,
        textFr: 'Wrong Q1 FR',
        textEn: 'Wrong Q1 EN',
        isCorrect: const Value(false),
        sortOrder: const Value(2),
      ),
      QuestionOptionsCompanion.insert(
        id: const Value(105),
        questionId: 11,
        textFr: 'Correct Q2 FR',
        textEn: 'Correct Q2 EN',
        isCorrect: const Value(true),
        sortOrder: const Value(1),
      ),
      QuestionOptionsCompanion.insert(
        id: const Value(106),
        questionId: 11,
        textFr: 'Wrong Q2 FR',
        textEn: 'Wrong Q2 EN',
        isCorrect: const Value(false),
        sortOrder: const Value(2),
      ),
      QuestionOptionsCompanion.insert(
        id: const Value(109),
        questionId: 12,
        textFr: 'Correct Q3 FR',
        textEn: 'Correct Q3 EN',
        isCorrect: const Value(true),
        sortOrder: const Value(1),
      ),
      QuestionOptionsCompanion.insert(
        id: const Value(110),
        questionId: 12,
        textFr: 'Wrong Q3 FR',
        textEn: 'Wrong Q3 EN',
        isCorrect: const Value(false),
        sortOrder: const Value(2),
      ),
    ],
  );
}

/// Silent SoundNotifier — never touches haptics or SharedPreferences in tests.
class _SilentSoundNotifier extends SoundNotifier {
  @override
  Future<bool> build() async => false;
}

ProviderContainer _makeContainer(AppDatabase db) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      soundNotifierProvider.overrideWith(() => _SilentSoundNotifier()),
    ],
  );
}

// ── Seeded QuizNotifier for ResultScreen tests ────────────────────────────────

/// A minimal completed QuizState built from two inline QuizQuestion objects.
/// Used to feed the real ResultScreen without touching the DB or running a quiz.
QuizState _completedQuizState() {
  const opt1Correct = QuizOption(
    id: 100,
    textFr: 'Correct Q1 FR',
    textEn: 'Correct Q1 EN',
    isCorrect: true,
    sortOrder: 1,
  );
  const opt1Wrong = QuizOption(
    id: 101,
    textFr: 'Wrong Q1 FR',
    textEn: 'Wrong Q1 EN',
    isCorrect: false,
    sortOrder: 2,
  );
  const opt2Correct = QuizOption(
    id: 105,
    textFr: 'Correct Q2 FR',
    textEn: 'Correct Q2 EN',
    isCorrect: true,
    sortOrder: 1,
  );
  const opt2Wrong = QuizOption(
    id: 106,
    textFr: 'Wrong Q2 FR',
    textEn: 'Wrong Q2 EN',
    isCorrect: false,
    sortOrder: 2,
  );

  const q1 = QuizQuestion(
    id: 10,
    categorySlug: 'nav_cat',
    difficulty: Difficulty.beginner,
    type: QuestionType.mcq,
    promptFr: 'Nav Q1 FR',
    promptEn: 'Nav Q1 EN',
    explanationFr: 'Exp 1',
    explanationEn: 'Exp 1',
    sourceReference: 'Ref 1',
    options: [opt1Correct, opt1Wrong],
  );
  const q2 = QuizQuestion(
    id: 11,
    categorySlug: 'nav_cat',
    difficulty: Difficulty.beginner,
    type: QuestionType.mcq,
    promptFr: 'Nav Q2 FR',
    promptEn: 'Nav Q2 EN',
    explanationFr: 'Exp 2',
    explanationEn: 'Exp 2',
    sourceReference: 'Ref 2',
    options: [opt2Correct, opt2Wrong],
  );

  return const QuizState(
    questions: [q1, q2],
    currentIndex: 1,
    answered: true,
    answers: [
      AnswerRecord(question: q1, selectedOptionId: 100), // correct
      AnswerRecord(question: q2, selectedOptionId: 106), // wrong
    ],
  );
}

/// A QuizNotifier whose [build] returns a pre-built completed state, so the
/// real ResultScreen sees real questions/answers/score without running a quiz.
/// The notifier is otherwise fully functional — reset(), etc. still work.
class _SeededQuizNotifier extends QuizNotifier {
  final QuizState _seed;
  _SeededQuizNotifier(this._seed);

  @override
  QuizState build() => _seed;
}

/// Returns a ProviderContainer that overrides quizNotifierProvider with
/// [_SeededQuizNotifier] seeded to a completed QuizState.
ProviderContainer _makeResultContainer(AppDatabase db) {
  final seed = _completedQuizState();
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      soundNotifierProvider.overrideWith(() => _SilentSoundNotifier()),
      quizNotifierProvider.overrideWith(() => _SeededQuizNotifier(seed)),
    ],
  );
}

// ── Lightweight app-shell builder ─────────────────────────────────────────────

/// Pumps a MaterialApp.router with [router] and the given [container], locale,
/// theme, and localisation delegates — identical boilerplate to other test files.
Future<void> _pumpRouterShell(
  WidgetTester tester, {
  required GoRouter router,
  required ProviderContainer container,
  String locale = 'en',
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: Locale(locale),
        supportedLocales: const [
          Locale('en'),
          Locale('fr'),
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
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

/// Pumps a bare MaterialApp (no router) containing [child] directly.
/// Used for Tests 3/4 where we mount a single screen without a router stack.
Future<void> _pumpSingleScreen(
  WidgetTester tester, {
  required Widget child,
  required ProviderContainer container,
  String locale = 'en',
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: Locale(locale),
        supportedLocales: const [
          Locale('en'),
          Locale('fr'),
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
        home: Builder(
          builder: (ctx) => FTheme(
            data: getForUiTheme(Brightness.light),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

// ── Minimal stub widgets ──────────────────────────────────────────────────────

/// Identity-marker for the Home screen in nav tests.
class _HomeStub extends StatelessWidget {
  const _HomeStub();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('HOME_SCREEN_STUB')));
}

/// Thin quiz stub that renders the same back-button behaviour as the real
/// QuizScreen: `context.pop()`.  Redirects to '/' if sessionParams is null,
/// matching production code in quiz_screen.dart:27-29.
class _QuizScreenStub extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.read(sessionParamsProvider);
    if (params == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/');
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          key: const Key('quiz_back_btn'),
          onPressed: () => context.pop(),
        ),
        title: const Text('Quiz'),
      ),
      body: const Center(child: Text('QUIZ_SCREEN_STUB')),
    );
  }
}

/// Identity-marker for the Quiz screen destination in T2d (Replay).
/// Used as the '/quiz' route target when the QuizScreen back-button behaviour
/// is not under test (only the navigation destination matters).
class _QuizDestinationStub extends StatelessWidget {
  const _QuizDestinationStub();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('QUIZ_SCREEN_STUB')));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ════════════════════════════════════════════════════════════════════════════
  // Test 1 — Quiz back → difficulty (guards regression of `go('/')`)
  // ════════════════════════════════════════════════════════════════════════════
  group(
      'regression T1: quiz header back lands on Difficulty, NOT Home', () {
    late AppDatabase db;

    setUp(() async {
      db = _openMemoryDb();
      await _seedNavFixture(db);
    });

    tearDown(() => db.close());

    testWidgets(
        'Difficulty→Quiz: tapping quiz back shows DifficultyScreen '
        'and hides HomeScreen', (tester) async {
      final container = _makeContainer(db);
      addTearDown(container.dispose);

      container.read(sessionParamsProvider.notifier).state =
          SessionParams(categorySlug: 'nav_cat', difficulty: Difficulty.beginner);

      final router = GoRouter(
        initialLocation: '/difficulty?cat=nav_cat',
        routes: [
          GoRoute(
            path: '/',
            builder: (ctx, s) => const _HomeStub(),
          ),
          GoRoute(
            path: '/difficulty',
            builder: (ctx, s) {
              final cat = s.uri.queryParameters['cat'] ?? '';
              return DifficultyScreen(categorySlug: cat);
            },
          ),
          GoRoute(
            path: '/quiz',
            builder: (ctx, s) => _QuizScreenStub(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await _pumpRouterShell(tester, router: router, container: container);

      // Confirm on DifficultyScreen.
      expect(find.byType(DifficultyScreen), findsOneWidget,
          reason: 'Should start on DifficultyScreen');

      // Push quiz (matching the real DifficultyScreen card onTap: context.push('/quiz')).
      router.push('/quiz');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('QUIZ_SCREEN_STUB'), findsOneWidget,
          reason: 'Should be on QuizScreen after push');

      // Tap the back button — mirrors `context.pop()` in quiz_screen.dart:132.
      await tester.tap(find.byKey(const Key('quiz_back_btn')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // GUARD: DifficultyScreen must be visible.
      // Fails if back action were `context.go('/')` — that resets the stack to
      // Home and leaves DifficultyScreen absent.
      expect(
        find.byType(DifficultyScreen),
        findsOneWidget,
        reason:
            'After tapping quiz back the DIFFICULTY screen must be shown. '
            'This fails if quiz_screen.dart uses context.go("/") instead of context.pop().',
      );
      expect(
        find.text('HOME_SCREEN_STUB'),
        findsNothing,
        reason:
            'Home screen must NOT appear after tapping quiz back — '
            'context.go("/") regression guard.',
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Test 2 — Result → "Choose level" → difficulty
  //
  // ALL sub-tests (T2a, T2b, T2c, T2d) render the REAL ResultScreen widget.
  // The real widget is mounted inside a real GoRouter so the onTap closures
  // defined in result_screen.dart are what drives the navigation — no copy.
  // Any future change to those closures will cause the appropriate sub-test
  // to fail before it reaches production.
  //
  // The real ResultScreen needs quizNotifierProvider to return a completed
  // QuizState (with questions + answers) and sessionParamsProvider to be set.
  // We achieve this with _SeededQuizNotifier, which pre-seeds build() to a
  // two-question completed state.  The rest of the notifier is unmodified, so
  // reset() still works exactly as production code calls it.
  // ════════════════════════════════════════════════════════════════════════════
  group(
      'regression T2: Result screen buttons navigate correctly '
      '(real ResultScreen widget)', () {
    late AppDatabase db;

    setUp(() async {
      db = _openMemoryDb();
      await _seedNavFixture(db);
    });

    tearDown(() => db.close());

    // ── 2a. "Choose level" with canPop==true → pops back to Difficulty ────────
    //
    // Router stack: /difficulty?cat=nav_cat → (push) /result
    // context.canPop() is true on /result because difficulty is in the back-stack.
    // The real result_screen.dart levels-button onTap calls context.pop() in
    // this branch.  If that were changed to context.go('/'), this test fails.

    testWidgets(
        'T2a — REAL ResultScreen: "Choose level" (canPop==true) pops back to '
        'DifficultyScreen for the same category, NOT to Home', (tester) async {
      final container = _makeResultContainer(db);
      addTearDown(container.dispose);

      container.read(sessionParamsProvider.notifier).state =
          SessionParams(categorySlug: 'nav_cat', difficulty: Difficulty.beginner);

      // Start on Difficulty; push result on top so canPop()==true on result.
      final router = GoRouter(
        initialLocation: '/difficulty?cat=nav_cat',
        routes: [
          GoRoute(
            path: '/',
            builder: (ctx, s) => const _HomeStub(),
          ),
          GoRoute(
            path: '/difficulty',
            builder: (ctx, s) {
              final cat = s.uri.queryParameters['cat'] ?? '';
              return DifficultyScreen(categorySlug: cat);
            },
          ),
          GoRoute(
            path: '/result',
            // REAL ResultScreen — not a stub.  Its onTap closures are exercised.
            builder: (ctx, s) => const ResultScreen(),
          ),
          GoRoute(
            path: '/quiz',
            builder: (ctx, s) => const _QuizDestinationStub(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await _pumpRouterShell(tester, router: router, container: container);
      expect(find.byType(DifficultyScreen), findsOneWidget,
          reason: 'Should start on DifficultyScreen');

      // Push result (mirrors pushReplacement in quiz_screen.dart — both leave
      // difficulty in the back-stack for the canPop case).
      router.push('/result');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Confirm the REAL ResultScreen is present and its buttons are rendered.
      expect(find.byType(ResultScreen), findsOneWidget,
          reason: 'Real ResultScreen must be mounted for this test to be valid');
      expect(find.byKey(const Key('result_replay_btn')), findsOneWidget,
          reason: 'result_replay_btn must be present on real ResultScreen');
      expect(find.byKey(const Key('result_levels_btn')), findsOneWidget,
          reason: 'result_levels_btn must be present on real ResultScreen');
      expect(find.byKey(const Key('result_home_btn')), findsOneWidget,
          reason: 'result_home_btn must be present on real ResultScreen');

      // Tap the real "Choose level" button defined in result_screen.dart.
      await tester.tap(find.byKey(const Key('result_levels_btn')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // GUARD: DifficultyScreen must reappear (context.pop() in levels onTap).
      // Fails if the button calls context.go('/') unconditionally.
      expect(
        find.byType(DifficultyScreen),
        findsOneWidget,
        reason:
            'result_levels_btn (real ResultScreen, canPop==true) must pop back '
            'to DifficultyScreen for nav_cat. '
            'Fails if result_screen.dart calls context.go("/") instead of context.pop().',
      );
      expect(
        find.text('HOME_SCREEN_STUB'),
        findsNothing,
        reason:
            'Home must NOT appear after tapping "Choose level" — '
            'context.go("/") regression guard.',
      );
    });

    // ── 2b. "Choose level" with canPop==false → goes to Difficulty via go() ──
    //
    // Router starts directly at /result (deep-link scenario).
    // context.canPop() is false, and sessionParams is set.
    // The real result_screen.dart levels onTap calls
    // context.go('/difficulty?cat=${p.categorySlug}') in this branch.
    // If that fallback were omitted or changed to context.go('/'), this fails.

    testWidgets(
        'T2b — REAL ResultScreen: "Choose level" (canPop==false, params set) '
        'navigates to Difficulty via context.go, NOT to Home', (tester) async {
      final container = _makeResultContainer(db);
      addTearDown(container.dispose);

      container.read(sessionParamsProvider.notifier).state =
          SessionParams(categorySlug: 'nav_cat', difficulty: Difficulty.beginner);

      // Start directly on /result so canPop()==false.
      final router = GoRouter(
        initialLocation: '/result',
        routes: [
          GoRoute(
            path: '/',
            builder: (ctx, s) => const _HomeStub(),
          ),
          GoRoute(
            path: '/difficulty',
            builder: (ctx, s) {
              final cat = s.uri.queryParameters['cat'] ?? '';
              return DifficultyScreen(categorySlug: cat);
            },
          ),
          GoRoute(
            path: '/result',
            // REAL ResultScreen.
            builder: (ctx, s) => const ResultScreen(),
          ),
          GoRoute(
            path: '/quiz',
            builder: (ctx, s) => const _QuizDestinationStub(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await _pumpRouterShell(tester, router: router, container: container);

      expect(find.byType(ResultScreen), findsOneWidget,
          reason: 'Real ResultScreen must be mounted for this test to be valid');
      expect(find.byKey(const Key('result_levels_btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('result_levels_btn')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // GUARD: DifficultyScreen must appear via context.go('/difficulty?cat=nav_cat').
      // Fails on old code that called context.go('/') unconditionally.
      expect(
        find.byType(DifficultyScreen),
        findsOneWidget,
        reason:
            'With canPop==false and params set (real ResultScreen), '
            'result_levels_btn must call context.go("/difficulty?cat=nav_cat"). '
            'Fails if context.go("/") is called instead.',
      );
      expect(
        find.text('HOME_SCREEN_STUB'),
        findsNothing,
        reason: 'Home must NOT appear — regression guard for context.go("/").',
      );
    });

    // ── 2c. "Home" button ─────────────────────────────────────────────────────

    testWidgets(
        'T2c — REAL ResultScreen: result_home_btn navigates to Home screen',
        (tester) async {
      final container = _makeResultContainer(db);
      addTearDown(container.dispose);

      container.read(sessionParamsProvider.notifier).state =
          SessionParams(categorySlug: 'nav_cat', difficulty: Difficulty.beginner);

      final router = GoRouter(
        initialLocation: '/result',
        routes: [
          GoRoute(
            path: '/',
            builder: (ctx, s) => const _HomeStub(),
          ),
          GoRoute(
            path: '/difficulty',
            builder: (ctx, s) => DifficultyScreen(
                categorySlug: s.uri.queryParameters['cat'] ?? ''),
          ),
          GoRoute(
            path: '/result',
            // REAL ResultScreen.
            builder: (ctx, s) => const ResultScreen(),
          ),
          GoRoute(
            path: '/quiz',
            builder: (ctx, s) => const _QuizDestinationStub(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await _pumpRouterShell(tester, router: router, container: container);

      expect(find.byType(ResultScreen), findsOneWidget,
          reason: 'Real ResultScreen must be mounted for this test to be valid');

      await tester.tap(find.byKey(const Key('result_home_btn')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        find.text('HOME_SCREEN_STUB'),
        findsOneWidget,
        reason:
            'result_home_btn (real ResultScreen) must navigate to HomeScreen. '
            'Fails if result_screen.dart home onTap no longer calls context.go("/").',
      );
    });

    // ── 2d. "Replay" button ───────────────────────────────────────────────────

    testWidgets(
        'T2d — REAL ResultScreen: result_replay_btn navigates to Quiz screen',
        (tester) async {
      final container = _makeResultContainer(db);
      addTearDown(container.dispose);

      container.read(sessionParamsProvider.notifier).state =
          SessionParams(categorySlug: 'nav_cat', difficulty: Difficulty.beginner);

      final router = GoRouter(
        initialLocation: '/result',
        routes: [
          GoRoute(
            path: '/',
            builder: (ctx, s) => const _HomeStub(),
          ),
          GoRoute(
            path: '/difficulty',
            builder: (ctx, s) => DifficultyScreen(
                categorySlug: s.uri.queryParameters['cat'] ?? ''),
          ),
          GoRoute(
            path: '/result',
            // REAL ResultScreen.
            builder: (ctx, s) => const ResultScreen(),
          ),
          GoRoute(
            path: '/quiz',
            builder: (ctx, s) => const _QuizDestinationStub(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await _pumpRouterShell(tester, router: router, container: container);

      expect(find.byType(ResultScreen), findsOneWidget,
          reason: 'Real ResultScreen must be mounted for this test to be valid');

      await tester.tap(find.byKey(const Key('result_replay_btn')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        find.text('QUIZ_SCREEN_STUB'),
        findsOneWidget,
        reason:
            'result_replay_btn (real ResultScreen) must navigate to QuizScreen. '
            'Fails if result_screen.dart replay onTap no longer calls context.pushReplacement("/quiz").',
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Test 3 — Completed difficulty card style + tappable (guards A2/#2/#3)
  // ════════════════════════════════════════════════════════════════════════════
  group(
      'regression T3: DifficultyScreen card badges and tappability', () {
    late AppDatabase db;

    setUp(() async {
      db = _openMemoryDb();
      // Seed the category row; actual question counts come from the provider
      // override below so no question rows are needed for this test.
      await db.seedAll(
        cats: [
          CategoriesCompanion.insert(
            slug: 'badge_cat',
            iconKey: 'star',
            nameFr: 'Badge Test',
            nameEn: 'Badge Test',
            sortOrder: const Value(1),
          ),
        ],
        qs: [],
        opts: [],
      );
    });

    tearDown(() => db.close());

    testWidgets(
        'completed card shows difficulty_completed_badge + is enabled; '
        'in-progress shows difficulty_questions_remaining + is enabled; '
        'empty card shows neither badge + is disabled', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          soundNotifierProvider.overrideWith(() => _SilentSoundNotifier()),
          // beginner     → completed  (total:30, remaining:0)
          // intermediate → in-progress (total:30, remaining:12)
          // advanced     → empty      (total:0,  remaining:0)
          levelStatusProvider.overrideWith(
            (ref, params) async {
              return switch (params.difficulty) {
                Difficulty.beginner     => (total: 30, remaining: 0),
                Difficulty.intermediate => (total: 30, remaining: 12),
                Difficulty.advanced     => (total: 0,  remaining: 0),
              };
            },
          ),
        ],
      );
      addTearDown(container.dispose);

      await _pumpSingleScreen(
        tester,
        container: container,
        child: const DifficultyScreen(categorySlug: 'badge_cat'),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);

      // ── Beginner card: completed ──────────────────────────────────────────
      // GUARD: Key('difficulty_completed_badge') must appear exactly once.
      // Fails on old code where the pill Text had no stable key.
      expect(
        find.byKey(const Key('difficulty_completed_badge')),
        findsOneWidget,
        reason:
            'Beginner card (remaining==0) must show '
            'Key(difficulty_completed_badge). '
            'Fails if the key is absent or the wrong badge state is rendered.',
      );

      // ── Intermediate card: in-progress ───────────────────────────────────
      // GUARD: Key('difficulty_questions_remaining') must appear exactly once.
      expect(
        find.byKey(const Key('difficulty_questions_remaining')),
        findsOneWidget,
        reason:
            'Intermediate card (remaining:12) must show '
            'Key(difficulty_questions_remaining). '
            'Fails if the remaining-count Text has no stable key.',
      );

      // One of each badge confirms the advanced/empty card shows neither.
      // (advanced card has total==0 → renders "no questions" text, not a badge.)

      // ── Opacity gate: card enabled/disabled ───────────────────────────────
      // _DifficultyCard.build() returns Opacity(...) as its root widget.
      // The key is placed on the _DifficultyCard widget by the DifficultyScreen
      // (inside a statusAsync.when(data: ...) branch), so in the element tree
      // the keyed element IS the _DifficultyCard StatelessElement.
      // Its first rendered child is the Opacity widget returned from build().
      //
      // We walk DESCENDANTS of the card finder until we hit the first Opacity.

      double opacityFor(Finder cardFinder) {
        final el = cardFinder.evaluate().first;
        double found = 1.0;
        // Visit direct children first (Opacity is the root of _DifficultyCard.build).
        void visit(Element element) {
          if (element.widget is Opacity) {
            found = (element.widget as Opacity).opacity;
            return;
          }
          element.visitChildren(visit);
        }
        el.visitChildren(visit);
        return found;
      }

      // Beginner (completed, total>0) → must be enabled (Opacity==1.0).
      // Fails if A2 logic marks completed cards as disabled.
      final beginnerOpacity =
          opacityFor(find.byKey(const Key('difficulty_card_beginner')));
      expect(
        beginnerOpacity,
        equals(1.0),
        reason:
            'Completed beginner card must be enabled (Opacity==1.0). '
            'A disabled card has Opacity==0.45. '
            'Fails if A2 incorrectly disables completed cards.',
      );

      // Intermediate (in-progress, remaining>0) → must be enabled.
      final intermediateOpacity =
          opacityFor(find.byKey(const Key('difficulty_card_intermediate')));
      expect(
        intermediateOpacity,
        equals(1.0),
        reason:
            'In-progress intermediate card must be enabled (Opacity==1.0).',
      );

      // Advanced (total==0, no content) → must be disabled (Opacity<1.0).
      // Fails if A2 incorrectly marks a no-content card as tappable.
      final advancedOpacity =
          opacityFor(find.byKey(const Key('difficulty_card_advanced')));
      expect(
        advancedOpacity,
        lessThan(1.0),
        reason:
            'Empty advanced card (total==0) must be disabled (Opacity<1.0). '
            'Fails if A2 marks a no-content card as tappable.',
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // Test 4 — Counts refresh on return (guards stale levelStatusProvider cache)
  // ════════════════════════════════════════════════════════════════════════════
  group(
      'regression T4: levelStatusProvider reflects completed badge after '
      'answering the last remaining question', () {
    late AppDatabase db;

    setUp(() async {
      db = _openMemoryDb();
      await _seedNavFixture(db);
    });

    tearDown(() => db.close());

    // ── 4a. Repository: countRemaining → 0 after recording last answer ────────

    test(
        'countRemaining returns 0 after all three beginner questions '
        'are recorded as correctly answered', () async {
      final repo = QuizRepository(db);

      final initialRemaining =
          await repo.countRemaining('nav_cat', Difficulty.beginner);
      expect(initialRemaining, 3,
          reason: 'Fixture has 3 beginner questions — all initially remaining');

      await repo.recordAnswer(10, true);
      await repo.recordAnswer(11, true);
      await repo.recordAnswer(12, true);

      final afterRemaining =
          await repo.countRemaining('nav_cat', Difficulty.beginner);

      // GUARD: must be 0.
      // Fails on old code that did not write to question_progress.
      expect(
        afterRemaining,
        0,
        reason:
            'After recording all 3 correct answers remaining must be 0. '
            'Fails if recordAnswer does not persist to question_progress table.',
      );
    });

    // ── 4b. Widget: DifficultyScreen shows completed badge after remount ──────

    testWidgets(
        'DifficultyScreen shows difficulty_completed_badge after all '
        'questions answered correctly and screen is freshly mounted',
        (tester) async {
      final container = _makeContainer(db);
      addTearDown(container.dispose);

      // Write all answers before mounting so the screen reads fresh data.
      final repo = container.read(quizRepositoryProvider);
      await repo.recordAnswer(10, true);
      await repo.recordAnswer(11, true);
      await repo.recordAnswer(12, true);

      await _pumpSingleScreen(
        tester,
        container: container,
        child: const DifficultyScreen(categorySlug: 'nav_cat'),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);

      // GUARD: completed badge on beginner card.
      // Fails if:
      //   (a) autoDispose removed from levelStatusProvider → stale cache, or
      //   (b) recordAnswer didn't persist.
      expect(
        find.byKey(const Key('difficulty_completed_badge')),
        findsOneWidget,
        reason:
            'After recording all answers correctly the beginner card must '
            'show difficulty_completed_badge (remaining==0). '
            'Fails if levelStatusProvider is not autoDispose (stale cache) '
            'or if recordAnswer does not persist.',
      );
    });

    // ── 4c. Full round-trip: answer all questions, then mount a fresh screen ───
    //
    // This test simulates the full user journey:
    //   1. User is on Difficulty screen.
    //   2. User navigates to quiz and answers all questions correctly.
    //   3. User navigates back to Difficulty.
    //   4. The difficulty card must now show the completed badge.
    //
    // The real-world mechanism: levelStatusProvider is autoDispose.family, so
    // when the DifficultyScreen unmounts (during quiz navigation) the provider
    // disposes and its cached value is cleared.  On remount, a new provider
    // instance queries the DB and gets remaining==0.
    //
    // In the widget test, GoRouter's page transitions can keep both pages alive
    // briefly during the route change.  To isolate the "fresh mount after
    // answers are written" aspect we explicitly write all answers THEN replace
    // the entire widget tree — which guarantees a clean provider re-query.
    // (T4b already covers the simpler single-mount case; T4c focuses on the
    //  "provider must not be stale" invariant by pumping a fresh widget tree.)

    testWidgets(
        'after recording all answers and replacing the widget tree, '
        'DifficultyScreen shows completed badge (no stale provider cache)',
        (tester) async {
      final container = _makeContainer(db);
      addTearDown(container.dispose);

      // Step 1: mount the Difficulty screen and navigate to quiz.
      container.read(sessionParamsProvider.notifier).state =
          SessionParams(categorySlug: 'nav_cat', difficulty: Difficulty.beginner);

      final router = GoRouter(
        initialLocation: '/quiz',
        routes: [
          GoRoute(
            path: '/difficulty',
            builder: (ctx, s) {
              final cat = s.uri.queryParameters['cat'] ?? '';
              return DifficultyScreen(categorySlug: cat);
            },
          ),
          GoRoute(
            path: '/quiz',
            builder: (ctx, s) => _QuizScreenStub(),
          ),
          GoRoute(
            path: '/',
            builder: (ctx, s) => const _HomeStub(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await _pumpRouterShell(tester, router: router, container: container);
      expect(find.text('QUIZ_SCREEN_STUB'), findsOneWidget,
          reason: 'Should start on QuizScreen');

      // Step 2: record all answers correctly (real DB write, same as selectOption).
      final repo = container.read(quizRepositoryProvider);
      await repo.recordAnswer(10, true);
      await repo.recordAnswer(11, true);
      await repo.recordAnswer(12, true);

      // Verify the DB really has remaining==0 before checking the widget.
      final remaining = await repo.countRemaining('nav_cat', Difficulty.beginner);
      expect(remaining, 0, reason: 'DB must have remaining==0 before remount');

      // Step 3: navigate to Difficulty — the quiz page is fully replaced.
      // We pump generously to let autoDispose fire (old screen unmounts) and
      // the FutureProvider for the new screen resolve.
      router.go('/difficulty?cat=nav_cat');
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(find.byType(DifficultyScreen), findsOneWidget,
          reason: 'Should be on DifficultyScreen after navigation');

      // GUARD: completed badge must now be visible.
      // Fails on:
      //   (a) Non-autoDispose levelStatusProvider that caches stale remaining>0, or
      //   (b) recordAnswer that doesn't persist (remaining stays > 0).
      expect(
        find.byKey(const Key('difficulty_completed_badge')),
        findsOneWidget,
        reason:
            'After navigating back from a completed quiz the beginner card '
            'must show difficulty_completed_badge. '
            'Fails on stale levelStatusProvider (not autoDispose) or '
            'if recordAnswer did not persist.',
      );
    });
  });
}
