import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../app_database.dart';

class DatabaseSeeder {
  final AppDatabase db;

  const DatabaseSeeder(this.db);

  Future<void> seedIfNeeded() async {
    final isEmpty = await db.isCategoriesEmpty();
    if (!isEmpty) return;

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

    await db.seedAll(
      cats: cats,
      qs: questionCompanions,
      opts: optionCompanions,
    );
  }
}
