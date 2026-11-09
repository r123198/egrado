import 'package:drift/drift.dart';
import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/data/repositories/id_generator.dart';
import 'package:egrado/domain/overviews.dart';
import 'package:egrado/domain/school_class.dart';

/// Classes and their student lists.
abstract interface class ClassRepository {
  /// Every class with its counts, sorted by name; updates live.
  Stream<List<ClassOverview>> watchOverviews();

  /// One class with its students, or null once deleted; updates live.
  Stream<SchoolClass?> watchClass(String classId);

  /// Returns the new class's id.
  Future<String> createClass(String name);
  Future<void> renameClass(String classId, String name);

  /// Saves the class's DepEd grading policy and subject group.
  Future<void> setGrading(
    String classId, {
    required String policyId,
    required String? subjectGroupId,
  });

  /// Also deletes the class's students, tests and scores.
  Future<void> deleteClass(String classId);

  Future<void> addStudents(String classId, List<Student> students);
  Future<void> renameStudent(String classId, int number, String name);
  Future<void> removeStudent(String classId, int number);
}

class DriftClassRepository implements ClassRepository {
  DriftClassRepository(this._db, [IdGenerator? ids])
    : _ids = ids ?? IdGenerator();

  final AppDatabase _db;
  final IdGenerator _ids;

  @override
  Stream<List<ClassOverview>> watchOverviews() {
    return _db
        .customSelect(
          'SELECT c.id, c.name, '
          '(SELECT COUNT(*) FROM students s WHERE s.class_id = c.id) '
          'AS student_count, '
          '(SELECT COUNT(*) FROM exams e WHERE e.class_id = c.id) '
          'AS test_count '
          'FROM school_classes c ORDER BY c.name COLLATE NOCASE',
          readsFrom: {_db.schoolClasses, _db.students, _db.exams},
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              ClassOverview(
                id: row.read<String>('id'),
                name: row.read<String>('name'),
                studentCount: row.read<int>('student_count'),
                testCount: row.read<int>('test_count'),
              ),
          ],
        );
  }

  @override
  Stream<SchoolClass?> watchClass(String classId) {
    final classQuery = _db.select(_db.schoolClasses)
      ..where((c) => c.id.equals(classId));
    final studentQuery = _db.select(_db.students)
      ..where((s) => s.classId.equals(classId));
    // Re-read both whenever either table changes.
    return _db
        .customSelect('SELECT 1', readsFrom: {_db.schoolClasses, _db.students})
        .watch()
        .asyncMap((_) async {
          final row = await classQuery.getSingleOrNull();
          if (row == null) return null;
          final students = await studentQuery.get();
          return SchoolClass(
            id: row.id,
            name: row.name,
            gradingPolicyId: row.gradingPolicy,
            subjectGroupId: row.subjectGroup,
            students: [
              for (final s in students) Student(number: s.number, name: s.name),
            ],
          );
        });
  }

  @override
  Future<String> createClass(String name) async {
    final id = _ids.next();
    await _db
        .into(_db.schoolClasses)
        .insert(
          SchoolClassesCompanion.insert(
            id: id,
            name: name,
            createdAt: DateTime.now(),
          ),
        );
    return id;
  }

  @override
  Future<void> renameClass(String classId, String name) =>
      (_db.update(_db.schoolClasses)..where((c) => c.id.equals(classId))).write(
        SchoolClassesCompanion(name: Value(name)),
      );

  @override
  Future<void> setGrading(
    String classId, {
    required String policyId,
    required String? subjectGroupId,
  }) =>
      (_db.update(_db.schoolClasses)..where((c) => c.id.equals(classId))).write(
        SchoolClassesCompanion(
          gradingPolicy: Value(policyId),
          subjectGroup: Value(subjectGroupId),
        ),
      );

  @override
  Future<void> deleteClass(String classId) =>
      (_db.delete(_db.schoolClasses)..where((c) => c.id.equals(classId))).go();

  @override
  Future<void> addStudents(String classId, List<Student> students) => _db.batch(
    (batch) => batch.insertAll(_db.students, [
      for (final s in students)
        StudentsCompanion.insert(
          classId: classId,
          number: s.number,
          name: s.name,
        ),
    ]),
  );

  @override
  Future<void> renameStudent(String classId, int number, String name) =>
      (_db.update(_db.students)
            ..where((s) => s.classId.equals(classId) & s.number.equals(number)))
          .write(StudentsCompanion(name: Value(name)));

  @override
  Future<void> removeStudent(String classId, int number) => (_db.delete(
    _db.students,
  )..where((s) => s.classId.equals(classId) & s.number.equals(number))).go();
}
