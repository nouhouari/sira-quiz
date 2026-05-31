import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/difficulty.dart';
import '../../domain/models/question_type.dart';
import '../../domain/models/quiz_question.dart';
import '../db/app_database.dart';

// ── Database provider ──────────────────────────────────────────────────────────
// In production main() this provider is overridden with the already-seeded
// AppDatabase instance. The factory below is the fallback used in tests.

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── Settings repository ───────────────────────────────────────────────────────

class SettingsRepository {
  final AppDatabase _db;
  const SettingsRepository(this._db);

  Future<String?> get(String key) => _db.getSetting(key);
  Future<void> set(String key, String value) => _db.setSetting(key, value);
}

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

// ── Settings providers (locale, themeMode, sound) ────────────────────────────

const _keyLocale = 'locale';
const _keyThemeMode = 'themeMode';
const _keySoundEnabled = 'soundEnabled';

class LocaleNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    return (await repo.get(_keyLocale)) ?? 'fr';
  }

  Future<void> setLocale(String languageCode) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.set(_keyLocale, languageCode);
    state = AsyncData(languageCode);
  }
}

final localeNotifierProvider =
    AsyncNotifierProvider<LocaleNotifier, String>(LocaleNotifier.new);

class ThemeModeNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    return (await repo.get(_keyThemeMode)) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.set(_keyThemeMode, mode);
    state = AsyncData(mode);
  }
}

final themeModeNotifierProvider =
    AsyncNotifierProvider<ThemeModeNotifier, String>(ThemeModeNotifier.new);

class SoundNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    final val = await repo.get(_keySoundEnabled);
    return val == 'true';
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.set(_keySoundEnabled, enabled.toString());
    state = AsyncData(enabled);
  }
}

final soundNotifierProvider =
    AsyncNotifierProvider<SoundNotifier, bool>(SoundNotifier.new);

// ── Quiz repository ────────────────────────────────────────────────────────────

class QuizRepository {
  final AppDatabase _db;
  const QuizRepository(this._db);

  Future<List<Category>> getAllCategories() => _db.getAllCategories();

  /// Total question count for a level (including mastered).
  Future<int> countTotal(String categorySlug, Difficulty difficulty) =>
      _db.countQuestions(categorySlug, difficulty.value);

  /// Remaining (not-yet-mastered) question count for a level.
  Future<int> countRemaining(String categorySlug, Difficulty difficulty) =>
      _db.countRemaining(categorySlug, difficulty.value);

  /// Kept for any callers that previously used [countAvailable].
  /// Delegates to [countTotal] — total never excludes mastered questions.
  Future<int> countAvailable(String categorySlug, Difficulty difficulty) =>
      countTotal(categorySlug, difficulty);

  /// Returns up to [limit] questions that have NOT yet been answered correctly.
  Future<List<QuizQuestion>> getSessionQuestions(
    String categorySlug,
    Difficulty difficulty, {
    int limit = 10,
  }) async {
    final rows = await _db.getUnansweredQuestions(
      categorySlug,
      difficulty.value,
      limit: limit,
    );
    if (rows.isEmpty) return const [];

    // Batched options fetch: one query for all question ids, no N+1.
    final ids = rows.map((r) => r.id).toList();
    final allOptions = await _db.getOptionsForQuestions(ids);

    // Group options by questionId in Dart.
    final optionsByQuestion = <int, List<QuizOption>>{};
    for (final o in allOptions) {
      optionsByQuestion.putIfAbsent(o.questionId, () => []).add(
            QuizOption(
              id: o.id,
              textFr: o.textFr,
              textEn: o.textEn,
              isCorrect: o.isCorrect,
              sortOrder: o.sortOrder,
            ),
          );
    }

    // TODO: option ids in the JSON must remain globally unique across all
    // questions because the seeder assigns them sequentially. A proper
    // AUTOINCREMENT fix is deferred — see review notes.

    return rows.map((row) {
      final opts = List.of(optionsByQuestion[row.id] ?? <QuizOption>[])
        ..shuffle();
      return QuizQuestion(
        id: row.id,
        categorySlug: row.categorySlug,
        difficulty: Difficulty.fromInt(row.difficulty),
        type: QuestionType.fromString(row.type),
        promptFr: row.promptFr,
        promptEn: row.promptEn,
        explanationFr: row.explanationFr,
        explanationEn: row.explanationEn,
        sourceArabic: row.sourceArabic,
        sourceReference: row.sourceReference,
        options: opts,
      );
    }).toList();
  }

  /// Records a question answer; correct answers are persisted permanently
  /// (a previously-correct row is never downgraded to wrong).
  Future<void> recordAnswer(int questionId, bool correct) =>
      _db.recordAnswer(questionId, correct);

  /// Clears progress for a specific category+difficulty so the level can be
  /// replayed from scratch.
  Future<void> resetProgressForLevel(
          String categorySlug, Difficulty difficulty) =>
      _db.resetProgressForLevel(categorySlug, difficulty.value);

  /// Wipes all progress across every level.
  Future<void> resetAllProgress() => _db.resetAllProgress();
}

final quizRepositoryProvider = Provider<QuizRepository>(
  (ref) => QuizRepository(ref.watch(appDatabaseProvider)),
);

// ── Derived providers ──────────────────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getAllCategories();
});

/// Combined total+remaining counts for a difficulty level.
/// autoDispose so it recomputes fresh whenever the Difficulty screen remounts
/// (picks up newly mastered questions after returning from a quiz session).
final levelStatusProvider = FutureProvider.autoDispose
    .family<({int total, int remaining}), ({String slug, Difficulty difficulty})>(
  (ref, params) async {
    final repo = ref.watch(quizRepositoryProvider);
    final total = await repo.countTotal(params.slug, params.difficulty);
    final remaining = await repo.countRemaining(params.slug, params.difficulty);
    return (total: total, remaining: remaining);
  },
);

// B3: questionCountProvider was a backward-compat shim delegating to
// levelStatusProvider.total. No callers remain after the difficulty screen
// migrated to levelStatusProvider in Phase A. Removed to avoid a footgun.
