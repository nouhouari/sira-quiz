// ignore_for_file: avoid_print
//
// Bug M-2 verification screenshot — categories bottom
// ─────────────────────────────────────────────────────────────────────────────
// Navigates to the Categories screen, scrolls to the very bottom, and captures
// a screenshot showing the last card (quran_message) fully visible above the
// system nav bar.  Run via:
//
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/categories_bottom_screenshot_test.dart \
//     -d RR8W900EWQP

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sira_quiz/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('categories bottom screenshot — M-2 fix verification',
      (WidgetTester tester) async {
    await binding.convertFlutterSurfaceToImage();

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 6));

    // Navigate to categories from home.
    await tester.tap(find.byKey(const Key('home_start_btn')));
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Scroll to the bottom of the categories list.
    await tester.fling(
      find.byType(ListView),
      const Offset(0, -3000),
      2000,
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Capture: last card (quran_message) must be fully visible above the nav bar.
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    await binding.takeScreenshot('15-categories-bottom');
  });
}
