// Seed integrity regression test.
//
// Parses lib/data/db/seed/questions_seed.json directly from disk and asserts
// the invariants that the Drift seeder depends on (non-null casts, enum values,
// option cardinality).  A violation here means seeding would crash or produce
// corrupt quiz data at runtime.
//
// Run:
//   flutter test test/seed_integrity_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _expectedQuestionCount = 1121;

// quran_message was removed in seed v4.
const _validSlugs = {
  'birth_youth',
  'revelation',
  'meccan_period',
  'hijra',
  'medinan_period',
  'expeditions',
  'family_companions',
  'character',
  'final_days',
};

const _validTypes = {'mcq', 'trueFalse'};


// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Resolves the path to the seed JSON relative to the project root, which is
/// the working directory when `flutter test` is run from the repo root.
String _seedPath() {
  // When run via `flutter test` the cwd is the project root.
  final candidate = 'lib/data/db/seed/questions_seed.json';
  if (File(candidate).existsSync()) return candidate;
  // Fallback: resolve relative to this test file's location.
  final scriptDir = File.fromUri(Platform.script).parent;
  return '${scriptDir.parent.path}/$candidate';
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Map<String, dynamic> data;
  late List<dynamic> rawCategories;
  late List<dynamic> rawQuestions;

  setUpAll(() {
    final path = _seedPath();
    final file = File(path);
    expect(
      file.existsSync(),
      isTrue,
      reason: 'questions_seed.json not found at $path',
    );
    final content = file.readAsStringSync();
    data = jsonDecode(content) as Map<String, dynamic>;
    rawCategories = data['categories'] as List<dynamic>;
    rawQuestions = data['questions'] as List<dynamic>;
  });

  // ── 1. Top-level counts and unique ids ──────────────────────────────────────

  group('top-level structure', () {
    test('categories count matches the 9 known slugs', () {
      expect(
        rawCategories.length,
        _validSlugs.length,
        reason: 'Expected ${_validSlugs.length} categories',
      );
    });

    test('category slugs are exactly the 9 known slugs (quran_message removed in v4)', () {
      final slugs = rawCategories
          .cast<Map<String, dynamic>>()
          .map((c) => c['slug'] as String)
          .toSet();
      expect(slugs, equals(_validSlugs));
    });

    test('question count == $_expectedQuestionCount', () {
      expect(
        rawQuestions.length,
        _expectedQuestionCount,
        reason: 'Expected exactly $_expectedQuestionCount questions',
      );
    });

    test('all question ids are unique', () {
      final ids = rawQuestions
          .cast<Map<String, dynamic>>()
          .map((q) => q['id'] as int)
          .toList();
      final unique = ids.toSet();
      expect(
        unique.length,
        ids.length,
        reason:
            'Duplicate ids found: ${ids.where((id) => ids.indexOf(id) != ids.lastIndexOf(id)).toSet()}',
      );
    });

    // ── Seed v4 removal guard ─────────────────────────────────────────────────

    test('no question has categorySlug == quran_message (removed in v4)', () {
      final violations = rawQuestions
          .cast<Map<String, dynamic>>()
          .where((q) => q['categorySlug'] == 'quran_message')
          .map((q) => 'Q${q['id']}')
          .toList();
      expect(
        violations,
        isEmpty,
        reason:
            'quran_message was removed in seed v4; these questions must not '
            'exist: ${violations.join(', ')}',
      );
    });

    test('categories list does not contain quran_message slug (removed in v4)', () {
      final slugs = rawCategories
          .cast<Map<String, dynamic>>()
          .map((c) => c['slug'] as String)
          .toList();
      expect(
        slugs,
        isNot(contains('quran_message')),
        reason:
            'quran_message category was removed in seed v4 and must not appear '
            'in the categories list',
      );
    });
  });

  // ── 2. Per-question field invariants ────────────────────────────────────────

  group('per-question field invariants', () {
    late List<Map<String, dynamic>> questions;

    setUpAll(() {
      questions = rawQuestions.cast<Map<String, dynamic>>();
    });

    test('every question has a valid type (mcq or trueFalse)', () {
      final violations = <String>[];
      for (final q in questions) {
        final id = q['id'];
        final type = q['type'] as String?;
        if (type == null || !_validTypes.contains(type)) {
          violations.add('Q$id: type="$type"');
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('every question has difficulty in {1, 2, 3}', () {
      final violations = <String>[];
      for (final q in questions) {
        final id = q['id'];
        final diff = q['difficulty'];
        if (diff == null || diff is! int || !{1, 2, 3}.contains(diff)) {
          violations.add('Q$id: difficulty=$diff');
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('every question has a valid categorySlug', () {
      final violations = <String>[];
      for (final q in questions) {
        final id = q['id'];
        final slug = q['categorySlug'] as String?;
        if (slug == null || !_validSlugs.contains(slug)) {
          violations.add('Q$id: categorySlug="$slug"');
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('every question has non-empty promptFr, promptEn', () {
      final violations = <String>[];
      for (final q in questions) {
        final id = q['id'];
        for (final field in ['promptFr', 'promptEn']) {
          final val = q[field] as String?;
          if (val == null || val.trim().isEmpty) {
            violations.add('Q$id: empty $field');
          }
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('every question has non-empty explanationFr, explanationEn', () {
      final violations = <String>[];
      for (final q in questions) {
        final id = q['id'];
        for (final field in ['explanationFr', 'explanationEn']) {
          final val = q[field] as String?;
          if (val == null || val.trim().isEmpty) {
            violations.add('Q$id: empty $field');
          }
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('every question has a non-empty sourceReference (non-null cast in seeder)', () {
      final violations = <String>[];
      for (final q in questions) {
        final id = q['id'];
        final ref = q['sourceReference'] as String?;
        if (ref == null || ref.trim().isEmpty) {
          violations.add('Q$id: sourceReference is null or empty');
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    // ── 3. Option cardinality ────────────────────────────────────────────────

    test('mcq questions have exactly 4 options', () {
      final violations = <String>[];
      for (final q in questions) {
        if (q['type'] != 'mcq') continue;
        final id = q['id'];
        final opts = (q['options'] as List<dynamic>?) ?? [];
        if (opts.length != 4) {
          violations.add('Q$id: ${opts.length} options');
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('trueFalse questions have exactly 2 options', () {
      final violations = <String>[];
      for (final q in questions) {
        if (q['type'] != 'trueFalse') continue;
        final id = q['id'];
        final opts = (q['options'] as List<dynamic>?) ?? [];
        if (opts.length != 2) {
          violations.add('Q$id: ${opts.length} options');
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('mcq questions have sortOrders exactly {1, 2, 3, 4}', () {
      final violations = <String>[];
      for (final q in questions) {
        if (q['type'] != 'mcq') continue;
        final id = q['id'];
        final opts = (q['options'] as List<dynamic>).cast<Map<String, dynamic>>();
        final sortOrders = opts.map((o) => o['sortOrder'] as int).toSet();
        if (!const {1, 2, 3, 4}.containsAll(sortOrders) ||
            sortOrders.length != 4) {
          violations.add('Q$id: sortOrders=${sortOrders.toList()..sort()}');
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('trueFalse questions have sortOrders exactly {1, 2}', () {
      final violations = <String>[];
      for (final q in questions) {
        if (q['type'] != 'trueFalse') continue;
        final id = q['id'];
        final opts = (q['options'] as List<dynamic>).cast<Map<String, dynamic>>();
        final sortOrders = opts.map((o) => o['sortOrder'] as int).toSet();
        if (!const {1, 2}.containsAll(sortOrders) || sortOrders.length != 2) {
          violations.add('Q$id: sortOrders=${sortOrders.toList()..sort()}');
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('every question has exactly one isCorrect==true option', () {
      final violations = <String>[];
      for (final q in questions) {
        final id = q['id'];
        final opts = (q['options'] as List<dynamic>).cast<Map<String, dynamic>>();
        final correctCount = opts.where((o) => o['isCorrect'] == true).length;
        if (correctCount != 1) {
          violations.add('Q$id: $correctCount correct options');
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('every option has non-empty textFr and textEn', () {
      final violations = <String>[];
      for (final q in questions) {
        final id = q['id'];
        final opts = (q['options'] as List<dynamic>).cast<Map<String, dynamic>>();
        for (int i = 0; i < opts.length; i++) {
          final o = opts[i];
          for (final field in ['textFr', 'textEn']) {
            final val = o[field] as String?;
            if (val == null || val.trim().isEmpty) {
              violations.add('Q$id option[${i + 1}]: empty $field');
            }
          }
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });

  // ── 4. Forbidden glyphs / strings ────────────────────────────────────────

  group('forbidden content', () {
    test('no question contains the Unicode honorific glyph ﷺ', () {
      final violations = <String>[];
      for (final q in rawQuestions.cast<Map<String, dynamic>>()) {
        final encoded = jsonEncode(q);
        if (encoded.contains('ﷺ')) {
          violations.add('Q${q['id']}: contains ﷺ');
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('no question contains the string "PBUH"', () {
      final violations = <String>[];
      for (final q in rawQuestions.cast<Map<String, dynamic>>()) {
        final encoded = jsonEncode(q);
        if (encoded.contains('PBUH')) {
          violations.add('Q${q['id']}: contains PBUH');
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });
}
