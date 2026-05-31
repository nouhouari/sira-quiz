// ignore_for_file: avoid_print
//
// Integration regression test — runs on the real device against the real DB.
//
// regression: quiz option tiles render without Material ancestor crash
// ─────────────────────────────────────────────────────────────────────────────
// Option tiles were briefly implemented with InkWell, which requires a Material
// ancestor.  ForUI's FScaffold does NOT supply one.  On first render of the
// unanswered quiz screen Flutter threw:
//
//   "No Material widget found. _InkResponseStateWidget requires a Material
//    widget ancestor."
//
// and replaced the options list with a red ErrorWidget.  The pre-existing
// integration test (quiz_flow_test.dart) stayed GREEN because it found tiles
// with `find.byWidgetPredicate((w) => w is InkWell && ...)`, which evaluated
// to zero hits after the InkWell was present but CRASHED — the tap loop was
// silently skipped.  Neither takeException() nor ErrorWidget was checked on
// the unanswered screen.
//
// This test closes that gap by:
//   1. Driving the REAL user path to the quiz screen.
//   2. Asserting a clean unanswered render BEFORE any tap.
//   3. Completing the session and asserting the result screen appears.
//
// Run:
//   flutter test integration_test/regression_quiz_render_test.dart -d RR8W900EWQP

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sira_quiz/main.dart' as app;

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<void> _tapKey(WidgetTester tester, Key key,
    {Duration settle = const Duration(seconds: 3)}) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle(settle);
}

// ── Test ──────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'regression: quiz option tiles render without Material ancestor crash',
      (WidgetTester tester) async {
    // ── Launch ──────────────────────────────────────────────────────────────
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(
      find.byKey(const Key('home_start_btn')),
      findsOneWidget,
      reason: 'App must reach home screen after launch',
    );

    // ── Real user path: Home → Categories → Difficulty → Quiz ───────────────
    await _tapKey(tester, const Key('home_start_btn'));
    expect(find.textContaining('Catégorie'), findsWidgets);

    // Pick the first visible category card.
    final categoryCards = find.byWidgetPredicate(
      (w) =>
          w.key != null &&
          w.key.toString().contains('category_card_'),
    );
    expect(categoryCards, findsWidgets,
        reason: 'At least one category_card_* key must be visible');
    await tester.ensureVisible(categoryCards.first);
    await tester.pumpAndSettle();
    await tester.tap(categoryCards.first);
    await tester.pumpAndSettle(const Duration(seconds: 4));

    expect(find.textContaining('Difficulté'), findsWidgets);

    // Pick the first visible difficulty card (Beginner / Débutant).
    final difficultyCards = find.byWidgetPredicate(
      (w) =>
          w.key != null &&
          w.key.toString().contains('difficulty_card_'),
    );
    expect(difficultyCards, findsWidgets,
        reason: 'At least one difficulty_card_* key must be visible');
    await tester.ensureVisible(difficultyCards.first);
    await tester.pumpAndSettle();
    await tester.tap(difficultyCards.first);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // ── UNANSWERED screen — the exact failure point ──────────────────────────
    // Wait for the quiz to finish loading.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 1. No exception on first render.
    // Pre-fix InkWell code threw a FlutterError here that takeException() would
    // return as non-null.
    expect(
      tester.takeException(),
      isNull,
      reason:
          'No exception must be thrown on the unanswered quiz screen '
          '(InkWell without Material ancestor would fail here — C-4)',
    );

    // 2. No ErrorWidget in the unanswered state.
    // Pre-fix code rendered a red ErrorWidget in place of the options list.
    expect(
      find.byType(ErrorWidget),
      findsNothing,
      reason:
          'ErrorWidget must not appear on the unanswered quiz screen',
    );

    // 3. Option tiles must be present with their stable Keys, found via Key
    //    lookup (NOT via InkWell — that was the stale finder that masked the bug).
    final optionTiles = find.byWidgetPredicate(
      (w) =>
          w.key != null &&
          w.key.toString().contains('option_tile_'),
    );
    expect(
      optionTiles,
      findsWidgets,
      reason:
          'option_tile_* keyed widgets must be present on the unanswered screen',
    );

    // 4. Question text must be visible (not obscured by an error overlay).
    expect(
      find.textContaining('Question'),
      findsWidgets,
      reason: 'Question counter text must be visible on the quiz screen',
    );

    // 5. Next button must NOT appear before any option is selected.
    expect(
      find.byKey(const Key('quiz_next_btn')),
      findsNothing,
      reason: 'quiz_next_btn must not be shown before any option is tapped',
    );

    // ── Complete the session — verify feedback and result also render cleanly ─
    int iterations = 0;
    const maxIterations = 15;

    while (iterations < maxIterations) {
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Reached result screen?
      if (find.text('Résultats').evaluate().isNotEmpty) break;

      // Locate option tiles by Key (the correct, stable approach).
      final tiles = find.byWidgetPredicate(
        (w) =>
            w.key != null &&
            w.key.toString().contains('option_tile_'),
      );

      if (tiles.evaluate().isEmpty) {
        iterations++;
        continue;
      }

      await tester.tap(tiles.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Post-answer render must also be clean.
      expect(
        tester.takeException(),
        isNull,
        reason: 'No exception after tapping an option tile (iteration $iterations)',
      );
      expect(
        find.byType(ErrorWidget),
        findsNothing,
        reason: 'No ErrorWidget after tapping option (iteration $iterations)',
      );

      // Advance to next question if the Next button is available.
      final nextBtn = find.byKey(const Key('quiz_next_btn'));
      if (nextBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(nextBtn);
        await tester.pumpAndSettle();
        await tester.tap(nextBtn);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      iterations++;
    }

    // ── Result screen assertions ─────────────────────────────────────────────
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(
      find.text('Résultats'),
      findsOneWidget,
      reason: 'Result screen must appear after answering all questions',
    );
    expect(
      find.textContaining(' / '),
      findsWidgets,
      reason: 'A score "X / Y" must be visible on the result screen',
    );

    // Final safety net: no exception or ErrorWidget on the result screen.
    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
  });
}
