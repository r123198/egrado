import 'package:egrado/domain/exam.dart';
import 'package:meta/meta.dart';

/// One student's scanned answers for one exam.
///
/// The score is not stored: it is always worked out against the exam's
/// current answer key, so fixing a key re-grades every paper.
@immutable
class ExamResult {
  ExamResult({
    required this.examId,
    required this.studentNumber,
    required List<int?> answers,
    required this.scannedAt,
  }) : answers = List.unmodifiable(answers);

  final String examId;
  final int studentNumber;

  /// Chosen bubble per question; null for blank or unreadable.
  final List<int?> answers;
  final DateTime scannedAt;
}

/// Number of answers matching the key. Questions without a key entry
/// don't count for anyone.
int scoreAnswers(Exam exam, List<int?> answers) {
  var score = 0;
  for (var q = 0; q < exam.questionCount; q++) {
    final key = exam.answerKey[q];
    if (key != null && q < answers.length && answers[q] == key) score++;
  }
  return score;
}

/// Questions that have a key entry and therefore count towards the score.
int gradableQuestions(Exam exam) =>
    exam.answerKey.where((c) => c != null).length;
