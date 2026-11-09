import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:egrado/data/database/tables.dart';

part 'app_database.g.dart';

/// The app's offline SQLite database. Everything a teacher enters or scans
/// lives here, on the device.
@DriftDatabase(
  tables: [
    SchoolClasses,
    Students,
    Exams,
    ExamResults,
    RecordNames,
    RecordPlacements,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'egrado'));

  /// Each signed-in teacher gets their own database file, so two teachers
  /// sharing a tablet never see each other's classes.
  AppDatabase.forUser(String uid)
    : super(driftDatabase(name: 'egrado_${_safeFileName(uid)}'));

  static String _safeFileName(String uid) =>
      uid.replaceAll(RegExp('[^A-Za-z0-9_-]'), '_');

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Grading: DepEd policy per class, what each test counts toward,
        // and what was written into the teacher's E-Class Record.
        await m.addColumn(schoolClasses, schoolClasses.gradingPolicy);
        await m.addColumn(schoolClasses, schoolClasses.subjectGroup);
        await m.addColumn(exams, exams.gradingPeriod);
        await m.addColumn(exams, exams.gradeComponent);
        await m.addColumn(exams, exams.examPart);
        await m.createTable(recordNames);
        await m.createTable(recordPlacements);
      }
    },
    // Deleting a class must also delete its students, tests and scores.
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
