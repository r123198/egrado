import 'package:drift/drift.dart';
import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/domain/exam_result.dart';

/// Scanned papers.
abstract interface class ResultRepository {
  /// A test's saved papers, sorted by student number; updates live.
  Stream<List<ExamResult>> watchResults(String examId);

  Future<ExamResult?> getResult(String examId, int studentNumber);

  /// Saves a paper, replacing any earlier one for the same student.
  /// When [replacing] names a different student, that student's saved
  /// paper is removed in the same step (the paper was reassigned).
  Future<void> saveResult(ExamResult result, {int? replacing});

  Future<void> deleteResult(String examId, int studentNumber);
}

class DriftResultRepository implements ResultRepository {
  DriftResultRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<ExamResult>> watchResults(String examId) =>
      (_db.select(_db.examResults)
            ..where((r) => r.examId.equals(examId))
            ..orderBy([(r) => OrderingTerm.asc(r.studentNumber)]))
          .watch()
          .map((rows) => rows.map(_toResult).toList());

  @override
  Future<ExamResult?> getResult(String examId, int studentNumber) async {
    final row =
        await (_db.select(_db.examResults)..where(
              (r) =>
                  r.examId.equals(examId) &
                  r.studentNumber.equals(studentNumber),
            ))
            .getSingleOrNull();
    return row == null ? null : _toResult(row);
  }

  @override
  Future<void> saveResult(ExamResult result, {int? replacing}) {
    return _db.transaction(() async {
      if (replacing != null && replacing != result.studentNumber) {
        await deleteResult(result.examId, replacing);
      }
      await _db
          .into(_db.examResults)
          .insertOnConflictUpdate(
            ExamResultsCompanion.insert(
              examId: result.examId,
              studentNumber: result.studentNumber,
              answers: result.answers,
              scannedAt: result.scannedAt,
            ),
          );
    });
  }

  @override
  Future<void> deleteResult(String examId, int studentNumber) =>
      (_db.delete(_db.examResults)..where(
            (r) =>
                r.examId.equals(examId) & r.studentNumber.equals(studentNumber),
          ))
          .go();

  static ExamResult _toResult(ResultRow row) => ExamResult(
    examId: row.examId,
    studentNumber: row.studentNumber,
    answers: row.answers,
    scannedAt: row.scannedAt,
  );
}
