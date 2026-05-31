import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sira_quiz/app.dart';
import 'package:sira_quiz/data/db/app_database.dart';
import 'package:sira_quiz/data/repositories/quiz_repository.dart';

/// A silent SoundNotifier that never touches real SharedPreferences.
class _SilentSoundNotifier extends SoundNotifier {
  @override
  Future<bool> build() async => false;
}

void main() {
  testWidgets('Home screen smoke test — renders start button', (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          soundNotifierProvider.overrideWith(() => _SilentSoundNotifier()),
        ],
        child: const SiraQuizApp(),
      ),
    );

    // Pump once to trigger async providers, then settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The Home screen must render the start button.
    expect(find.byKey(const Key('home_start_btn')), findsOneWidget);

    await db.close();
  });
}
