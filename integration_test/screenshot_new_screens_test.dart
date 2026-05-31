// ignore_for_file: avoid_print
//
// Screenshot capture for Phase B's new screens:
//   13-mastered.png         — _MasteredScreen (Niveau maîtrisé)
//   14-difficulty-terminé.png — Difficulty screen showing at least one "Terminé" badge
//
// This file is intentionally separate from screenshot_tour_test.dart so it can
// be run independently after progress data has been established.
//
// Run via flutter drive (writes PNGs via the test_driver onScreenshot hook):
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshot_new_screens_test.dart \
//     -d RR8W900EWQP
//
// The simplest reliable path to _MasteredScreen on-device:
//   1. Navigate to a Difficulty screen.
//   2. Enter a Beginner level.
//   3. If the level is already mastered → allMastered screen is shown immediately.
//      Otherwise answer all questions correctly (best-effort) and re-enter.
//
// Note: Because the device DB state may vary, we drive the full answer loop
// and then re-enter the level to trigger allMastered.  If the level is not
// fully mastered after one pass the test still captures whatever state is shown
// and reports it clearly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sira_quiz/main.dart' as app;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<void> _shot(
    IntegrationTestWidgetsFlutterBinding binding,
    WidgetTester tester,
    String name) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 600));
  await binding.takeScreenshot(name);
  print('[screenshot] $name captured');
}

Future<void> _tap(WidgetTester tester, Key key,
    {Duration settle = const Duration(seconds: 3)}) async {
  final f = find.byKey(key);
  if (f.evaluate().isNotEmpty) {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
  }
  await tester.tap(f);
  await tester.pumpAndSettle(settle);
}

Future<void> _tapText(WidgetTester tester, String text,
    {Duration settle = const Duration(seconds: 3)}) async {
  final f = find.text(text).first;
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle(settle);
}

Future<void> _goBack(WidgetTester tester,
    {Duration settle = const Duration(seconds: 2)}) async {
  for (final label in ['Back', 'Retour', 'back', 'retour']) {
    final f = find.bySemanticsLabel(label);
    if (f.evaluate().isNotEmpty) {
      await tester.tap(f.first);
      await tester.pumpAndSettle(settle);
      return;
    }
  }
  final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  if (nav.canPop()) {
    nav.pop();
    await tester.pumpAndSettle(settle);
  }
}

/// Answer all questions in the current quiz session (best-effort: taps first
/// visible option tile on each question).  Returns true if the result screen
/// or mastered screen is reached.
Future<bool> _answerAllQuestions(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pumpAndSettle(const Duration(seconds: 2));

    if (find.text('Résultats').evaluate().isNotEmpty) return true;
    if (find.text('Niveau maîtrisé').evaluate().isNotEmpty) return true;

    final tiles = find.byWidgetPredicate(
      (w) => w.key != null && w.key.toString().contains('option_tile_'),
    );
    if (tiles.evaluate().isEmpty) continue;

    // Try to find the CORRECT option by checking the sort-order=1 tile.
    // We tap the first tile available — some will be correct, progressing the
    // mastery count toward allMastered.
    await tester.tap(tiles.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final nextBtn = find.byKey(const Key('quiz_next_btn'));
    if (nextBtn.evaluate().isNotEmpty) {
      await tester.ensureVisible(nextBtn);
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }
  }
  return false;
}

/// Navigate from the result screen back home.
Future<void> _fromResultToHome(WidgetTester tester) async {
  final homeBtn = find.byKey(const Key('result_home_btn'));
  if (homeBtn.evaluate().isNotEmpty) {
    await tester.ensureVisible(homeBtn);
    await tester.pumpAndSettle();
    await tester.tap(homeBtn);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

// ---------------------------------------------------------------------------
// Screenshot tour for new screens
// ---------------------------------------------------------------------------

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour — Phase B new screens (mastered + terminé)',
      (WidgetTester tester) async {
    await binding.convertFlutterSurfaceToImage();

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 6));

    // ── Navigate to the birth_youth / Beginner quiz ────────────────────────────
    await _tap(tester, const Key('home_start_btn'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Pick first category (birth_youth if seeded, else first available).
    final cats = find.byWidgetPredicate(
      (w) => w.key != null && w.key.toString().contains('category_card_'),
    );
    expect(cats, findsWidgets, reason: 'At least one category card must exist');
    await tester.ensureVisible(cats.first);
    await tester.pumpAndSettle();
    await tester.tap(cats.first);
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // ── First attempt at mastering the level ──────────────────────────────────
    // Enter Beginner.
    await _tapText(tester, 'Débutant', settle: const Duration(seconds: 6));
    await tester.pumpAndSettle(const Duration(seconds: 4));

    if (find.text('Niveau maîtrisé').evaluate().isNotEmpty) {
      // Already mastered from a prior run → capture immediately.
      print('[screenshot] Level already mastered — capturing 13-mastered now');
      await _shot(binding, tester, '13-mastered');

      await _goBack(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await _shot(binding, tester, '14-difficulty-termine');
      return;
    }

    // Answer the full session.
    await _answerAllQuestions(tester);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    if (find.text('Niveau maîtrisé').evaluate().isNotEmpty) {
      await _shot(binding, tester, '13-mastered');
      await _goBack(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await _shot(binding, tester, '14-difficulty-termine');
      return;
    }

    // Reached result screen — go home and re-enter to trigger allMastered.
    if (find.text('Résultats').evaluate().isNotEmpty) {
      await _fromResultToHome(tester);
    } else {
      // Unexpected state — try to pop back to home.
      for (var i = 0; i < 3; i++) {
        await _goBack(tester);
        if (find.byKey(const Key('home_start_btn')).evaluate().isNotEmpty) {
          break;
        }
      }
    }

    // Re-navigate to the same level — with at least some correct answers
    // recorded, subsequent sessions have fewer unanswered questions.
    // Repeat up to 3 times until allMastered is shown.
    bool masteredCaptured = false;
    for (var pass = 0; pass < 3 && !masteredCaptured; pass++) {
      // Re-navigate to the difficulty screen.
      if (find.byKey(const Key('home_start_btn')).evaluate().isNotEmpty) {
        await _tap(tester, const Key('home_start_btn'));
        await tester.pumpAndSettle(const Duration(seconds: 3));
        final c2 = find.byWidgetPredicate(
          (w) => w.key != null && w.key.toString().contains('category_card_'),
        );
        if (c2.evaluate().isNotEmpty) {
          await tester.ensureVisible(c2.first);
          await tester.pumpAndSettle();
          await tester.tap(c2.first);
          await tester.pumpAndSettle(const Duration(seconds: 4));
        }
      }

      // Enter Beginner.
      await _tapText(tester, 'Débutant', settle: const Duration(seconds: 6));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      if (find.text('Niveau maîtrisé').evaluate().isNotEmpty) {
        await _shot(binding, tester, '13-mastered');
        masteredCaptured = true;

        // Pop back to capture the Terminé badge.
        await _goBack(tester);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await _shot(binding, tester, '14-difficulty-termine');
        break;
      }

      // Answer remaining questions.
      await _answerAllQuestions(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      if (find.text('Niveau maîtrisé').evaluate().isNotEmpty) {
        await _shot(binding, tester, '13-mastered');
        masteredCaptured = true;

        await _goBack(tester);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await _shot(binding, tester, '14-difficulty-termine');
        break;
      }

      if (find.text('Résultats').evaluate().isNotEmpty) {
        await _fromResultToHome(tester);
      } else {
        for (var i = 0; i < 3; i++) {
          await _goBack(tester);
          if (find.byKey(const Key('home_start_btn')).evaluate().isNotEmpty) {
            break;
          }
        }
      }
    }

    if (!masteredCaptured) {
      // Could not reach allMastered in 3 passes — capture current state for
      // inspection and note the limitation.
      print(
        '[screenshot] WARNING: could not reach "Niveau maîtrisé" in 3 passes. '
        'The level may have many questions requiring more correct answers. '
        'Capturing current Difficulty screen state as fallback.',
      );
      // Make sure we are on the Difficulty screen.
      if (find.byWidgetPredicate(
        (w) => w.key != null && w.key.toString().contains('difficulty_card_'),
      ).evaluate().isNotEmpty) {
        await _shot(binding, tester, '13-mastered-not-reached');
        await _shot(binding, tester, '14-difficulty-termine');
      }
    }
  });
}
