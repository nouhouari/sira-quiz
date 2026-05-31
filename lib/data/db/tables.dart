import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get slug => text().unique()();
  TextColumn get iconKey => text()();
  TextColumn get nameFr => text()();
  TextColumn get nameEn => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Questions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get categorySlug => text()();
  IntColumn get difficulty => integer()(); // 1=beginner,2=intermediate,3=advanced
  TextColumn get type => text()(); // 'mcq' | 'trueFalse'
  TextColumn get promptFr => text()();
  TextColumn get promptEn => text()();
  TextColumn get explanationFr => text()();
  TextColumn get explanationEn => text()();
  TextColumn get sourceArabic => text().nullable()();
  TextColumn get sourceReference => text()();
}

class QuestionOptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get questionId => integer()();
  TextColumn get textFr => text()();
  TextColumn get textEn => text()();
  BoolColumn get isCorrect => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

// Key-value settings store (locale, themeMode, soundEnabled, etc.)
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
