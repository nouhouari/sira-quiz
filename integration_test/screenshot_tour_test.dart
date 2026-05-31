// ignore_for_file: avoid_print
//
// Screenshot tour — captures every key screen on the physical Android device
// for the UI/UX gate. Run via:
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshot_tour_test.dart \
//     -d RR8W900EWQP

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
}

Future<void> _tapKey(WidgetTester tester, Key key,
    {Duration settle = const Duration(seconds: 3)}) async {
  final f = find.byKey(key);
  // Use ensureVisible only when the widget is confirmed present.
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

/// Pop the current route by invoking the semantic back button / any back-gesture.
/// ForUI uses FLucideIcons which are SVG-based; we can't match by Material icon.
/// Fall back to Navigator.pop via the back-semantics tooltip.
Future<void> _goBack(WidgetTester tester, {Duration settle = const Duration(seconds: 2)}) async {
  // Try common semantic back labels.
  for (final label in ['Back', 'Retour', 'back', 'retour']) {
    final f = find.bySemanticsLabel(label);
    if (f.evaluate().isNotEmpty) {
      await tester.tap(f.first);
      await tester.pumpAndSettle(settle);
      return;
    }
  }
  // Fallback: use the Navigator's system back.
  final NavigatorState nav =
      tester.state<NavigatorState>(find.byType(Navigator).first);
  if (nav.canPop()) {
    nav.pop();
    await tester.pumpAndSettle(settle);
  }
}

// ---------------------------------------------------------------------------
// Tour
// ---------------------------------------------------------------------------

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour', (WidgetTester tester) async {
    // On Android physical device, convert surface to image once before any shot.
    await binding.convertFlutterSurfaceToImage();

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 6));

    // ── 01 Home ────────────────────────────────────────────────────────────
    await _shot(binding, tester, '01-home');

    // ── Navigate to categories ─────────────────────────────────────────────
    await _tapKey(tester, const Key('home_start_btn'));
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // ── 02 Categories ─────────────────────────────────────────────────────
    await _shot(binding, tester, '02-categories');

    // ── Navigate to Difficulty for birth_youth ────────────────────────────
    await _tapKey(tester, const Key('category_card_birth_youth'),
        settle: const Duration(seconds: 4));

    // ── 03 Difficulty ─────────────────────────────────────────────────────
    await _shot(binding, tester, '03-difficulty');

    // ── Start quiz (Beginner) ──────────────────────────────────────────────
    await _tapText(tester, 'Débutant', settle: const Duration(seconds: 6));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // ── 04 Quiz unanswered ────────────────────────────────────────────────
    await _shot(binding, tester, '04-quiz-unanswered');

    // Select first option to reveal feedback.
    final optionTiles = find.byWidgetPredicate(
      (w) =>
          w is GestureDetector &&
          w.key != null &&
          w.key.toString().contains('option_tile_'),
    );
    expect(optionTiles.evaluate().isNotEmpty, isTrue,
        reason: 'At least one option tile must be present');
    await tester.tap(optionTiles.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ── 05 Quiz answered (feedback + source ref visible) ──────────────────
    await _shot(binding, tester, '05-quiz-answered');

    // ── Answer remaining questions to reach result ─────────────────────────
    var iterations = 0;
    const maxIterations = 15;
    while (iterations < maxIterations) {
      await tester.pumpAndSettle(const Duration(seconds: 2));
      if (find.text('Résultats').evaluate().isNotEmpty) break;

      // Tap next/see-results if visible.
      final nextBtn = find.byKey(const Key('quiz_next_btn'));
      if (nextBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(nextBtn);
        await tester.pumpAndSettle();
        await tester.tap(nextBtn);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        if (find.text('Résultats').evaluate().isNotEmpty) break;
      }

      // Tap first option on the next question.
      final opts = find.byWidgetPredicate(
        (w) =>
            w is GestureDetector &&
            w.key != null &&
            w.key.toString().contains('option_tile_'),
      );
      if (opts.evaluate().isNotEmpty) {
        await tester.tap(opts.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      iterations++;
    }

    await tester.pumpAndSettle(const Duration(seconds: 4));

    // ── 06 Result ─────────────────────────────────────────────────────────
    expect(find.text('Résultats'), findsOneWidget);
    await _shot(binding, tester, '06-result');

    // ── Navigate to Settings ───────────────────────────────────────────────
    // Go home first.
    final homeBtn = find.byKey(const Key('result_home_btn'));
    await tester.ensureVisible(homeBtn);
    await tester.pumpAndSettle();
    await tester.tap(homeBtn);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await _tapKey(tester, const Key('home_settings_btn'));

    // ── 07 Settings ───────────────────────────────────────────────────────
    await _shot(binding, tester, '07-settings');

    // ── Navigate to About ──────────────────────────────────────────────────
    // Back to home.
    await _goBack(tester);

    await _tapKey(tester, const Key('home_about_btn'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Scroll to disclaimer.
    await tester.dragUntilVisible(
      find.text('Avertissement Important'),
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    // ── 08 About (disclaimer visible) ────────────────────────────────────
    await _shot(binding, tester, '08-about');

    // ── Switch to English and capture Home ────────────────────────────────
    // Go back home.
    await _goBack(tester);

    // Open settings and switch to EN.
    await _tapKey(tester, const Key('home_settings_btn'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _tapKey(tester, const Key('settings_lang_en'),
        settle: const Duration(seconds: 3));

    // Back to home.
    await _goBack(tester, settle: const Duration(seconds: 3));

    // ── 09 Home EN ────────────────────────────────────────────────────────
    expect(find.text('Start Quiz'), findsOneWidget,
        reason: 'App must display English labels after locale switch');
    await _shot(binding, tester, '09-home-EN');

    // Restore FR locale for cleanliness.
    await _tapKey(tester, const Key('home_settings_btn'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _tapKey(tester, const Key('settings_lang_fr'),
        settle: const Duration(seconds: 2));
    await _goBack(tester);
  });
}
