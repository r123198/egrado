import 'package:drift/native.dart';
import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/data/repositories/class_record_repository.dart';
import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/grading/scheme_presets.dart';
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

/// Version 2 (DepEd grading): a component and an exam part per test.
const _v2Schema = [
  'CREATE TABLE school_classes (id TEXT NOT NULL, name TEXT NOT NULL, '
      'created_at INTEGER NOT NULL, grading_policy TEXT, subject_group TEXT, '
      'PRIMARY KEY (id))',
  'CREATE TABLE students (class_id TEXT NOT NULL REFERENCES '
      'school_classes (id) ON DELETE CASCADE, number INTEGER NOT NULL, '
      'name TEXT NOT NULL, PRIMARY KEY (class_id, number))',
  'CREATE TABLE exams (id TEXT NOT NULL, class_id TEXT NOT NULL REFERENCES '
      'school_classes (id) ON DELETE CASCADE, title TEXT NOT NULL, '
      'question_count INTEGER NOT NULL, choice_count INTEGER NOT NULL, '
      'answer_key TEXT NOT NULL, created_at INTEGER NOT NULL, '
      'grading_period INTEGER, grade_component TEXT, exam_part TEXT, '
      'PRIMARY KEY (id))',
  'CREATE TABLE exam_results (exam_id TEXT NOT NULL REFERENCES exams (id) '
      'ON DELETE CASCADE, student_number INTEGER NOT NULL, '
      'answers TEXT NOT NULL, scanned_at INTEGER NOT NULL, '
      'PRIMARY KEY (exam_id, student_number))',
  'CREATE TABLE record_names (class_id TEXT NOT NULL REFERENCES '
      'school_classes (id) ON DELETE CASCADE, student_number INTEGER NOT NULL, '
      'student_name TEXT NOT NULL, record_name TEXT NOT NULL, '
      'PRIMARY KEY (class_id, student_number))',
  'CREATE TABLE record_placements (exam_id TEXT NOT NULL REFERENCES exams '
      '(id) ON DELETE CASCADE, sheet_name TEXT NOT NULL, '
      'column_index INTEGER NOT NULL, highest_score INTEGER NOT NULL, '
      'PRIMARY KEY (exam_id))',
  "INSERT INTO school_classes VALUES ('c1', 'Grade 7 – Rizal', 0, "
      "'do8_2015', 'math_science')",
  "INSERT INTO students VALUES ('c1', 1, 'Dela Cruz, Juan')",
  "INSERT INTO exams VALUES ('ww', 'c1', 'Quiz', 5, 4, '[0,1,2,3,0]', 0, "
      "1, 'writtenWork', NULL)",
  "INSERT INTO exams VALUES ('te', 'c1', 'Exam', 5, 4, '[0,1,2,3,0]', 0, "
      "2, 'exam', 'termExam')",
  "INSERT INTO exams VALUES ('ex', 'c1', 'Old exam', 5, 4, '[0,1,2,3,0]', 0, "
      "1, 'exam', NULL)",
  "INSERT INTO exams VALUES ('no', 'c1', 'Practice', 5, 4, '[0,1,2,3,0]', 0, "
      'NULL, NULL, NULL)',
  "INSERT INTO exam_results VALUES ('te', 1, '[0,1,2,3,0]', 0)",
  "INSERT INTO record_placements VALUES ('ww', 'MATH_Q1', 6, 5)",
  'PRAGMA user_version = 2',
];

AppDatabase _opened(List<String> schema) => AppDatabase(
  NativeDatabase.memory(
    setup: (raw) {
      for (final sql in schema) {
        raw.execute(sql);
      }
    },
  ),
);

void main() {
  test(
    'upgrading from version 2 keeps what every test counts toward',
    () async {
      final db = _opened(_v2Schema);
      addTearDown(db.close);
      final classes = DriftClassRepository(db);
      final exams = DriftExamRepository(db);

      Future<GradeTag?> tagOf(String id) async =>
          (await exams.watchExam(id).first)?.gradeTag;

      expect(
        await tagOf('ww'),
        const GradeTag(period: 1, categoryId: DepEdCategory.writtenWork),
      );
      expect(
        await tagOf('te'),
        const GradeTag(period: 2, categoryId: DepEdCategory.termExam),
      );
      expect(
        await tagOf('ex'),
        const GradeTag(period: 1, categoryId: DepEdCategory.exam),
      );
      expect(await tagOf('no'), isNull);

      final c = await classes.watchClass('c1').first;
      expect(c?.gradingPolicy, do8s2015);
      expect(c?.subjectGroup?.id, 'math_science');
      expect(c?.customScheme, isNull);

      // Scores and remembered class-record columns survive the rebuild.
      final records = DriftClassRecordRepository(db);
      expect(await records.watchClassResults('c1').first, hasLength(1));
      expect(await records.getPlacements('c1'), contains('ww'));

      // The new column works.
      await classes.setGrading(
        'c1',
        policyId: do8s2015.id,
        subjectGroupId: null,
        customScheme: collegeScheme,
      );
      final custom = (await classes.watchClass('c1').first)?.customScheme;
      expect(custom?.id, collegeScheme.id);
      expect(custom?.leaves.map((l) => l.id), [
        'quizzes',
        'assignments',
        'term_exam',
      ]);
    },
  );

  test('a saved scheme that cannot be read falls back to DepEd', () async {
    final db = _opened(_v2Schema);
    addTearDown(db.close);
    final classes = DriftClassRepository(db);
    await classes.watchClass('c1').first; // run the migration
    await db.customStatement(
      "UPDATE school_classes SET custom_scheme = '{not json'",
    );
    final c = await classes.watchClass('c1').first;
    expect(c?.customScheme, isNull);
    expect(c?.scheme.isDepEd, isTrue);
  });

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
    const tag = GradeTag(period: 1, categoryId: DepEdCategory.writtenWork);
    await exams.updateExam(exam!.copyWith(gradeTag: () => tag));
    expect((await exams.watchExam('e1').first)?.gradeTag, tag);
    await records.saveFill('c1', names: {1: 'DELA CRUZ, JUAN'}, placements: {});
    expect(await records.getRecordNames('c1'), {1: 'DELA CRUZ, JUAN'});
    expect(db.schemaVersion, 3);
  });
}
