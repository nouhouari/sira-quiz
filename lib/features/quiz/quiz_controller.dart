import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/quiz_repository.dart';
import '../../domain/models/difficulty.dart';
import '../../domain/models/quiz_question.dart';

// ── Error type ────────────────────────────────────────────────────────────────

enum QuizError {
  none,
  noQuestions,
  /// The user has already answered every question in this level correctly.
  /// Distinct from [noQuestions] (which means no content exists at all).
  allMastered,
  unknown,
}

// ── State ─────────────────────────────────────────────────────────────────────

class AnswerRecord {
  final QuizQuestion question;
  final int? selectedOptionId; // null if unanswered (shouldn't happen)

  const AnswerRecord({
    required this.question,
    required this.selectedOptionId,
  });

  bool get isCorrect =>
      question.options
          .where((o) => o.isCorrect)
          .any((o) => o.id == selectedOptionId);
}

class QuizState {
  final List<QuizQuestion> questions;
  final int currentIndex;
  final int? selectedOptionId;
  final bool answered;
  final List<AnswerRecord> answers;
  final bool loading;
  final QuizError error;

  const QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedOptionId,
    this.answered = false,
    this.answers = const [],
    this.loading = false,
    this.error = QuizError.none,
  });

  bool get hasError => error != QuizError.none;

  bool get isLastQuestion =>
      questions.isNotEmpty && currentIndex >= questions.length - 1;

  QuizQuestion? get currentQuestion =>
      questions.isEmpty ? null : questions[currentIndex];

  int get score => answers.where((a) => a.isCorrect).length;

  /// True once all questions have been answered (answers list is full).
  bool get isComplete =>
      questions.isNotEmpty && answers.length == questions.length;

  QuizState copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? selectedOptionId,
    bool clearSelection = false,
    bool? answered,
    List<AnswerRecord>? answers,
    bool? loading,
    QuizError? error,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOptionId: clearSelection ? null : (selectedOptionId ?? this.selectedOptionId),
      answered: answered ?? this.answered,
      answers: answers ?? this.answers,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class QuizNotifier extends Notifier<QuizState> {
  /// Tracks the in-flight [recordAnswer] future started by [selectOption].
  /// B2: [resetLevelAndRestart] awaits this before resetting progress so a
  /// fire-and-forget answer written after the reset cannot re-insert a
  /// mastered row (TOCTOU window closed).
  Future<void>? _pendingRecord;

  @override
  QuizState build() => const QuizState();

  Future<void> startSession(String categorySlug, Difficulty difficulty) async {
    state = const QuizState(loading: true);
    try {
      final repo = ref.read(quizRepositoryProvider);
      final questions = await repo.getSessionQuestions(categorySlug, difficulty);
      if (questions.isEmpty) {
        final total = await repo.countTotal(categorySlug, difficulty);
        state = QuizState(
          error: total > 0 ? QuizError.allMastered : QuizError.noQuestions,
        );
        return;
      }
      state = QuizState(questions: questions);
    } catch (e) {
      state = const QuizState(error: QuizError.unknown);
    }
  }

  void selectOption(int optionId) {
    if (state.answered) return;
    state = state.copyWith(selectedOptionId: optionId, answered: true);

    final soundEnabled = ref.read(soundNotifierProvider).valueOrNull ?? false;
    if (soundEnabled) {
      HapticFeedback.lightImpact();
    }

    // Fire-and-forget progress persistence. Recording on select means progress
    // survives leaving mid-quiz via the back button (Feature 1).
    // B2: store the Future so resetLevelAndRestart can await it.
    final question = state.currentQuestion;
    if (question != null) {
      final isCorrect =
          question.options.where((o) => o.isCorrect).any((o) => o.id == optionId);
      _pendingRecord = ref
          .read(quizRepositoryProvider)
          .recordAnswer(question.id, isCorrect)
          .catchError((Object e) {
        debugPrint('[QuizNotifier] recordAnswer failed: $e');
      });
    }
  }

  /// Resets progress for a specific level and immediately starts a new session.
  /// Called by the Phase B "Play again" button on the allMastered screen.
  ///
  /// B2: awaits any in-flight [_pendingRecord] before resetting so a late-
  /// arriving recordAnswer cannot re-insert a mastered row after the reset.
  Future<void> resetLevelAndRestart(
      String categorySlug, Difficulty difficulty) async {
    // Drain any in-flight recordAnswer before wiping progress.
    if (_pendingRecord != null) {
      await _pendingRecord!.catchError((_) {});
      _pendingRecord = null;
    }
    final repo = ref.read(quizRepositoryProvider);
    await repo.resetProgressForLevel(categorySlug, difficulty);
    await startSession(categorySlug, difficulty);
  }

  void nextQuestion() {
    final current = state.currentQuestion;
    if (current == null) return;

    final record = AnswerRecord(
      question: current,
      selectedOptionId: state.selectedOptionId,
    );
    final updatedAnswers = [...state.answers, record];

    if (state.isLastQuestion) {
      // Quiz is complete — isComplete on the new state is true.
      // The ref.listen in QuizScreen triggers navigation.
      state = state.copyWith(answers: updatedAnswers);
    } else {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        answers: updatedAnswers,
        clearSelection: true,
        answered: false,
      );
    }
  }

  void reset() {
    state = const QuizState();
  }
}

final quizNotifierProvider =
    NotifierProvider<QuizNotifier, QuizState>(QuizNotifier.new);

// ── Session params provider ───────────────────────────────────────────────────

class SessionParams {
  final String categorySlug;
  final Difficulty difficulty;
  const SessionParams({required this.categorySlug, required this.difficulty});
}

final sessionParamsProvider = StateProvider<SessionParams?>((_) => null);
