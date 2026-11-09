import 'package:drift/native.dart';
import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/data/repositories/class_record_repository.dart';
import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tables exactly as schema version 1 (the released app) created them.
const _v1Schema = [
  'CREATE TABLE school_classes (id TEXT NOT NULL, name TEXT NOT NULL, '
      'created_at INTEGER NOT NULL, PRIMARY KEY (id))',
  'CREATE TABLE students (class_id TEXT NOT NULL REFERENCES '
      'school_classes (id) ON DELETE CASCADE, number INTEGER NOT NULL, '
      'name TEXT NOT NULL, PRIMARY KEY (class_id, number))',
  'CREATE TABLE exams (id TEXT NOT NULL, class_id TEXT NOT NULL REFERENCES '
      'school_classes (id) ON DELETE CASCADE, title TEXT NOT NULL, '
      'question_count INTEGER NOT NULL, choice_count INTEGER NOT NULL, '
      'answer_key TEXT NOT NULL, created_at INTEGER NOT NULL, '
      'PRIMARY KEY (id))',
  'CREATE TABLE exam_results (exam_id TEXT NOT NULL REFERENCES exams (id) '
      'ON DELETE CASCADE, student_number INTEGER NOT NULL, '
      'answers TEXT NOT NULL, scanned_at INTEGER NOT NULL, '
      'PRIMARY KEY (exam_id, student_number))',
  "INSERT INTO school_classes VALUES ('c1', 'Grade 7 – Rizal', 0)",
  "INSERT INTO students VALUES ('c1', 1, 'Dela Cruz, Juan')",
  "INSERT INTO exams VALUES ('e1', 'c1', 'Quiz 1', 5, 4, "
      "'[0,1,2,3,0]', 0)",
  "INSERT INTO exam_results VALUES ('e1', 1, '[0,1,2,3,0]', 0)",
  'PRAGMA user_version = 1',
];

void main() {
  test('upgrading from version 1 keeps every class, test and score', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          for (final sql in _v1Schema) {
            raw.execute(sql);
          }
        },
      ),
    );
    addTearDown(db.close);

    final classes = DriftClassRepository(db);
    final exams = DriftExamRepository(db);
    final records = DriftClassRecordRepository(db);

    final c = await classes.watchClass('c1').first;
    expect(c?.name, 'Grade 7 – Rizal');
    expect(c?.gradingPolicy, do015Sy2026); // default for old classes
    expect(c?.subjectGroup, isNull);

    final exam = await exams.watchExam('e1').first;
    expect(exam?.title, 'Quiz 1');
    expect(exam?.gradeTag, isNull); // old tests count toward nothing

    expect(await records.watchClassResults('c1').first, hasLength(1));

    // The new columns and tables work.
    const tag = GradeTag(period: 1, component: GradeComponent.writtenWork);
    await exams.updateExam(exam!.copyWith(gradeTag: () => tag));
    expect((await exams.watchExam('e1').first)?.gradeTag, tag);
    await records.saveFill('c1', names: {1: 'DELA CRUZ, JUAN'}, placements: {});
    expect(await records.getRecordNames('c1'), {1: 'DELA CRUZ, JUAN'});
    expect(db.schemaVersion, 2);
  });
}
