import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/domain/exam_result.dart';

import 'fixtures.dart';

/// Puts [testClass] and the 5-question [testExam] (ids `c1`, `e1`) into
/// [db], plus any [results].
Future<void> seedSchool(
  AppDatabase db, {
  List<int?> key = const [0, 1, 2, 3, 0],
  List<ExamResult> results = const [],
}) async {
  final exam = testExam(key: key);
  await db
      .into(db.schoolClasses)
      .insert(
        SchoolClassesCompanion.insert(
          id: testClass.id,
          name: testClass.name,
          createdAt: DateTime(2026),
        ),
      );
  for (final s in testClass.students) {
    await db
        .into(db.students)
        .insert(
          StudentsCompanion.insert(
            classId: testClass.id,
            number: s.number,
            name: s.name,
          ),
        );
  }
  await db
      .into(db.exams)
      .insert(
        ExamsCompanion.insert(
          id: exam.id,
          classId: exam.classId,
          title: exam.title,
          questionCount: exam.questionCount,
          choiceCount: exam.choiceCount,
          answerKey: exam.answerKey,
          createdAt: exam.createdAt,
        ),
      );
  for (final r in results) {
    await db
        .into(db.examResults)
        .insert(
          ExamResultsCompanion.insert(
            examId: r.examId,
            studentNumber: r.studentNumber,
            answers: r.answers,
            scannedAt: r.scannedAt,
          ),
        );
  }
}
