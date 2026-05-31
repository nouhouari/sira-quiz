enum QuestionType {
  mcq('mcq'),
  trueFalse('trueFalse');

  final String value;
  const QuestionType(this.value);

  static QuestionType fromString(String v) => QuestionType.values.firstWhere(
        (t) => t.value == v,
        orElse: () => QuestionType.mcq,
      );
}
