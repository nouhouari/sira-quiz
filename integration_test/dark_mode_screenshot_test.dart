// ignore_for_file: avoid_print
//
// Dark-mode screenshot capture — switches app to dark theme and captures home.
// Run via:
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/dark_mode_screenshot_test.dart \
//     -d RR8W900EWQP

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sira_quiz/main.dart' as app;

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
  if (f.evaluate().isNotEmpty) {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
  }
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
  final NavigatorState nav =
      tester.state<NavigatorState>(find.byType(Navigator).first);
  if (nav.canPop()) {
    nav.pop();
    await tester.pumpAndSettle(settle);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dark mode screenshot', (WidgetTester tester) async {
    await binding.convertFlutterSurfaceToImage();

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 6));

    // Open Settings and switch to dark theme.
    await _tapKey(tester, const Key('home_settings_btn'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Tap "Sombre" (dark theme tile).
    final darkTile = find.text('Sombre');
    if (darkTile.evaluate().isNotEmpty) {
      await tester.tap(darkTile.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // Go back to home.
    await _goBack(tester, settle: const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // ── 10 Home Dark ─────────────────────────────────────────────────────────
    await _shot(binding, tester, '10-home-dark');

    // Restore to system theme.
    await _tapKey(tester, const Key('home_settings_btn'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final sysTile = find.text('Système');
    if (sysTile.evaluate().isNotEmpty) {
      await tester.tap(sysTile.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
    await _goBack(tester);
  });
}
