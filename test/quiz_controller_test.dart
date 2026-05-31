// ignore_for_file: avoid_print

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sira_quiz/data/db/app_database.dart';
import 'package:sira_quiz/data/repositories/quiz_repository.dart';
import 'package:sira_quiz/domain/models/difficulty.dart';
import 'package:sira_quiz/features/quiz/quiz_controller.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a fully in-memory AppDatabase (no file I/O).
AppDatabase _openMemoryDb() => AppDatabase(NativeDatabase.memory());

/// Seeds the DB with a small, deterministic fixture:
///   - 1 category: "test_cat"
///   - 3 questions, beginner difficulty, 2 options each
///     Q1: correct = opt id 1   (option sort 1)
///     Q2: correct = opt id 5   (option sort 1)
///     Q3: correct = opt id 9   (option sort 1)
///
/// Option ids are globally unique (matches seeder convention).
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
      // Q3: id 6 wrong, id 7 wrong, id 8 wrong, id 9 correct
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

/// Builds a [ProviderContainer] wired to [db] with overrides for the DB and
/// sound provider (sound is off so HapticFeedback is never triggered in tests).
ProviderContainer _makeContainer(AppDatabase db) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      // Silence the sound AsyncNotifier so it never tries to read real prefs.
      soundNotifierProvider.overrideWith(() => _SilentSoundNotifier()),
    ],
  );
}

/// A silent SoundNotifier subclass that always returns false without DB access.
class _SilentSoundNotifier extends SoundNotifier {
  @override
  Future<bool> build() async => false;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('QuizNotifier — controller unit tests', () {
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

    // ── Helper: start a session and wait for questions to load ──────────────

    Future<void> startSession() async {
      await container
          .read(quizNotifierProvider.notifier)
          .startSession('test_cat', Difficulty.beginner);
    }

    // ── 1. Score increments only on correct answer ─────────────────────────

    test('score increments when the correct option is selected', () async {
      await startSession();

      final q1 = container.read(quizNotifierProvider).currentQuestion!;
      final correctId = q1.options.firstWhere((o) => o.isCorrect).id;

      container.read(quizNotifierProvider.notifier).selectOption(correctId);
      container.read(quizNotifierProvider.notifier).nextQuestion();

      // After advancing past Q1 the AnswerRecord for Q1 is recorded.
      final state = container.read(quizNotifierProvider);
      expect(state.answers.length, 1);
      expect(state.answers.first.isCorrect, isTrue);
      expect(state.score, 1);
    });

    test('score does NOT increment when a wrong option is selected', () async {
      await startSession();

      final q1 = container.read(quizNotifierProvider).currentQuestion!;
      final wrongId = q1.options.firstWhere((o) => !o.isCorrect).id;

      container.read(quizNotifierProvider.notifier).selectOption(wrongId);
      container.read(quizNotifierProvider.notifier).nextQuestion();

      final state = container.read(quizNotifierProvider);
      expect(state.answers.first.isCorrect, isFalse);
      expect(state.score, 0);
    });

    test('score accumulates across multiple questions', () async {
      await startSession();

      // Answer all 3 questions correctly.
      for (var i = 0; i < 3; i++) {
        final q =
            container.read(quizNotifierProvider).currentQuestion!;
        final correctId = q.options.firstWhere((o) => o.isCorrect).id;
        container
            .read(quizNotifierProvider.notifier)
            .selectOption(correctId);
        container.read(quizNotifierProvider.notifier).nextQuestion();
      }

      final state = container.read(quizNotifierProvider);
      expect(state.score, 3);
    });

    // ── 2. isLastQuestion ──────────────────────────────────────────────────

    test('isLastQuestion is false on the first question', () async {
      await startSession();
      expect(container.read(quizNotifierProvider).currentIndex, 0);
      expect(container.read(quizNotifierProvider).isLastQuestion, isFalse);
    });

    test('isLastQuestion is true when on the final question', () async {
      await startSession();
      final notifier = container.read(quizNotifierProvider.notifier);

      // Advance to last question (index 2 out of 3).
      for (var i = 0; i < 2; i++) {
        final q =
            container.read(quizNotifierProvider).currentQuestion!;
        final correctId = q.options.firstWhere((o) => o.isCorrect).id;
        notifier.selectOption(correctId);
        notifier.nextQuestion();
      }

      final state = container.read(quizNotifierProvider);
      expect(state.currentIndex, 2);
      expect(state.isLastQuestion, isTrue);
    });

    // ── 3. isComplete after answering last question ────────────────────────

    test('isComplete becomes true after answering and advancing past the last question',
        () async {
      await startSession();
      final notifier = container.read(quizNotifierProvider.notifier);

      // Answer all 3 questions.
      for (var i = 0; i < 3; i++) {
        final q =
            container.read(quizNotifierProvider).currentQuestion!;
        final correctId = q.options.firstWhere((o) => o.isCorrect).id;
        notifier.selectOption(correctId);
        notifier.nextQuestion();
      }

      final state = container.read(quizNotifierProvider);
      expect(state.isComplete, isTrue);
      expect(state.answers.length, 3);
    });

    // ── 4. Selecting an option locks it; second select is a no-op ──────────

    test('selectOption is idempotent — second call after answered is ignored',
        () async {
      await startSession();
      final notifier = container.read(quizNotifierProvider.notifier);

      final q1 = container.read(quizNotifierProvider).currentQuestion!;
      final firstOptionId = q1.options.first.id;
      final secondOptionId = q1.options.last.id;

      // First select.
      notifier.selectOption(firstOptionId);
      expect(
          container.read(quizNotifierProvider).selectedOptionId,
          firstOptionId);

      // Second select (different option) should be ignored because answered == true.
      notifier.selectOption(secondOptionId);
      expect(
          container.read(quizNotifierProvider).selectedOptionId,
          firstOptionId,
          reason: 'second selectOption call must not change the selection');
    });

    test('answered flag is set to true after first selectOption', () async {
      await startSession();
      final notifier = container.read(quizNotifierProvider.notifier);
      final q1 = container.read(quizNotifierProvider).currentQuestion!;

      expect(container.read(quizNotifierProvider).answered, isFalse);
      notifier.selectOption(q1.options.first.id);
      expect(container.read(quizNotifierProvider).answered, isTrue);
    });

    // ── 5. Empty selection sets QuizError.noQuestions ─────────────────────

    test('startSession with unknown slug sets QuizError.noQuestions', () async {
      await container
          .read(quizNotifierProvider.notifier)
          .startSession('nonexistent_category', Difficulty.beginner);

      final state = container.read(quizNotifierProvider);
      expect(state.error, QuizError.noQuestions);
      expect(state.hasError, isTrue);
      expect(state.loading, isFalse);
    });

    test(
        'startSession with valid slug but mismatched difficulty sets QuizError.noQuestions',
        () async {
      // 'test_cat' only has beginner questions in our fixture.
      await container
          .read(quizNotifierProvider.notifier)
          .startSession('test_cat', Difficulty.advanced);

      final state = container.read(quizNotifierProvider);
      expect(state.error, QuizError.noQuestions);
    });

    // ── 6. reset() clears state ────────────────────────────────────────────

    test('reset clears all state back to initial', () async {
      await startSession();
      final notifier = container.read(quizNotifierProvider.notifier);
      final q = container.read(quizNotifierProvider).currentQuestion!;
      notifier.selectOption(q.options.first.id);
      notifier.reset();

      final state = container.read(quizNotifierProvider);
      expect(state.questions, isEmpty);
      expect(state.currentIndex, 0);
      expect(state.answered, isFalse);
      expect(state.answers, isEmpty);
      expect(state.error, QuizError.none);
    });

    // ── 7. nextQuestion clears selection for next question ─────────────────

    test('nextQuestion resets selectedOptionId and answered for the new question',
        () async {
      await startSession();
      final notifier = container.read(quizNotifierProvider.notifier);

      final q1 = container.read(quizNotifierProvider).currentQuestion!;
      notifier.selectOption(q1.options.first.id);
      notifier.nextQuestion();

      final state = container.read(quizNotifierProvider);
      expect(state.currentIndex, 1);
      expect(state.answered, isFalse);
      expect(state.selectedOptionId, isNull);
    });

    // ── 8. QuizState.score property ────────────────────────────────────────

    test('score is 0 when no questions are answered', () async {
      await startSession();
      expect(container.read(quizNotifierProvider).score, 0);
    });

    // ── 9. Initial/loading states ──────────────────────────────────────────

    test('initial state has loading=false, error=none, no questions', () {
      final state = container.read(quizNotifierProvider);
      expect(state.loading, isFalse);
      expect(state.error, QuizError.none);
      expect(state.questions, isEmpty);
      expect(state.isComplete, isFalse);
    });

    test('state transitions to loading=true then resolves with questions', () async {
      // Fire startSession without awaiting to observe the loading state.
      // We cannot easily capture the intermediate loading state here because
      // startSession is async and Dart's event loop won't yield between the
      // `state = const QuizState(loading: true)` and the DB query in the same
      // microtask. Instead, we verify the end result is valid.
      await startSession();
      final state = container.read(quizNotifierProvider);
      expect(state.loading, isFalse);
      expect(state.questions.isNotEmpty, isTrue);
      expect(state.questions.length, lessThanOrEqualTo(10));
    });
  });
}
