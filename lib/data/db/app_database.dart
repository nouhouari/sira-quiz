import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, Questions, QuestionOptions, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

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
    final result = await (select(categories)).getSingleOrNull();
    return result == null;
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
}
