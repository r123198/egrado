import 'package:egrado/domain/exam_result.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

void main() {
  group('scoring', () {
    test('counts answers that match the key', () {
      expect(scoreAnswers(testExam(), [0, 1, 2, 3, 0]), 5);
      expect(scoreAnswers(testExam(), [0, 0, 2, null, 1]), 2);
    });

    test('questions without a key entry count for no one', () {
      final exam = testExam(key: [0, null, 2, 3, 0]);
      expect(scoreAnswers(exam, [0, 1, 2, 3, 0]), 4);
      expect(gradableQuestions(exam), 4);
    });

    test('fixing the key re-grades saved answers', () {
      final answers = [1, 1, 2, 3, 0];
      expect(scoreAnswers(testExam(), answers), 4);
      expect(scoreAnswers(testExam(key: [1, 1, 2, 3, 0]), answers), 5);
    });

    test('tolerates answers shorter than the test', () {
      expect(scoreAnswers(testExam(), [0, 1]), 2);
    });
  });

  group('Exam', () {
    test('pads or trims the key to the question count', () {
      expect(testExam(key: [0]).answerKey, [0, null, null, null, null]);
      expect(testExam().copyWith(questionCount: 3).answerKey, [0, 1, 2]);
    });

    test('drops key letters that no longer exist with fewer choices', () {
      final exam = testExam().copyWith(choiceCount: 3);
      expect(exam.answerKey, [0, 1, 2, null, 0]);
      expect(exam.hasCompleteKey, isFalse);
    });
  });

  group('SchoolClass', () {
    final c = SchoolClass(
      id: 'c',
      name: 'x',
      students: const [
        Student(number: 3, name: 'C'),
        Student(number: 1, name: 'A'),
      ],
    );

    test('keeps students sorted by number', () {
      expect(c.students.map((s) => s.number), [1, 3]);
    });

    test('next free number fills gaps first', () {
      expect(c.nextFreeNumber, 2);
    });

    test('numbers new students into gaps, then onward', () {
      expect(
        c.numberNewStudents(['B', 'D', 'E']).map((s) => '${s.number}${s.name}'),
        ['2B', '4D', '5E'],
      );
    });

    test('stops at the last bubble-able number', () {
      final full = SchoolClass(
        id: 'c',
        name: 'x',
        students: [
          for (var n = 1; n <= 98; n++) Student(number: n, name: '$n'),
        ],
      );
      expect(full.numberNewStudents(['a', 'b', 'c']), hasLength(1));
    });
  });
}
