// ignore_for_file: avoid_print
//
// Unit tests for progress-persistence features (Phase B).
//
// These tests run in-process over an in-memory Drift DB (NativeDatabase.memory())
// — no device required, no file I/O.
//
// All tests in this file exercise AppDatabase / QuizRepository directly and
// would FAIL on the pre-feature code for the reasons noted inline.
//
// Run:
//   flutter test test/progress_repository_test.dart

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sira_quiz/data/db/app_database.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AppDatabase _openMemoryDb() => AppDatabase(NativeDatabase.memory());

/// Seeds two categories with questions so cross-level isolation can be tested:
///   - cat_a / beginner  → Q1(id=1), Q2(id=2)
///   - cat_a / intermediate → Q3(id=3)
///   - cat_b / beginner  → Q4(id=4)
///
/// Each question has exactly 2 options:
///   odd id  = correct option  (sortOrder=1)
///   even id = wrong option    (sortOrder=2)
///
/// Options are offset by question id × 10 so ids stay globally unique:
///   Q1 → opts 101 (correct), 102 (wrong)
///   Q2 → opts 201 (correct), 202 (wrong)
///   Q3 → opts 301 (correct), 302 (wrong)
///   Q4 → opts 401 (correct), 402 (wrong)
Future<void> _seedFixture(AppDatabase db) async {
  await db.seedAll(
    cats: [
      CategoriesCompanion.insert(
        slug: 'cat_a',
        iconKey: 'star',
        nameFr: 'Catégorie A',
        nameEn: 'Category A',
        sortOrder: const Value(1),
      ),
      CategoriesCompanion.insert(
        slug: 'cat_b',
        iconKey: 'circle',
        nameFr: 'Catégorie B',
        nameEn: 'Category B',
        sortOrder: const Value(2),
      ),
    ],
    qs: [
      _question(id: 1, slug: 'cat_a', diff: 1),
      _question(id: 2, slug: 'cat_a', diff: 1),
      _question(id: 3, slug: 'cat_a', diff: 2),
      _question(id: 4, slug: 'cat_b', diff: 1),
    ],
    opts: [
      _option(id: 101, questionId: 1, correct: true),
      _option(id: 102, questionId: 1, correct: false),
      _option(id: 201, questionId: 2, correct: true),
      _option(id: 202, questionId: 2, correct: false),
      _option(id: 301, questionId: 3, correct: true),
      _option(id: 302, questionId: 3, correct: false),
      _option(id: 401, questionId: 4, correct: true),
      _option(id: 402, questionId: 4, correct: false),
    ],
  );
}

QuestionsCompanion _question({
  required int id,
  required String slug,
  required int diff,
}) =>
    QuestionsCompanion.insert(
      id: Value(id),
      categorySlug: slug,
      difficulty: diff,
      type: 'mcq',
      promptFr: 'Q$id FR',
      promptEn: 'Q$id EN',
      explanationFr: 'Expl $id FR',
      explanationEn: 'Expl $id EN',
      sourceArabic: const Value(null),
      sourceReference: 'Ref $id',
    );

QuestionOptionsCompanion _option({
  required int id,
  required int questionId,
  required bool correct,
}) =>
    QuestionOptionsCompanion.insert(
      id: Value(id),
      questionId: questionId,
      textFr: correct ? 'Correct FR' : 'Faux FR',
      textEn: correct ? 'Correct EN' : 'Wrong EN',
      isCorrect: Value(correct),
      sortOrder: Value(correct ? 1 : 2),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Progress persistence — AppDatabase / QuizRepository', () {
    late AppDatabase db;

    setUp(() async {
      db = _openMemoryDb();
      await _seedFixture(db);
    });

    tearDown(() async {
      await db.close();
    });

    // ── 1. Correct answer excludes the question; wrong answer does not ─────────
    //
    // Pre-feature: getUnansweredQuestions always returned ALL questions because
    // the question_progress table did not exist.
    // Post-feature: recordAnswer(q, true) causes the SQL NOT IN subquery to
    // exclude that question id.

    test('recordAnswer correct → getUnansweredQuestions excludes the question',
        () async {
      await db.recordAnswer(1, true); // Q1 mastered

      final remaining =
          await db.getUnansweredQuestions('cat_a', 1); // beginner
      final ids = remaining.map((q) => q.id).toList();

      expect(ids, isNot(contains(1)),
          reason: 'Q1 answered correctly must be excluded from future sessions');
      expect(ids, contains(2),
          reason: 'Q2 (not yet answered) must still be returned');
    });

    test('recordAnswer wrong → getUnansweredQuestions INCLUDES the question',
        () async {
      await db.recordAnswer(1, false); // Q1 answered wrong

      final remaining = await db.getUnansweredQuestions('cat_a', 1);
      final ids = remaining.map((q) => q.id).toList();

      expect(ids, contains(1),
          reason:
              'A wrong answer must not exclude the question — only correct answers do');
    });

    // ── 2. No-downgrade: correct answer is permanent ──────────────────────────
    //
    // Pre-feature: no downgrade protection (table did not exist).
    // Post-feature: recordAnswer uses insertOrIgnore for wrong answers so a
    // previously-correct row can never be overwritten.

    test(
        'no-downgrade: record correct then wrong → question stays excluded (mastered)',
        () async {
      await db.recordAnswer(1, true); // mastered
      await db.recordAnswer(1, false); // attempt to downgrade

      final remaining = await db.getUnansweredQuestions('cat_a', 1);
      final ids = remaining.map((q) => q.id).toList();

      expect(ids, isNot(contains(1)),
          reason:
              'A previously correct answer must never be downgraded to wrong — '
              'insertOrIgnore on wrong must leave the correct row intact');
    });

    // ── 3. countRemaining == len(getUnansweredQuestions) for all states ────────
    //
    // These two queries must use the identical SQL subquery so their results
    // never diverge (the displayed count on the difficulty screen matches the
    // actual session).
    //
    // Pre-feature: countRemaining equaled countTotal (no mastery filtering).

    test('countRemaining matches getUnansweredQuestions length — no progress',
        () async {
      final count = await db.countRemaining('cat_a', 1);
      final questions = await db.getUnansweredQuestions('cat_a', 1);

      expect(count, questions.length,
          reason:
              'countRemaining and getUnansweredQuestions must always agree '
              '(no progress state)');
    });

    test(
        'countRemaining matches getUnansweredQuestions length — one question mastered',
        () async {
      await db.recordAnswer(1, true); // Q1 mastered

      final count = await db.countRemaining('cat_a', 1);
      final questions = await db.getUnansweredQuestions('cat_a', 1);

      expect(count, questions.length,
          reason:
              'countRemaining and getUnansweredQuestions must agree after one mastery');
      expect(count, 1, reason: '2 beginner questions, 1 mastered → 1 remaining');
    });

    test(
        'countRemaining matches getUnansweredQuestions length — all questions mastered',
        () async {
      await db.recordAnswer(1, true);
      await db.recordAnswer(2, true);

      final count = await db.countRemaining('cat_a', 1);
      final questions = await db.getUnansweredQuestions('cat_a', 1);

      expect(count, questions.length,
          reason:
              'countRemaining and getUnansweredQuestions must agree when all are mastered');
      expect(count, 0,
          reason: 'All beginner questions mastered → 0 remaining');
    });

    // ── 4. allMastered vs noQuestions distinction ──────────────────────────────
    //
    // QuizError.allMastered: total > 0 AND remaining == 0.
    // QuizError.noQuestions: total == 0.
    //
    // Pre-feature: countTotal and countRemaining both always returned the same
    // value (no mastery tracking), so startSession could never produce the
    // allMastered branch.

    test(
        'allMastered scenario: level with content all-mastered → remaining=0, total>0',
        () async {
      // Master both beginner questions.
      await db.recordAnswer(1, true);
      await db.recordAnswer(2, true);

      final total = await db.countQuestions('cat_a', 1);
      final remaining = await db.countRemaining('cat_a', 1);

      expect(total, greaterThan(0),
          reason: 'A level with seeded questions must have total > 0');
      expect(remaining, 0,
          reason:
              'After mastering all questions remaining must be 0 (allMastered trigger)');
    });

    test(
        'noQuestions scenario: non-existent level → total=0, remaining=0',
        () async {
      final total = await db.countQuestions('nonexistent', 1);
      final remaining = await db.countRemaining('nonexistent', 1);

      expect(total, 0, reason: 'Non-existent slug must yield total=0');
      expect(remaining, 0, reason: 'Non-existent slug must yield remaining=0');
    });

    // ── 5. resetProgressForLevel — level isolation ────────────────────────────
    //
    // Pre-feature: reset did not exist (table did not exist).
    // Post-feature: deletes progress rows only for the specified level; other
    // levels' mastered questions are untouched.

    test(
        'resetProgressForLevel re-includes that level but NOT another level\'s mastered questions',
        () async {
      // Master Q1 (cat_a/beginner), Q3 (cat_a/intermediate), Q4 (cat_b/beginner).
      await db.recordAnswer(1, true);
      await db.recordAnswer(3, true);
      await db.recordAnswer(4, true);

      // Reset only cat_a / beginner.
      await db.resetProgressForLevel('cat_a', 1);

      // cat_a/beginner: Q1 must be back in the unanswered set.
      final catABeginner = await db.getUnansweredQuestions('cat_a', 1);
      expect(catABeginner.map((q) => q.id), contains(1),
          reason:
              'Q1 must be re-included after resetting cat_a/beginner progress');

      // cat_a/intermediate: Q3 must still be excluded.
      final catAInter = await db.getUnansweredQuestions('cat_a', 2);
      expect(catAInter.map((q) => q.id), isNot(contains(3)),
          reason:
              'Q3 (different difficulty) must remain mastered after partial reset');

      // cat_b/beginner: Q4 must still be excluded.
      final catBBeginner = await db.getUnansweredQuestions('cat_b', 1);
      expect(catBBeginner.map((q) => q.id), isNot(contains(4)),
          reason:
              'Q4 (different category) must remain mastered after partial reset');
    });

    // ── 6. resetAllProgress — wipes everything ────────────────────────────────

    test('resetAllProgress clears every mastered question across all levels',
        () async {
      await db.recordAnswer(1, true);
      await db.recordAnswer(3, true);
      await db.recordAnswer(4, true);

      await db.resetAllProgress();

      // All questions should now be back in the unanswered set.
      final catABeginner = await db.getUnansweredQuestions('cat_a', 1);
      final catAInter = await db.getUnansweredQuestions('cat_a', 2);
      final catBBeginner = await db.getUnansweredQuestions('cat_b', 1);

      expect(catABeginner.map((q) => q.id), contains(1),
          reason: 'Q1 must be back after resetAllProgress');
      expect(catAInter.map((q) => q.id), contains(3),
          reason: 'Q3 must be back after resetAllProgress');
      expect(catBBeginner.map((q) => q.id), contains(4),
          reason: 'Q4 must be back after resetAllProgress');
    });

    // ── 7. isCategoriesEmpty guard ────────────────────────────────────────────
    //
    // The old isCategoriesEmpty used getSingleOrNull() which THROWS a
    // StateError("too many elements") when the query returns more than one row —
    // i.e. on every launch after the first seed.  The fix uses a COUNT query.
    //
    // This test seeds ≥2 categories (done in _seedFixture: cat_a and cat_b)
    // then asserts both that the result is `false` AND that no exception is thrown.
    //
    // On the old implementation this test would throw:
    //   StateError: Bad state: too many elements

    test(
        'isCategoriesEmpty — returns false AND does not throw when ≥2 categories exist',
        () async {
      // Fixture already has cat_a and cat_b (2 categories).
      // If getSingleOrNull is still in use this line throws StateError.
      final bool result = await db.isCategoriesEmpty();

      expect(result, isFalse,
          reason:
              'isCategoriesEmpty must return false when categories exist '
              '(old getSingleOrNull implementation would throw here)');
    });

    test('isCategoriesEmpty — returns true on a freshly created empty DB',
        () async {
      final emptyDb = _openMemoryDb();
      addTearDown(emptyDb.close);
      // No seedAll called — categories table is empty.
      final result = await emptyDb.isCategoriesEmpty();
      expect(result, isTrue,
          reason: 'isCategoriesEmpty must return true on an empty DB');
    });

    // ── 8. Migration: fresh schema has a working question_progress table ──────
    //
    // Verifying that AppDatabase(NativeDatabase.memory()) (schema v2) creates the
    // question_progress table and that INSERT + SELECT work.
    //
    // On a schema where question_progress was missing (v1 only) the recordAnswer
    // call would throw "no such table: question_progress".

    test(
        'migration: fresh AppDatabase (v2) has a functional question_progress table',
        () async {
      // A freshly opened memory DB should have run onCreate → createAll.
      // Insert a progress row and read it back to confirm the table exists.
      expect(
        () async => db.recordAnswer(1, true),
        returnsNormally,
        reason:
            'recordAnswer must not throw — question_progress table must exist '
            'in schema v2 (would throw "no such table" if migration was missing)',
      );

      await db.recordAnswer(1, true);
      final remaining = await db.getUnansweredQuestions('cat_a', 1);
      expect(remaining.map((q) => q.id), isNot(contains(1)),
          reason:
              'After recording a correct answer the question must be excluded '
              '(confirms the table is writable and the NOT IN subquery works)');
    });
  });
}
