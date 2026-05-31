import 'question_type.dart';
import 'difficulty.dart';

class QuizOption {
  final int id;
  final String textFr;
  final String textEn;
  final bool isCorrect;
  final int sortOrder;

  const QuizOption({
    required this.id,
    required this.textFr,
    required this.textEn,
    required this.isCorrect,
    required this.sortOrder,
  });
}

class QuizQuestion {
  final int id;
  final String categorySlug;
  final Difficulty difficulty;
  final QuestionType type;
  final String promptFr;
  final String promptEn;
  final String explanationFr;
  final String explanationEn;
  final String? sourceArabic;
  final String sourceReference;
  final List<QuizOption> options;

  const QuizQuestion({
    required this.id,
    required this.categorySlug,
    required this.difficulty,
    required this.type,
    required this.promptFr,
    required this.promptEn,
    required this.explanationFr,
    required this.explanationEn,
    this.sourceArabic,
    required this.sourceReference,
    required this.options,
  });

  QuizOption? get correctOption =>
      options.where((o) => o.isCorrect).firstOrNull;
}
