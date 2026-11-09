import 'package:drift/native.dart';
import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/exam_result.dart';
import 'package:egrado/domain/school_class.dart';

AppDatabase memoryDatabase() => AppDatabase(NativeDatabase.memory());

final testClass = SchoolClass(
  id: 'c1',
  name: 'Grade 7 – Rizal',
  students: const [
    Student(number: 1, name: 'Dela Cruz, Juan'),
    Student(number: 2, name: 'Santos, María'),
    Student(number: 3, name: 'Reyes, Ana'),
  ],
);

/// 5 questions, key A B C D A.
Exam testExam({List<int?> key = const [0, 1, 2, 3, 0], String id = 'e1'}) =>
    Exam(
      id: id,
      classId: 'c1',
      title: 'Science Quiz',
      questionCount: 5,
      choiceCount: 4,
      answerKey: key,
      createdAt: DateTime(2026, 11, 9),
    );

ExamResult testResult(int student, List<int?> answers, {String exam = 'e1'}) =>
    ExamResult(
      examId: exam,
      studentNumber: student,
      answers: answers,
      scannedAt: DateTime(2026, 11, 9, 10),
    );
