import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/data/repositories/result_repository.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

void main() {
  late AppDatabase db;
  late ClassRepository classes;
  late ExamRepository exams;
  late ResultRepository results;

  setUp(() {
    db = memoryDatabase();
    classes = DriftClassRepository(db);
    exams = DriftExamRepository(db);
    results = DriftResultRepository(db);
  });
  tearDown(() => db.close());

  Future<(String, String)> seed() async {
    final classId = await classes.createClass('Grade 7 – Rizal');
    await classes.addStudents(classId, testClass.students);
    final examId = await exams.createExam(
      classId: classId,
      title: 'Quiz',
      questionCount: 5,
      choiceCount: 4,
    );
    return (classId, examId);
  }

  group('ClassRepository', () {
    test('overview counts students and tests, sorted by name', () async {
      await seed();
      await classes.createClass('aardvark section');
      final list = await classes.watchOverviews().first;
      expect(list.map((c) => c.name), ['aardvark section', 'Grade 7 – Rizal']);
      expect(list[1].studentCount, 3);
      expect(list[1].testCount, 1);
    });

    test('a class comes with its students, sorted by number', () async {
      final (classId, _) = await seed();
      await classes.addStudents(classId, const [Student(number: 9, name: 'Z')]);
      await classes.removeStudent(classId, 2);
      await classes.renameStudent(classId, 1, 'Cruz, Juan D.');
      final c = (await classes.watchClass(classId).first)!;
      expect(c.students.map((s) => '${s.number} ${s.name}'), [
        '1 Cruz, Juan D.',
        '3 Reyes, Ana',
        '9 Z',
      ]);
    });

    test('watching a class sees new students as they are added', () async {
      final (classId, _) = await seed();
      final sizes = classes
          .watchClass(classId)
          .map((c) => c?.students.length)
          .take(2)
          .toList();
      await Future<void>.delayed(Duration.zero);
      await classes.addStudents(classId, const [Student(number: 4, name: 'D')]);
      expect(await sizes, [3, 4]);
    });

    test('deleting a class removes its students, tests and scores', () async {
      final (classId, examId) = await seed();
      await results.saveResult(testResult(1, [0], exam: examId));
      await classes.deleteClass(classId);
      expect(await classes.watchClass(classId).first, isNull);
      expect(await exams.watchExam(examId).first, isNull);
      expect(await results.getResult(examId, 1), isNull);
    });
  });

  group('ExamRepository', () {
    test('a new test has an empty key the length of the test', () async {
      final (_, examId) = await seed();
      final exam = (await exams.watchExam(examId).first)!;
      expect(exam.answerKey, [null, null, null, null, null]);
      expect(exam.hasCompleteKey, isFalse);
    });

    test('saves the answer key and counts checked papers', () async {
      final (classId, examId) = await seed();
      final exam = (await exams.watchExam(examId).first)!;
      await exams.updateExam(exam.copyWith(answerKey: [0, 1, 2, 3, null]));
      await results.saveResult(testResult(2, [0], exam: examId));

      final overview = (await exams.watchOverviews(classId).first).single;
      expect(overview.exam.answerKey, [0, 1, 2, 3, null]);
      expect(overview.checkedCount, 1);
    });

    test('all tests across classes come with their class name', () async {
      await seed();
      final other = await classes.createClass('Grade 8');
      await exams.createExam(
        classId: other,
        title: 'Math',
        questionCount: 10,
        choiceCount: 4,
      );
      final all = await exams.watchAllOverviews().first;
      expect(all.map((o) => '${o.exam.title} · ${o.className}'), [
        'Math · Grade 8',
        'Quiz · Grade 7 – Rizal',
      ]);
    });

    test('deleting a test removes only its scores', () async {
      final (classId, examId) = await seed();
      await results.saveResult(testResult(1, [0], exam: examId));
      await exams.deleteExam(examId);
      expect(await results.getResult(examId, 1), isNull);
      expect(await classes.watchClass(classId).first, isNotNull);
    });
  });

  group('ResultRepository', () {
    test('a rescan replaces the earlier paper for that student', () async {
      final (_, examId) = await seed();
      await results.saveResult(testResult(2, [0, 0], exam: examId));
      await results.saveResult(testResult(2, [1, null], exam: examId));
      final list = await results.watchResults(examId).first;
      expect(list.single.answers, [1, null]);
    });

    test('reassigning a paper moves it to the other student', () async {
      final (_, examId) = await seed();
      await results.saveResult(testResult(1, [0], exam: examId));
      await results.saveResult(testResult(3, [0], exam: examId), replacing: 1);
      final list = await results.watchResults(examId).first;
      expect(list.map((r) => r.studentNumber), [3]);
    });

    test('a paper survives its student being removed', () async {
      final (classId, examId) = await seed();
      await results.saveResult(testResult(2, [0], exam: examId));
      await classes.removeStudent(classId, 2);
      expect(await results.getResult(examId, 2), isNotNull);
    });
  });
}
