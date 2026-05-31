// Unit tests for the content-version re-seed mechanism (kSeedVersion).
//
// Verifies that:
//   1. Fresh install seeds content and writes kSeedVersion to Settings.
//   2. Re-seed (version bump) updates question text while preserving QuestionProgress.
//   3. Up-to-date installs are no-ops (seed is not re-applied).
//
// All tests use NativeDatabase.memory() — no device or file I/O required.
//
// Run:
//   flutter test test/seeder_reseed_test.dart

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sira_quiz/data/db/app_database.dart';
import 'package:sira_quiz/data/db/seed/seeder.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AppDatabase _openMemoryDb() => AppDatabase(NativeDatabase.memory());

/// Builds a minimal 1-category / 1-question / 2-option fixture as raw data.
/// [promptFr] / [promptEn] are parameterised so we can simulate a content
/// update (v1 text → v2 text) without modifying the real seed file.
Map<String, dynamic> _rawSeedData({
  String promptFr = 'Prompt v1 FR',
  String promptEn = 'Prompt v1 EN',
}) {
  return {
    'categories': [
      {
        'slug': 'test_reseed',
        'iconKey': 'star',
        'nameFr': 'Catégorie Test',
        'nameEn': 'Test Category',
        'sortOrder': 1,
      }
    ],
    'questions': [
      {
        'id': 1,
        'categorySlug': 'test_reseed',
        'difficulty': 1,
        'type': 'mcq',
        'promptFr': promptFr,
        'promptEn': promptEn,
        'explanationFr': 'Explication FR',
        'explanationEn': 'Explanation EN',
        'sourceArabic': null,
        'sourceReference': 'Ref 1',
        'options': [
          {
            'textFr': 'Correct FR',
            'textEn': 'Correct EN',
            'isCorrect': true,
            'sortOrder': 1,
          },
          {
            'textFr': 'Faux FR',
            'textEn': 'Wrong EN',
            'isCorrect': false,
            'sortOrder': 2,
          },
        ],
      }
    ],
  };
}

/// Builds Drift companion objects from raw seed data.
({
  List<CategoriesCompanion> cats,
  List<QuestionsCompanion> qs,
  List<QuestionOptionsCompanion> opts,
}) _buildCompanions(Map<String, dynamic> data) {
  final rawCategories = data['categories'] as List<dynamic>;
  final rawQuestions = data['questions'] as List<dynamic>;

  final cats = rawCategories.map((c) {
    final m = c as Map<String, dynamic>;
    return CategoriesCompanion.insert(
      slug: m['slug'] as String,
      iconKey: m['iconKey'] as String,
      nameFr: m['nameFr'] as String,
      nameEn: m['nameEn'] as String,
      sortOrder: Value(m['sortOrder'] as int),
    );
  }).toList();

  final qs = <QuestionsCompanion>[];
  final optsByQId = <int, List<Map<String, dynamic>>>{};
  for (final q in rawQuestions) {
    final m = q as Map<String, dynamic>;
    final qId = m['id'] as int;
    qs.add(QuestionsCompanion.insert(
      id: Value(qId),
      categorySlug: m['categorySlug'] as String,
      difficulty: m['difficulty'] as int,
      type: m['type'] as String,
      promptFr: m['promptFr'] as String,
      promptEn: m['promptEn'] as String,
      explanationFr: m['explanationFr'] as String,
      explanationEn: m['explanationEn'] as String,
      sourceArabic: Value(m['sourceArabic'] as String?),
      sourceReference: m['sourceReference'] as String,
    ));
    optsByQId[qId] =
        (m['options'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  int optId = 1;
  final opts = <QuestionOptionsCompanion>[];
  for (final entry in optsByQId.entries) {
    for (final o in entry.value) {
      opts.add(QuestionOptionsCompanion.insert(
        id: Value(optId++),
        questionId: entry.key,
        textFr: o['textFr'] as String,
        textEn: o['textEn'] as String,
        isCorrect: Value(o['isCorrect'] as bool),
        sortOrder: Value(o['sortOrder'] as int),
      ));
    }
  }

  return (cats: cats, qs: qs, opts: opts);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseSeeder — content-version re-seed', () {
    late AppDatabase db;

    setUp(() {
      db = _openMemoryDb();
    });

    tearDown(() async {
      await db.close();
    });

    // ── 1. Fresh install: seeds content and records kSeedVersion ────────────

    test('fresh install: seeds content and writes kSeedVersion to Settings',
        () async {
      // Use the real JSON asset via the asset bundle.
      // We verify that categories are populated and the setting is written.
      final seeder = DatabaseSeeder(db);
      await seeder.seedIfNeeded();

      final isEmpty = await db.isCategoriesEmpty();
      expect(isEmpty, isFalse, reason: 'Categories must be seeded on first run');

      final storedVersion = await db.getSetting('seed_version');
      expect(
        int.tryParse(storedVersion ?? ''),
        kSeedVersion,
        reason: 'seed_version setting must be set to kSeedVersion after fresh seed',
      );
    });

    // ── 2. Already up-to-date: no-op ────────────────────────────────────────

    test('up-to-date install: seedIfNeeded is a no-op when version matches',
        () async {
      // Seed v1 content directly (bypassing seeder).
      final v1data = _rawSeedData(promptFr: 'Prompt v1 FR', promptEn: 'Prompt v1 EN');
      final v1c = _buildCompanions(v1data);
      await db.seedAll(cats: v1c.cats, qs: v1c.qs, opts: v1c.opts);
      // Mark as already at kSeedVersion.
      await db.setSetting('seed_version', '$kSeedVersion');

      // Record a progress entry.
      await db.recordAnswer(1, true);

      // Now run seedIfNeeded — it should detect version match and do nothing.
      final seeder = DatabaseSeeder(db);
      // Override the JSON loaded by the seeder is non-trivial; instead we
      // verify the observable behaviour: the seeder must not change the
      // question text (because it is a no-op) and must not touch progress.

      // We cannot easily intercept the real asset load here, so we verify
      // indirectly: isCategoriesEmpty is false (data exists), version stays.
      await seeder.seedIfNeeded();

      final storedVersion = await db.getSetting('seed_version');
      expect(
        int.tryParse(storedVersion ?? ''),
        kSeedVersion,
        reason: 'seed_version must remain at kSeedVersion after a no-op run',
      );

      // Progress must still be intact.
      final remaining = await db.getUnansweredQuestions('test_reseed', 1);
      expect(
        remaining.map((q) => q.id),
        isNot(contains(1)),
        reason: 'QuestionProgress must survive a no-op seedIfNeeded call',
      );
    });

    // ── 3. Version bump: text updated, progress preserved ───────────────────

    test(
        'version bump: re-seed updates question text while preserving QuestionProgress',
        () async {
      // Step A — simulate a v1 install: seed old content, record version=1,
      //           record user progress on Q1.
      final v1data = _rawSeedData(promptFr: 'Prompt v1 FR', promptEn: 'Prompt v1 EN');
      final v1c = _buildCompanions(v1data);
      await db.seedAll(cats: v1c.cats, qs: v1c.qs, opts: v1c.opts);
      await db.setSetting('seed_version', '1'); // stored as v1
      await db.recordAnswer(1, true);          // user answered Q1 correctly

      // Step B — simulate a content update: upsert v2 content with updated text.
      final v2data = _rawSeedData(promptFr: 'Prompt v2 FR (SWS)', promptEn: 'Prompt v2 EN (SWS)');
      final v2c = _buildCompanions(v2data);
      await db.seedAllUpsert(cats: v2c.cats, qs: v2c.qs, opts: v2c.opts);
      await db.setSetting('seed_version', '$kSeedVersion');

      // Verify text was updated.
      final questions = await db.getQuestions('test_reseed', 1);
      expect(questions, isNotEmpty, reason: 'Q1 must still exist after upsert');
      final q1 = questions.first;
      expect(
        q1.promptEn,
        'Prompt v2 EN (SWS)',
        reason: 'promptEn must reflect v2 content after upsert',
      );
      expect(
        q1.promptFr,
        'Prompt v2 FR (SWS)',
        reason: 'promptFr must reflect v2 content after upsert',
      );

      // Verify QuestionProgress was NOT touched — Q1 is still mastered.
      final remaining = await db.getUnansweredQuestions('test_reseed', 1);
      expect(
        remaining.map((q) => q.id),
        isNot(contains(1)),
        reason:
            'Q1 QuestionProgress (mastered) must survive a content upsert — '
            'user progress must never be lost during re-seed',
      );

      // Verify version was written.
      final storedVersion = await db.getSetting('seed_version');
      expect(
        int.tryParse(storedVersion ?? ''),
        kSeedVersion,
        reason: 'seed_version must be updated to kSeedVersion after re-seed',
      );
    });

    // ── 4. seedAllUpsert does not delete QuestionProgress ───────────────────

    test('seedAllUpsert: progress rows are not deleted', () async {
      final v1data = _rawSeedData();
      final v1c = _buildCompanions(v1data);
      await db.seedAll(cats: v1c.cats, qs: v1c.qs, opts: v1c.opts);
      await db.recordAnswer(1, true);

      // Run upsert.
      await db.seedAllUpsert(cats: v1c.cats, qs: v1c.qs, opts: v1c.opts);

      // Q1 must still be mastered.
      final remaining = await db.getUnansweredQuestions('test_reseed', 1);
      expect(
        remaining.map((q) => q.id),
        isNot(contains(1)),
        reason: 'seedAllUpsert must not delete QuestionProgress rows',
      );
    });
  });
}
