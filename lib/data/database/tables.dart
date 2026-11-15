import 'dart:convert';

import 'package:drift/drift.dart';

/// Stores a list of chosen bubbles (null = blank) as JSON text.
class ChoiceListConverter extends TypeConverter<List<int?>, String> {
  const ChoiceListConverter();

  @override
  List<int?> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List).cast<int?>();

  @override
  String toSql(List<int?> value) => jsonEncode(value);
}

@DataClassName('ClassRow')
class SchoolClasses extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  /// DepEd grading policy id (see `kGradingPolicies`); null = current one.
  TextColumn get gradingPolicy => text().nullable()();

  /// Subject group id inside the policy; null = not chosen yet.
  TextColumn get subjectGroup => text().nullable()();

  /// The teacher's own grading scheme as JSON (`GradingScheme.toJson`);
  /// null = the DepEd policy and subject above.
  TextColumn get customScheme => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('StudentRow')
class Students extends Table {
  TextColumn get classId =>
      text().references(SchoolClasses, #id, onDelete: KeyAction.cascade)();

  /// The number shaded on the answer sheet (1–99), unique within a class.
  IntColumn get number => integer()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {classId, number};
}

@DataClassName('ExamRow')
class Exams extends Table {
  TextColumn get id => text()();
  TextColumn get classId =>
      text().references(SchoolClasses, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  IntColumn get questionCount => integer()();
  IntColumn get choiceCount => integer()();
  TextColumn get answerKey => text().map(const ChoiceListConverter())();
  DateTimeColumn get createdAt => dateTime()();

  /// Grading period this test counts toward; null = not counted.
  IntColumn get gradingPeriod => integer().nullable()();

  /// Id of the grading-scheme category this test counts under (Written
  /// Work, Term Exam, Quizzes…); null = not counted.
  TextColumn get gradeCategory => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One scanned paper. Keyed by student number, not by student row, so a
/// score survives the student being removed from the class list.
@DataClassName('ResultRow')
class ExamResults extends Table {
  TextColumn get examId =>
      text().references(Exams, #id, onDelete: KeyAction.cascade)();
  IntColumn get studentNumber => integer()();
  TextColumn get answers => text().map(const ChoiceListConverter())();
  DateTimeColumn get scannedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {examId, studentNumber};
}

/// Which class-record name belongs to which student, as matched or chosen
/// by the teacher, so the next fill doesn't ask again.
@DataClassName('RecordNameRow')
class RecordNames extends Table {
  TextColumn get classId =>
      text().references(SchoolClasses, #id, onDelete: KeyAction.cascade)();
  IntColumn get studentNumber => integer()();

  /// The student's name when paired. A pairing is only reused while the
  /// student still has this name, so a new student given a freed-up number
  /// never inherits someone else's class-record row.
  TextColumn get studentName => text()();
  TextColumn get recordName => text()();

  @override
  Set<Column> get primaryKey => {classId, studentNumber};
}

/// The class-record sheet and column a test was written into, so filling
/// again updates that column instead of using a new one.
@DataClassName('RecordPlacementRow')
class RecordPlacements extends Table {
  TextColumn get examId =>
      text().references(Exams, #id, onDelete: KeyAction.cascade)();
  TextColumn get sheetName => text()();
  IntColumn get columnIndex => integer()();

  /// The Highest Possible Score written there, to recognise the column.
  IntColumn get highestScore => integer()();

  @override
  Set<Column> get primaryKey => {examId};
}

/// Small per-teacher choices (which kind of school they teach in), one
/// row per setting.
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
