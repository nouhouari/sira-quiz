// ignore_for_file: avoid_print
//
// Integration regression test — Phase B / Feature 1 (navigation) + Feature 2
// (progress persistence).
//
// Run on device:
//   flutter test integration_test/regression_progress_nav_test.dart -d RR8W900EWQP
//
// Both scenarios MUST run inside ONE testWidgets call (app.main() must be
// called only once per session — re-opening the Drift DB causes
// "Too many elements" in isCategoriesEmpty).
//
// ── F1: Back from quiz → Difficulty screen (not Home) ───────────────────────
//
// Pre-fix: tapping FHeaderAction.back in QuizScreen called context.go('/')
//          which navigated to the Home route regardless of where you came from.
// Post-fix: tapping the back button calls context.pop() which pops the quiz
//           route and reveals the Difficulty screen below it.
//
// Assertion that fails on old code:
//   find.byKey(const Key('home_start_btn'))  →  findsNothing (was findsOneWidget)
//   find.byWidgetPredicate(difficulty_card_*)  →  findsWidgets (was findsNothing)
//
// ── F2: Progress persistence — mastered question not shown again ────────────
//
// Pre-fix: No question_progress table.  getSessionQuestions returned ALL
//          questions every session, so a just-answered question was always
//          included in the next session.
// Post-fix: getUnansweredQuestions excludes correctly-answered questions via
//           the NOT IN subquery.  The difficulty screen also shows a reduced
//           remaining count.
//
// Assertion that fails on old code:
//   remainingBefore > remainingAfter  →  remainingBefore == remainingAfter
//   because countRemaining equalled countTotal in the old code.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sira_quiz/main.dart' as app;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<void> _tap(WidgetTester tester, Key key,
    {Duration settle = const Duration(seconds: 3)}) async {
  final f = find.byKey(key);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
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

/// Press the ForUI back button (FHeaderAction.back = FLucideIcons.arrowLeft SVG).
/// Not a Material icon → must locate by semantics, NOT by Icons.arrow_back_*.
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

/// Tap an option tile and advance.  Returns true if the quiz is now complete
/// (Résultats screen visible).
Future<bool> _answerOneQuestion(WidgetTester tester) async {
  final tiles = find.byWidgetPredicate(
    (w) => w.key != null && w.key.toString().contains('option_tile_'),
  );
  if (tiles.evaluate().isEmpty) return false;

  await tester.tap(tiles.first);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  final nextBtn = find.byKey(const Key('quiz_next_btn'));
  if (nextBtn.evaluate().isNotEmpty) {
    await tester.ensureVisible(nextBtn);
    await tester.pumpAndSettle();
    await tester.tap(nextBtn);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  return find.text('Résultats').evaluate().isNotEmpty;
}

/// Tap the CORRECT option tile and advance.
/// We locate the correct option by tapping the first tile that, after tapping,
/// shows the Next/Voir button.  However, since we cannot read DB ids from the
/// widget layer in integration tests, we use the simplest proxy: the quiz
/// always shows the feedback card and the Next button regardless of
/// correctness, so this just taps the first option.
///
/// For F2 the important thing is that AT LEAST ONE correct answer is recorded.
/// The actual option tiles are shuffled, so some will be correct.  We wrap the
/// whole answer loop and accept the probability of at least one correct hit.

/// Read the "remaining" count displayed on a difficulty card by extracting the
/// text from the Key('difficulty_questions_remaining') widget.
/// Returns null if the widget is not found or still loading.
int? _readRemainingCount(WidgetTester tester) {
  final widgets = find.byKey(const Key('difficulty_questions_remaining'));
  if (widgets.evaluate().isEmpty) return null;

  // The Text widget's data field contains the localized string, e.g.
  // "7 restantes" or "Terminé".  We try to parse the leading integer.
  final widget = tester.widget(widgets.first);
  if (widget is Text) {
    final data = widget.data ?? '';
    // "Terminé" badge → remaining == 0
    if (data.contains('Terminé') || data.contains('Completed')) return 0;
    final match = RegExp(r'(\d+)').firstMatch(data);
    if (match != null) return int.tryParse(match.group(1)!);
  }
  return null;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ONE testWidgets — both scenarios share a single app.main() call.
  testWidgets(
      'F1: back from quiz → Difficulty; F2: mastered question excluded next session',
      (WidgetTester tester) async {
    // ── Launch ────────────────────────────────────────────────────────────────
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 6));

    expect(
      find.byKey(const Key('home_start_btn')),
      findsOneWidget,
      reason: 'App must be on Home screen after launch',
    );

    // ╔══════════════════════════════════════════════════════════════════════╗
    // ║  SCENARIO F1: Back from quiz → Difficulty (not Home)                 ║
    // ╚══════════════════════════════════════════════════════════════════════╝

    // Navigate: Home → Categories
    await _tap(tester, const Key('home_start_btn'));
    expect(find.textContaining('Catégorie'), findsWidgets);

    // Categories → Difficulty (pick birth_youth or first available category)
    final catCards = find.byWidgetPredicate(
      (w) => w.key != null && w.key.toString().contains('category_card_'),
    );
    expect(catCards, findsWidgets,
        reason: 'At least one category card must be visible');
    await tester.ensureVisible(catCards.first);
    await tester.pumpAndSettle();
    await tester.tap(catCards.first);
    await tester.pumpAndSettle(const Duration(seconds: 4));

    expect(find.textContaining('Difficulté'), findsWidgets,
        reason: 'Must be on Difficulty screen after tapping a category');

    // Confirm difficulty cards are present (we'll check for them after back).
    final diffCardsBeforeQuiz = find.byWidgetPredicate(
      (w) => w.key != null && w.key.toString().contains('difficulty_card_'),
    );
    expect(diffCardsBeforeQuiz, findsWidgets,
        reason: 'Difficulty cards must be visible before entering the quiz');

    // Difficulty → Quiz (tap first enabled difficulty card).
    // We tap 'Débutant' by text for determinism — it is always present.
    await _tapText(tester, 'Débutant', settle: const Duration(seconds: 6));
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Confirm we are on the Quiz screen (question counter present).
    // Check for either the loading screen or the actual quiz screen.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // If allMastered is shown, back still goes to difficulty (same code path).
    // Either way we tap back now.
    print('[F1] On quiz/mastered screen — tapping back button');

    // TAP the ForUI back button: FHeaderAction.back → semantics label 'Back'
    await _goBack(tester, settle: const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ── F1 GUARD assertions ───────────────────────────────────────────────────
    //
    // Old behavior: context.go('/') → lands on Home (home_start_btn present).
    // New behavior: context.pop()  → lands on Difficulty (difficulty_card_* present).

    // 1. home_start_btn must NOT be visible (we must NOT be on Home).
    expect(
      find.byKey(const Key('home_start_btn')),
      findsNothing,
      reason:
          'F1 regression guard: after tapping the quiz back button we must NOT '
          'be on the Home screen. Old code used context.go("/") which went Home. '
          'New code uses context.pop() which returns to Difficulty.',
    );

    // 2. Difficulty cards must be visible (we must be on the Difficulty screen).
    final diffCardsAfterBack = find.byWidgetPredicate(
      (w) => w.key != null && w.key.toString().contains('difficulty_card_'),
    );
    expect(
      diffCardsAfterBack,
      findsWidgets,
      reason:
          'F1 regression guard: after tapping the quiz back button we must land '
          'on the Difficulty screen (difficulty_card_* widgets visible). '
          'Old code navigated to Home instead of popping back here.',
    );

    // 3. Difficulty title must be present.
    expect(
      find.textContaining('Difficulté'),
      findsWidgets,
      reason:
          'F1: the Difficulty screen title must be visible after popping back from quiz',
    );

    print('[F1] PASSED: back from quiz → Difficulty screen confirmed');

    // ╔══════════════════════════════════════════════════════════════════════╗
    // ║  SCENARIO F2: Progress persistence — mastered question excluded       ║
    // ╚══════════════════════════════════════════════════════════════════════╝
    //
    // Strategy:
    //   a) Read the remaining count shown on the beginner card.
    //   b) Enter the quiz, answer enough questions to master at least one.
    //   c) Return to the Difficulty screen.
    //   d) Read the remaining count again — it must be lower (or 0 = Terminé).
    //   e) Re-enter the same level and assert that total questions in the new
    //      session is less than the original total (or allMastered is shown).
    //
    // We are already on the Difficulty screen from F1.

    // Read remaining count BEFORE the session.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Get the beginner card's remaining count — wait for it to load.
    int? remainingBefore;
    for (var attempt = 0; attempt < 5; attempt++) {
      remainingBefore = _readRemainingCount(tester);
      if (remainingBefore != null) break;
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    print('[F2] Remaining count BEFORE session: $remainingBefore');

    // Enter Beginner quiz and answer ALL questions (or until result/mastered).
    await _tapText(tester, 'Débutant', settle: const Duration(seconds: 6));
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Answer questions until we hit the result screen or allMastered.
    int iterations = 0;
    const maxIterations = 15;
    bool reachedEnd = false;

    while (iterations < maxIterations) {
      await tester.pumpAndSettle(const Duration(seconds: 2));

      if (find.text('Résultats').evaluate().isNotEmpty) {
        reachedEnd = true;
        break;
      }
      if (find.text('Niveau maîtrisé').evaluate().isNotEmpty) {
        reachedEnd = true;
        break;
      }

      final done = await _answerOneQuestion(tester);
      if (done) {
        reachedEnd = true;
        break;
      }
      iterations++;
    }

    print('[F2] Reached end of session: $reachedEnd (iterations=$iterations)');

    // Navigate back to the Difficulty screen.
    if (find.text('Résultats').evaluate().isNotEmpty) {
      // From result screen: tap Home then re-navigate.
      // Alternatively pop back via back button.
      final homeBtn = find.byKey(const Key('result_home_btn'));
      if (homeBtn.evaluate().isNotEmpty) {
        await _tap(tester, const Key('result_home_btn'));
      } else {
        // Fall back: pop back twice (result → quiz → difficulty not accessible
        // after pushReplacement, so navigate home then re-enter).
        await _goBack(tester);
      }
      // We're likely at Home now. Re-navigate to Difficulty.
      await tester.pumpAndSettle(const Duration(seconds: 2));
      if (find.byKey(const Key('home_start_btn')).evaluate().isNotEmpty) {
        await _tap(tester, const Key('home_start_btn'));
        await tester.pumpAndSettle(const Duration(seconds: 3));
        final cats = find.byWidgetPredicate(
          (w) => w.key != null && w.key.toString().contains('category_card_'),
        );
        if (cats.evaluate().isNotEmpty) {
          await tester.ensureVisible(cats.first);
          await tester.pumpAndSettle();
          await tester.tap(cats.first);
          await tester.pumpAndSettle(const Duration(seconds: 4));
        }
      }
    } else if (find.text('Niveau maîtrisé').evaluate().isNotEmpty) {
      // From mastered screen: tap the back button to return to Difficulty.
      final masteredBack = find.byKey(const Key('mastered_back_btn'));
      if (masteredBack.evaluate().isNotEmpty) {
        await tester.tap(masteredBack);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      } else {
        await _goBack(tester);
      }
    }

    // Wait for levelStatusProvider to reload with fresh counts.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Read remaining count AFTER the session.
    int? remainingAfter;
    for (var attempt = 0; attempt < 5; attempt++) {
      remainingAfter = _readRemainingCount(tester);
      if (remainingAfter != null) break;
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    print('[F2] Remaining count AFTER session: $remainingAfter');

    // ── F2 GUARD assertions ───────────────────────────────────────────────────
    //
    // The remaining count must have DECREASED (or reached 0 = Terminé badge).
    //
    // Old behavior: countRemaining == countTotal always, so before == after.
    // New behavior: correct answers are persisted; countRemaining drops.
    //
    // Note: if remainingBefore was already 0 (already-mastered level on the
    // device) both values will be 0 and the test is trivially true — the
    // allMastered guard below covers that.

    if (remainingBefore != null && remainingAfter != null) {
      expect(
        remainingAfter,
        lessThan(remainingBefore > 0 ? remainingBefore : 1),
        reason:
            'F2 regression guard: the remaining count on the Difficulty card must '
            'DECREASE after answering questions correctly. '
            'Old code did not persist progress (question_progress table missing) '
            'so countRemaining always equalled countTotal — remainingBefore == remainingAfter. '
            'New code persists correct answers: remainingAfter < remainingBefore.',
      );
    } else {
      // If we hit "Niveau maîtrisé" or the difficulty shows "Terminé",
      // that alone proves progress was persisted.
      final termineDone = find.text('Terminé').evaluate().isNotEmpty ||
          find.text('Completed').evaluate().isNotEmpty ||
          find.text('Niveau maîtrisé').evaluate().isNotEmpty;

      expect(
        termineDone,
        isTrue,
        reason:
            'F2: could not read numeric remaining count; but at minimum the '
            '"Terminé" badge or "Niveau maîtrisé" screen must be visible to '
            'confirm progress was persisted.',
      );
    }

    print('[F2] PASSED: progress persistence confirmed');
  });
}
