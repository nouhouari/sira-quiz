// ignore_for_file: avoid_print

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sira_quiz/main.dart' as app;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<void> _launch(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

Future<void> _tap(WidgetTester tester, Key key,
    {Duration settle = const Duration(seconds: 3)}) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle(settle);
}

Future<void> _tapText(WidgetTester tester, String text,
    {Duration settle = const Duration(seconds: 3)}) async {
  final finder = find.text(text).first;
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle(settle);
}

/// Navigate via the back route or Navigator.pop.
/// ForUI uses Lucide SVG icons — not Material icons — so we find by semantics.
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
  final NavigatorState nav =
      tester.state<NavigatorState>(find.byType(Navigator).first);
  if (nav.canPop()) {
    nav.pop();
    await tester.pumpAndSettle(settle);
  }
}

// ---------------------------------------------------------------------------
// Integration flow test
//
// All scenarios run in ONE testWidgets to avoid re-calling app.main()
// (which would try to re-open the already-open Drift DB).
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Quiz integration: full session + language switch + about screen',
      (WidgetTester tester) async {
    // ── Launch app ──────────────────────────────────────────────────────────
    await _launch(tester);

    // ╔══════════════════════════════════════════════════════════════════════╗
    // ║  SCENARIO 1: Full session flow                                       ║
    // ╚══════════════════════════════════════════════════════════════════════╝

    expect(find.byKey(const Key('home_start_btn')), findsOneWidget);
    expect(find.text('Quiz Sîra'), findsWidgets);

    // Home → Categories
    await _tap(tester, const Key('home_start_btn'));
    expect(find.text('Choisir une Catégorie'), findsOneWidget);
    expect(find.byKey(const Key('category_card_birth_youth')), findsOneWidget);

    // Categories → Difficulty (birth_youth)
    await _tap(tester, const Key('category_card_birth_youth'),
        settle: const Duration(seconds: 4));
    expect(find.text('Choisir la Difficulté'), findsOneWidget);

    // Difficulty → Quiz (Beginner)
    await _tapText(tester, 'Débutant', settle: const Duration(seconds: 5));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.textContaining('Question'), findsWidgets);

    // Answer all questions.
    var iterations = 0;
    const maxIterations = 12;
    while (iterations < maxIterations) {
      await tester.pumpAndSettle(const Duration(seconds: 2));
      if (find.text('Résultats').evaluate().isNotEmpty) break;

      final optionTiles = find.byWidgetPredicate(
        (w) =>
            w is GestureDetector &&
            w.key != null &&
            w.key.toString().contains('option_tile_'),
      );

      if (optionTiles.evaluate().isEmpty) {
        await tester.pumpAndSettle(const Duration(seconds: 3));
        iterations++;
        continue;
      }

      await tester.tap(optionTiles.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final nextBtn = find.byKey(const Key('quiz_next_btn'));
      if (nextBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(nextBtn);
        await tester.pumpAndSettle();
        await tester.tap(nextBtn);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      iterations++;
    }

    // Result screen assertions.
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.text('Résultats'), findsOneWidget,
        reason: 'Result screen must appear after answering all questions');
    expect(find.textContaining(' / '), findsWidgets,
        reason: 'A score like "3 / 5" must be visible');

    // Replay: verify quiz restarts.
    await tester.ensureVisible(find.byKey(const Key('result_replay_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('result_replay_btn')));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.textContaining('Question'), findsWidgets,
        reason: 'Replay must restart the quiz session');

    // After replay, navigate home using the quiz header back action
    // (calls context.go('/') in QuizScreen).
    // Answer one more question to reach result, then tap the home button.
    // This avoids needing to find the back icon (ForUI uses Lucide SVG icons).
    //
    // Simpler: tap the back button semantics. ForUI FHeaderAction.back does not
    // set semanticsLabel by default, but FTappable does provide semantics via
    // the icon Builder. We use Navigator pop directly since after pushReplacement
    // the quiz is at the top of the go_router stack.
    //
    // The safest path: answer one question → reach result again → tap home btn.
    {
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final opts = find.byWidgetPredicate(
        (w) =>
            w is GestureDetector &&
            w.key != null &&
            w.key.toString().contains('option_tile_'),
      );
      if (opts.evaluate().isNotEmpty) {
        await tester.tap(opts.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        // Now either next question or see results
        int inner = 0;
        while (inner < 15) {
          if (find.text('Résultats').evaluate().isNotEmpty) break;
          final nb = find.byKey(const Key('quiz_next_btn'));
          if (nb.evaluate().isNotEmpty) {
            await tester.ensureVisible(nb);
            await tester.pumpAndSettle();
            await tester.tap(nb);
            await tester.pumpAndSettle(const Duration(seconds: 3));
            if (find.text('Résultats').evaluate().isNotEmpty) break;
          }
          final o2 = find.byWidgetPredicate(
            (w) =>
                w is GestureDetector &&
                w.key != null &&
                w.key.toString().contains('option_tile_'),
          );
          if (o2.evaluate().isNotEmpty) {
            await tester.tap(o2.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));
          }
          inner++;
        }
      }
    }
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Navigate home via the result home button.
    final homeFromResult = find.byKey(const Key('result_home_btn'));
    if (homeFromResult.evaluate().isNotEmpty) {
      await tester.ensureVisible(homeFromResult);
      await tester.pumpAndSettle();
      await tester.tap(homeFromResult);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    // Confirm we're back at home (FR).
    expect(find.byKey(const Key('home_start_btn')), findsOneWidget);

    // ╔══════════════════════════════════════════════════════════════════════╗
    // ║  SCENARIO 2: Language switch EN ↔ FR                                ║
    // ╚══════════════════════════════════════════════════════════════════════╝

    await _tap(tester, const Key('home_settings_btn'));
    expect(find.text('Paramètres'), findsOneWidget);

    // Switch to EN.
    await _tap(tester, const Key('settings_lang_en'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Back to home using go_router pop semantics.
    await _goBack(tester, settle: const Duration(seconds: 3));

    // If still on settings (back failed), try the home route directly.
    if (find.byKey(const Key('home_start_btn')).evaluate().isEmpty) {
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    expect(find.text('Start Quiz'), findsOneWidget,
        reason: 'Switching to EN must change home_start label');

    // Switch back to French.
    await _tap(tester, const Key('home_settings_btn'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _tap(tester, const Key('settings_lang_fr'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _goBack(tester, settle: const Duration(seconds: 2));

    expect(find.text('Commencer le Quiz'), findsOneWidget,
        reason: 'Switching back to FR must restore French labels');

    // ╔══════════════════════════════════════════════════════════════════════╗
    // ║  SCENARIO 3: About screen disclaimer                                ║
    // ╚══════════════════════════════════════════════════════════════════════╝

    await _tap(tester, const Key('home_about_btn'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('À propos'), findsWidgets);

    await tester.dragUntilVisible(
      find.text('Avertissement Important'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    expect(find.text('Avertissement Important'), findsOneWidget,
        reason: 'Disclaimer title must be visible on About screen');
    expect(
      find.textContaining('outil éducatif'),
      findsOneWidget,
      reason: 'Disclaimer body must mention "outil éducatif"',
    );
  });
}
