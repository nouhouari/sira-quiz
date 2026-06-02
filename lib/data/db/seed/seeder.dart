import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../app_database.dart';

/// Bump this whenever the seed data changes (e.g. text corrections, new
/// questions).  Existing installs will have their content upserted on the
/// next launch without losing any QuestionProgress rows.
const kSeedVersion = 6;

/// Settings key under which the applied seed version is stored.
const _kSeedVersionKey = 'seed_version';

class DatabaseSeeder {
  final AppDatabase db;

  const DatabaseSeeder(this.db);

  /// Runs the appropriate seed path:
  ///
  /// 1. **Fresh install** (categories table is empty): full insert-or-ignore
  ///    seed, then write kSeedVersion to Settings.
  /// 2. **Existing install, outdated seed** (stored version < kSeedVersion):
  ///    idempotent upsert that updates all text/metadata fields while
  ///    preserving QuestionProgress, then write kSeedVersion to Settings.
  /// 3. **Existing install, up-to-date seed**: no-op.
  Future<void> seedIfNeeded() async {
    final isEmpty = await db.isCategoriesEmpty();

    if (!isEmpty) {
      // Check whether the stored seed version is current.
      final storedVersionStr = await db.getSetting(_kSeedVersionKey);
      final storedVersion = int.tryParse(storedVersionStr ?? '') ?? 0;
      if (storedVersion >= kSeedVersion) return; // Already up to date.

      // Outdated content — upsert without touching progress, then prune
      // rows that are no longer in the seed (e.g. removed categories).
      // The three operations are wrapped in a single outer transaction so the
      // v→v+1 upgrade is all-or-nothing: if anything fails, the version is not
      // written and the upgrade safely retries on the next launch.  Drift turns
      // the nested transactions inside seedAllUpsert/pruneRemovedSeedRows into
      // savepoints, so this composes correctly.
      debugPrint(
        '[DatabaseSeeder] Seed version $storedVersion → $kSeedVersion: '
        're-seeding content (progress preserved).',
      );
      final (cats, qs, opts) = await _buildCompanions();
      await db.transaction(() async {
        await db.seedAllUpsert(cats: cats, qs: qs, opts: opts);
        await db.pruneRemovedSeedRows(cats: cats, qs: qs, opts: opts);
        await db.setSetting(_kSeedVersionKey, '$kSeedVersion');
      });
      return;
    }

    // Fresh install: insert and record version.
    final (cats, qs, opts) = await _buildCompanions();
    await db.seedAll(cats: cats, qs: qs, opts: opts);
    await db.setSetting(_kSeedVersionKey, '$kSeedVersion');
  }

  // ---------------------------------------------------------------------------

  /// Parses questions_seed.json and builds Drift companion objects.
  Future<(List<CategoriesCompanion>, List<QuestionsCompanion>, List<QuestionOptionsCompanion>)>
      _buildCompanions() async {
    late final String jsonString;
    late final Map<String, dynamic> data;
    try {
      jsonString =
          await rootBundle.loadString('lib/data/db/seed/questions_seed.json');
      data = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e, st) {
      debugPrint(
        '[DatabaseSeeder] Failed to load or parse questions_seed.json: $e\n$st',
      );
      rethrow;
    }

    final rawCategories = data['categories'] as List<dynamic>;
    final rawQuestions = data['questions'] as List<dynamic>;

    // Build category companions
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

    // Build question companions and collect options separately
    final questionCompanions = <QuestionsCompanion>[];
    final optionsByQuestionId = <int, List<Map<String, dynamic>>>{};

    for (final q in rawQuestions) {
      final m = q as Map<String, dynamic>;
      final qId = m['id'] as int;
      questionCompanions.add(QuestionsCompanion.insert(
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
      optionsByQuestionId[qId] =
          (m['options'] as List<dynamic>).cast<Map<String, dynamic>>();
    }

    // Build option companions
    int optionAutoId = 1;
    final optionCompanions = <QuestionOptionsCompanion>[];
    for (final entry in optionsByQuestionId.entries) {
      for (final o in entry.value) {
        optionCompanions.add(QuestionOptionsCompanion.insert(
          id: Value(optionAutoId++),
          questionId: entry.key,
          textFr: o['textFr'] as String,
          textEn: o['textEn'] as String,
          isCorrect: Value(o['isCorrect'] as bool),
          sortOrder: Value(o['sortOrder'] as int),
        ));
      }
    }

    return (cats, questionCompanions, optionCompanions);
  }
}
