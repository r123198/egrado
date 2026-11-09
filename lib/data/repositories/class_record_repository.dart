import 'package:drift/drift.dart';
import 'package:egrado/class_record/class_record_fill.dart';
import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/domain/exam_result.dart';

/// What the app remembers about a class's E-Class Record between fills.
abstract interface class ClassRecordRepository {
  /// Student number → the learner's name as written in the class record,
  /// for students who still have the name they had when paired.
  Future<Map<int, String>> getRecordNames(String classId);

  /// Test id → where it was written, for the class's tests.
  Future<Map<String, ColumnPlacement>> getPlacements(String classId);

  /// After a fill: replaces the class's name pairings ([names]: student
  /// number → record name) and records where each test went, together.
  Future<void> saveFill(
    String classId, {
    required Map<int, String> names,
    required Map<String, ColumnPlacement> placements,
  });

  /// Every scanned paper of every test in the class; updates live.
  Stream<List<ExamResult>> watchClassResults(String classId);
}

class DriftClassRecordRepository implements ClassRecordRepository {
  DriftClassRecordRepository(this._db);

  final AppDatabase _db;

  @override
  Future<Map<int, String>> getRecordNames(String classId) async {
    final query = _db.select(_db.recordNames).join([
      innerJoin(
        _db.students,
        _db.students.classId.equalsExp(_db.recordNames.classId) &
            _db.students.number.equalsExp(_db.recordNames.studentNumber),
      ),
    ])..where(_db.recordNames.classId.equals(classId));
    final rows = await query.get();
    return {
      for (final row in rows)
        if (row.readTable(_db.students).name ==
            row.readTable(_db.recordNames).studentName)
          row.readTable(_db.recordNames).studentNumber: row
              .readTable(_db.recordNames)
              .recordName,
    };
  }

  @override
  Future<void> saveFill(
    String classId, {
    required Map<int, String> names,
    required Map<String, ColumnPlacement> placements,
  }) => _db.transaction(() async {
    final students = await (_db.select(
      _db.students,
    )..where((s) => s.classId.equals(classId))).get();
    final studentNames = {for (final s in students) s.number: s.name};
    await (_db.delete(
      _db.recordNames,
    )..where((r) => r.classId.equals(classId))).go();
    await _db.batch((b) {
      b.insertAll(_db.recordNames, [
        for (final MapEntry(key: number, value: name) in names.entries)
          if (studentNames[number] case final studentName?)
            RecordNamesCompanion.insert(
              classId: classId,
              studentNumber: number,
              studentName: studentName,
              recordName: name,
            ),
      ]);
      b.insertAllOnConflictUpdate(_db.recordPlacements, [
        for (final MapEntry(key: examId, value: p) in placements.entries)
          RecordPlacementsCompanion.insert(
            examId: examId,
            sheetName: p.sheetName,
            columnIndex: p.column,
            highestScore: p.highestScore,
          ),
      ]);
    });
  });

  @override
  Future<Map<String, ColumnPlacement>> getPlacements(String classId) async {
    final query = _db.select(_db.recordPlacements).join([
      innerJoin(_db.exams, _db.exams.id.equalsExp(_db.recordPlacements.examId)),
    ])..where(_db.exams.classId.equals(classId));
    final rows = await query.get();
    return {
      for (final row in rows)
        row.readTable(_db.recordPlacements).examId: ColumnPlacement(
          row.readTable(_db.recordPlacements).sheetName,
          row.readTable(_db.recordPlacements).columnIndex,
          row.readTable(_db.recordPlacements).highestScore,
        ),
    };
  }

  @override
  Stream<List<ExamResult>> watchClassResults(String classId) {
    final query = _db.select(_db.examResults).join([
      innerJoin(_db.exams, _db.exams.id.equalsExp(_db.examResults.examId)),
    ])..where(_db.exams.classId.equals(classId));
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          ExamResult(
            examId: row.readTable(_db.examResults).examId,
            studentNumber: row.readTable(_db.examResults).studentNumber,
            answers: row.readTable(_db.examResults).answers,
            scannedAt: row.readTable(_db.examResults).scannedAt,
          ),
      ],
    );
  }
}
