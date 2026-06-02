import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, Questions, QuestionOptions, Settings, QuestionProgress])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(questionProgress);
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'sira_quiz');
  }

  // ── Categories ──────────────────────────────────────────────────────────────

  Future<List<Category>> getAllCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .get();

  // ── Questions ────────────────────────────────────────────────────────────────

  Future<int> countQuestions(String categorySlug, int difficulty) async {
    final count = countAll(
      filter: questions.categorySlug.equals(categorySlug) &
          questions.difficulty.equals(difficulty),
    );
    final result = await (selectOnly(questions)..addColumns([count])).getSingle();
    return result.read(count) ?? 0;
  }

  Future<List<Question>> getQuestions(
    String categorySlug,
    int difficulty, {
    int limit = 10,
  }) async {
    final query = select(questions)
      ..where(
        (q) =>
            q.categorySlug.equals(categorySlug) &
            q.difficulty.equals(difficulty),
      );
    final rows = await query.get();
    rows.shuffle();
    return rows.take(limit).toList();
  }

  /// Like [getQuestions] but excludes questions already mastered (answered
  /// correctly at least once). Shuffles the remaining rows before truncating.
  ///
  /// B1: exclusion is via a correlated SQL subquery so the mastered set is
  /// never loaded into Dart and the 999 bound-variable SQLite ceiling cannot
  /// be hit regardless of how many questions a user has mastered.
  Future<List<Question>> getUnansweredQuestions(
    String categorySlug,
    int difficulty, {
    int limit = 10,
  }) async {
    final query = select(questions)
      ..where(
        (q) =>
            q.categorySlug.equals(categorySlug) &
            q.difficulty.equals(difficulty) &
            q.id.isNotInQuery(_masteredIdsSubquery()),
      );
    final rows = await query.get();
    rows.shuffle();
    return rows.take(limit).toList();
  }

  /// Count of questions in this category+difficulty that are NOT yet mastered.
  ///
  /// B1: uses the same [_masteredIdsSubquery] as [getUnansweredQuestions] so
  /// the displayed "remaining" count always matches the questions actually served.
  Future<int> countRemaining(String categorySlug, int difficulty) async {
    final count = countAll(
      filter: questions.categorySlug.equals(categorySlug) &
          questions.difficulty.equals(difficulty) &
          questions.id.isNotInQuery(_masteredIdsSubquery()),
    );
    final result =
        await (selectOnly(questions)..addColumns([count])).getSingle();
    return result.read(count) ?? 0;
  }

  /// Shared subquery: returns the set of question ids that have been answered
  /// correctly at least once.  Used by both [getUnansweredQuestions] and
  /// [countRemaining] to guarantee they always exclude the identical set.
  JoinedSelectStatement _masteredIdsSubquery() {
    return selectOnly(questionProgress)
      ..addColumns([questionProgress.questionId])
      ..where(questionProgress.answeredCorrectly.equals(true));
  }

  /// Records a question answer.
  /// - Correct answers: upsert to mark as mastered (never loses the correct flag).
  /// - Wrong answers: insert-or-ignore so a previously-correct row is never
  ///   downgraded.
  Future<void> recordAnswer(int questionId, bool correct) async {
    if (correct) {
      await into(questionProgress).insertOnConflictUpdate(
        QuestionProgressCompanion.insert(
          questionId: Value(questionId),
          answeredCorrectly: true,
          answeredAt: DateTime.now(),
        ),
      );
    } else {
      await into(questionProgress).insert(
        QuestionProgressCompanion.insert(
          questionId: Value(questionId),
          answeredCorrectly: false,
          answeredAt: DateTime.now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  /// Deletes progress for all questions in a specific category+difficulty level.
  Future<void> resetProgressForLevel(
      String categorySlug, int difficulty) async {
    // Collect question ids for this level.
    final levelIds = await (selectOnly(questions)
          ..addColumns([questions.id])
          ..where(questions.categorySlug.equals(categorySlug) &
              questions.difficulty.equals(difficulty)))
        .get()
        .then((rows) => rows.map((r) => r.read(questions.id)!).toList());

    if (levelIds.isEmpty) return;
    await (delete(questionProgress)
          ..where((p) => p.questionId.isIn(levelIds)))
        .go();
  }

  /// Deletes all progress records (full reset).
  Future<void> resetAllProgress() => delete(questionProgress).go();

  Future<List<QuestionOption>> getOptionsForQuestion(int questionId) =>
      (select(questionOptions)
            ..where((o) => o.questionId.equals(questionId))
            ..orderBy([(o) => OrderingTerm.asc(o.sortOrder)]))
          .get();

  /// Batched variant — fetches options for multiple questions in one query.
  /// Results are ordered by [sortOrder] within each question.
  Future<List<QuestionOption>> getOptionsForQuestions(List<int> ids) =>
      (select(questionOptions)
            ..where((o) => o.questionId.isIn(ids))
            ..orderBy([(o) => OrderingTerm.asc(o.sortOrder)]))
          .get();

  // ── Settings ─────────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final row = await (select(settings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(settings).insertOnConflictUpdate(
      SettingsCompanion(key: Value(key), value: Value(value)),
    );
  }

  // ── Seeding ──────────────────────────────────────────────────────────────────

  Future<bool> isCategoriesEmpty() async {
    // Use a COUNT query so this never throws "Too many elements" when
    // the DB already has multiple category rows (getSingleOrNull would
    // throw if there is more than one row).
    final count = countAll();
    final result =
        await (selectOnly(categories)..addColumns([count])).getSingle();
    return (result.read(count) ?? 0) == 0;
  }

  Future<void> seedAll({
    required List<CategoriesCompanion> cats,
    required List<QuestionsCompanion> qs,
    required List<QuestionOptionsCompanion> opts,
  }) async {
    // Single batch inside a transaction — three separate batch() calls were
    // already transactional but each opened its own statement group. One call
    // is simpler and slightly more efficient.
    await transaction(() async {
      await batch((b) {
        b.insertAll(categories, cats, mode: InsertMode.insertOrIgnore);
        b.insertAll(questions, qs, mode: InsertMode.insertOrIgnore);
        b.insertAll(questionOptions, opts, mode: InsertMode.insertOrIgnore);
      });
    });
  }

  /// Idempotent upsert used by the content-version re-seed path.
  ///
  /// Updates all text/metadata fields on existing rows and inserts new ones.
  /// Crucially, this does NOT touch [QuestionProgress] — user progress is
  /// keyed by stable question id and must survive content updates.
  Future<void> seedAllUpsert({
    required List<CategoriesCompanion> cats,
    required List<QuestionsCompanion> qs,
    required List<QuestionOptionsCompanion> opts,
  }) async {
    await transaction(() async {
      await batch((b) {
        b.insertAll(categories, cats, mode: InsertMode.insertOrReplace);
        b.insertAll(questions, qs, mode: InsertMode.insertOrReplace);
        b.insertAll(questionOptions, opts, mode: InsertMode.insertOrReplace);
      });
    });
  }

  /// Prunes rows in the DB that are no longer present in the seed.
  ///
  /// Called after [seedAllUpsert] on every content-version upgrade.  The prune
  /// removes categories, questions, question options, and orphaned progress
  /// rows whose ids / slugs are absent from the current seed data.  Rows that
  /// ARE still in the seed are never touched.
  ///
  /// **Delete order matters** — steps 1 and 2 must run BEFORE steps 3 and 4:
  ///   1. Delete questions whose categorySlug is no longer valid.
  ///   2. Delete categories whose slug is no longer valid.
  ///   3. Delete question_options WHERE question_id NOT IN (SELECT id FROM questions).
  ///   4. Delete question_progress WHERE question_id NOT IN (SELECT id FROM questions).
  ///
  /// Steps 3 and 4 use a subquery against the live `questions` table.  Because
  /// [seedAllUpsert] never deletes rows, the removed questions are still in the
  /// `questions` table until step 1 runs.  If steps 3/4 ran first, their
  /// subquery would match nothing and orphaned option/progress rows would be
  /// left permanently.
  ///
  /// Variable-limit strategy: SQLite's 999-bound-variable ceiling is avoided by
  /// using NOT-IN only on the small, bounded set of valid category slugs
  /// (currently ≤ ~20).  For question options and question-progress the approach
  /// uses a correlated "NOT IN" subquery against the live questions table —
  /// this works entirely on the DB side with no Dart-side variable binding, so
  /// the 999 ceiling is never approached regardless of how many questions exist.
  ///
  /// QuestionProgress rows for KEPT questions are never touched: only rows
  /// whose questionId no longer appears in the questions table after step 1
  /// are removed in step 4.
  Future<void> pruneRemovedSeedRows({
    required List<CategoriesCompanion> cats,
    required List<QuestionsCompanion> qs,
    required List<QuestionOptionsCompanion> opts,
  }) async {
    // Build the valid slug set from the seed companions (bounded, small — ≤ ~20).
    // Question ids are NOT bound into Dart variables; steps 3/4 use correlated
    // subqueries against the questions table instead, avoiding the SQLite
    // 999-bound-variable ceiling.
    final validSlugs = cats.map((c) => c.slug.value).toList();

    await transaction(() async {
      // 1. Prune removed questions first: delete questions whose categorySlug is
      //    not in the valid-slug set (bounded, currently ≤ ~20 slugs).
      //    This must run BEFORE steps 3/4 so that the `questions` table reflects
      //    only the current seed when the subqueries in those steps execute.
      await (delete(questions)
            ..where((q) => q.categorySlug.isNotIn(validSlugs)))
          .go();

      // 2. Prune removed categories: NOT IN on validSlugs (small set, safe).
      await (delete(categories)
            ..where((c) => c.slug.isNotIn(validSlugs)))
          .go();

      // 3. Prune orphaned question options: delete options whose question_id no
      //    longer appears in the questions table.  Because step 1 already removed
      //    the questions for deleted categories, this subquery now correctly
      //    identifies all orphaned option rows.
      await customStatement(
        'DELETE FROM question_options '
        'WHERE question_id NOT IN (SELECT id FROM questions)',
      );

      // 4. Prune orphaned QuestionProgress rows: same subquery pattern — delete
      //    progress for question ids that no longer exist in the questions table
      //    (removed by step 1).  This ONLY removes progress for removed questions;
      //    all kept progress (e.g. a user who mastered birth_youth questions)
      //    is untouched because those question ids are still in the table.
      await customStatement(
        'DELETE FROM question_progress '
        'WHERE question_id NOT IN (SELECT id FROM questions)',
      );
    });
  }
}
