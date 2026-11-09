import 'package:drift/drift.dart';
import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/data/repositories/id_generator.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/overviews.dart';
import 'package:egrado/grading/grading_policy.dart';

/// Tests and their answer keys.
abstract interface class ExamRepository {
  /// A class's tests, newest first, with how many papers are checked.
  Stream<List<ExamOverview>> watchOverviews(String classId);

  /// Every test in every class, newest first, with class names.
  Stream<List<ExamOverview>> watchAllOverviews();

  /// One test, or null once deleted; updates live.
  Stream<Exam?> watchExam(String examId);

  /// Returns the new test's id.
  Future<String> createExam({
    required String classId,
    required String title,
    required int questionCount,
    required int choiceCount,
    GradeTag? gradeTag,
  });

  /// Saves title, counts, answer key and grade tag of an existing test.
  Future<void> updateExam(Exam exam);

  /// Also deletes the test's scores.
  Future<void> deleteExam(String examId);
}

class DriftExamRepository implements ExamRepository {
  DriftExamRepository(this._db, [IdGenerator? ids])
    : _ids = ids ?? IdGenerator();

  final AppDatabase _db;
  final IdGenerator _ids;

  @override
  Stream<List<ExamOverview>> watchOverviews(String classId) =>
      _watchOverviewsWhere('e.class_id = ?', [Variable.withString(classId)]);

  @override
  Stream<List<ExamOverview>> watchAllOverviews() =>
      _watchOverviewsWhere('1 = 1', const []);

  Stream<List<ExamOverview>> _watchOverviewsWhere(
    String condition,
    List<Variable<Object>> variables,
  ) {
    return _db
        .customSelect(
          'SELECT e.*, c.name AS class_name, '
          '(SELECT COUNT(*) FROM exam_results r WHERE r.exam_id = e.id) '
          'AS checked_count, '
          '(SELECT COUNT(*) FROM students s WHERE s.class_id = e.class_id) '
          'AS class_size '
          'FROM exams e JOIN school_classes c ON c.id = e.class_id '
          'WHERE $condition ORDER BY e.created_at DESC, e.rowid DESC',
          variables: variables,
          readsFrom: {
            _db.exams,
            _db.examResults,
            _db.schoolClasses,
            _db.students,
          },
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              ExamOverview(
                exam: _toExam(_db.exams.map(row.data)),
                checkedCount: row.read<int>('checked_count'),
                className: row.read<String>('class_name'),
                classSize: row.read<int>('class_size'),
              ),
          ],
        );
  }

  @override
  Stream<Exam?> watchExam(String examId) =>
      (_db.select(_db.exams)..where((e) => e.id.equals(examId)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _toExam(row));

  @override
  Future<String> createExam({
    required String classId,
    required String title,
    required int questionCount,
    required int choiceCount,
    GradeTag? gradeTag,
  }) async {
    final id = _ids.next();
    await _db
        .into(_db.exams)
        .insert(
          ExamsCompanion.insert(
            id: id,
            classId: classId,
            title: title,
            questionCount: questionCount,
            choiceCount: choiceCount,
            answerKey: List<int?>.filled(questionCount, null),
            createdAt: DateTime.now(),
            gradingPeriod: Value(gradeTag?.period),
            gradeComponent: Value(gradeTag?.component.name),
            examPart: Value(gradeTag?.examPart?.name),
          ),
        );
    return id;
  }

  @override
  Future<void> updateExam(Exam exam) =>
      (_db.update(_db.exams)..where((e) => e.id.equals(exam.id))).write(
        ExamsCompanion(
          title: Value(exam.title),
          questionCount: Value(exam.questionCount),
          choiceCount: Value(exam.choiceCount),
          answerKey: Value(exam.answerKey),
          gradingPeriod: Value(exam.gradeTag?.period),
          gradeComponent: Value(exam.gradeTag?.component.name),
          examPart: Value(exam.gradeTag?.examPart?.name),
        ),
      );

  @override
  Future<void> deleteExam(String examId) =>
      (_db.delete(_db.exams)..where((e) => e.id.equals(examId))).go();

  static Exam _toExam(ExamRow row) => Exam(
    id: row.id,
    classId: row.classId,
    title: row.title,
    questionCount: row.questionCount,
    choiceCount: row.choiceCount,
    answerKey: row.answerKey,
    createdAt: row.createdAt,
    gradeTag: _toTag(row),
  );

  /// Unknown names (from a newer app version) read as "not counted".
  static GradeTag? _toTag(ExamRow row) {
    final period = row.gradingPeriod;
    final component = GradeComponent.values.asNameMap()[row.gradeComponent];
    if (period == null || period < 1 || component == null) return null;
    return GradeTag(
      period: period,
      component: component,
      examPart: component == GradeComponent.exam
          ? ExamPart.values.asNameMap()[row.examPart]
          : null,
    );
  }
}
