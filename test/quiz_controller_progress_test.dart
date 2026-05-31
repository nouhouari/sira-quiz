// ignore_for_file: avoid_print
//
// Controller-level progress tests (Phase B).
//
// These tests extend quiz_controller_test.dart's fixture and patterns to verify:
//   1. selectOption(correct) fires recordAnswer and the question becomes mastered.
//   2. resetLevelAndRestart awaits the pending record before resetting (TOCTOU guard).
//
// Run:
//   flutter test test/quiz_controller_progress_test.dart

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sira_quiz/data/db/app_database.dart';
import 'package:sira_quiz/data/repositories/quiz_repository.dart';
import 'package:sira_quiz/domain/models/difficulty.dart';
import 'package:sira_quiz/features/quiz/quiz_controller.dart';

// ---------------------------------------------------------------------------
// Helpers (same fixture as quiz_controller_test.dart)
// ---------------------------------------------------------------------------

AppDatabase _openMemoryDb() => AppDatabase(NativeDatabase.memory());

/// Identical fixture to quiz_controller_test.dart:
///   test_cat / beginner / Q1-Q3
///   Correct options: 1, 5, 9 (sort_order=1 in each group)
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
      // Q1: id 1 correct, id 2 wrong
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
      // Q2: id 3 wrong, id 4 wrong, id 5 correct
      QuestionOptionsCompanion.insert(
        id: const Value(3),
        questionId: 2,
        textFr: 'Faux 2a FR',
        textEn: 'Wrong 2a EN',
        isCorrect: const Value(false),
        sortOrder: const Value(2),
      ),
      QuestionOptionsCompanion.insert(
        id: const Value(4),
        questionId: 2,
        textFr: 'Faux 2b FR',
        textEn: 'Wrong 2b EN',
        isCorrect: const Value(false),
        sortOrder: const Value(3),
      ),
      QuestionOptionsCompanion.insert(
        id: const Value(5),
        questionId: 2,
        textFr: 'Correct 2 FR',
        textEn: 'Correct 2 EN',
        isCorrect: const Value(true),
        sortOrder: const Value(1),
      ),
      // Q3: id 6,7,8 wrong, id 9 correct
      QuestionOptionsCompanion.insert(
        id: const Value(6),
        questionId: 3,
        textFr: 'Faux 3a FR',
        textEn: 'Wrong 3a EN',
        isCorrect: const Value(false),
        sortOrder: const Value(2),
      ),
      QuestionOptionsCompanion.insert(
        id: const Value(7),
        questionId: 3,
        textFr: 'Faux 3b FR',
        textEn: 'Wrong 3b EN',
        isCorrect: const Value(false),
        sortOrder: const Value(3),
      ),
      QuestionOptionsCompanion.insert(
        id: const Value(8),
        questionId: 3,
        textFr: 'Faux 3c FR',
        textEn: 'Wrong 3c EN',
        isCorrect: const Value(false),
        sortOrder: const Value(4),
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

/// Silent SoundNotifier — avoids touching HapticFeedback in tests.
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('QuizNotifier — progress persistence (Phase B)', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      db = _openMemoryDb();
      await _seedFixture(db);
      container = _makeContainer(db);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> startSession() => container
        .read(quizNotifierProvider.notifier)
        .startSession('test_cat', Difficulty.beginner);

    // ── 1. selectOption(correct) causes the question to become mastered ───────
    //
    // Pre-feature: selectOption only updated UI state; no DB write happened.
    //   → getUnansweredQuestions would still return the question in the next
    //     session (no exclusion).
    // Post-feature: selectOption fires _pendingRecord which calls
    //   repo.recordAnswer(question.id, true).  After the future resolves the
    //   question_progress row exists and getUnansweredQuestions excludes the id.
    //
    // Assertion that fails on old code:
    //   expect(masteredCount, 0)  (old) vs expect(masteredCount, 1) (new)

    test(
        'selectOption(correct) → question is recorded as mastered in the DB',
        () async {
      await startSession();

      final q1 = container.read(quizNotifierProvider).currentQuestion!;
      final correctId = q1.options.firstWhere((o) => o.isCorrect).id;

      // Select the correct answer — fires _pendingRecord.
      container.read(quizNotifierProvider.notifier).selectOption(correctId);

      // Drain the microtask queue so the fire-and-forget DB write completes.
      // We use a small pump delay rather than accessing the private _pendingRecord.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify via the DB: q1 must now be excluded from future sessions.
      final remaining =
          await db.getUnansweredQuestions('test_cat', 1);
      final remainingIds = remaining.map((q) => q.id).toList();

      expect(
        remainingIds,
        isNot(contains(q1.id)),
        reason:
            'After selecting the CORRECT option the question must be recorded as '
            'mastered — getUnansweredQuestions must exclude it. '
            'On the pre-feature code no DB write happened so the question would '
            'still appear here.',
      );
    });

    test(
        'selectOption(wrong) → question is NOT recorded as mastered in the DB',
        () async {
      await startSession();

      final q1 = container.read(quizNotifierProvider).currentQuestion!;
      final wrongId = q1.options.firstWhere((o) => !o.isCorrect).id;

      container.read(quizNotifierProvider.notifier).selectOption(wrongId);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final remaining =
          await db.getUnansweredQuestions('test_cat', 1);
      final remainingIds = remaining.map((q) => q.id).toList();

      expect(
        remainingIds,
        contains(q1.id),
        reason:
            'A wrong answer must NOT cause the question to be excluded — '
            'only correct answers produce mastery.',
      );
    });

    // ── 2. resetLevelAndRestart TOCTOU guard ──────────────────────────────────
    //
    // Pre-feature: resetLevelAndRestart did not exist.  If it had existed without
    // the await _pendingRecord guard, the sequence would be:
    //   1. selectOption fires _pendingRecord (async, not yet awaited)
    //   2. resetLevelAndRestart calls resetProgressForLevel (deletes rows)
    //   3. _pendingRecord resolves → re-inserts the mastered row (TOCTOU)
    //   4. countRemaining returns 0 even after the reset
    //
    // Post-feature: resetLevelAndRestart awaits _pendingRecord before
    // resetting, so no late re-insert can happen.
    //
    // Assertion that fails on the TOCTOU-vulnerable implementation:
    //   expect(masteredAfterReset, 0)  (new, after reset)
    //   vs actual == 1 (if late re-insert landed)

    test(
        'resetLevelAndRestart — awaits pendingRecord before reset (TOCTOU guard)',
        () async {
      await startSession();

      final q1 = container.read(quizNotifierProvider).currentQuestion!;
      final correctId = q1.options.firstWhere((o) => o.isCorrect).id;

      // Select correct answer — starts _pendingRecord (fire-and-forget).
      container.read(quizNotifierProvider.notifier).selectOption(correctId);

      // Immediately call resetLevelAndRestart WITHOUT yielding to the event loop.
      // On a TOCTOU-vulnerable impl the _pendingRecord would finish AFTER reset.
      // With the B2 fix, resetLevelAndRestart awaits _pendingRecord first.
      await container
          .read(quizNotifierProvider.notifier)
          .resetLevelAndRestart('test_cat', Difficulty.beginner);

      // After reset: countRemaining must equal the total (nothing mastered).
      final remaining = await db.countRemaining('test_cat', 1);
      final total = await db.countQuestions('test_cat', 1);

      expect(
        remaining,
        total,
        reason:
            'After resetLevelAndRestart all questions must be unmastered '
            '(remaining == total). A TOCTOU-vulnerable impl would have remaining < total '
            'because the fire-and-forget recordAnswer re-inserted a mastered row after the reset.',
      );
    });
  });
}
