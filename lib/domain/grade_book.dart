import 'package:egrado/class_record/class_record_fill.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/exam_result.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/grading/term_grade.dart';

/// Turns a class's tagged tests and scanned papers into what the grade
/// calculator and the class-record filler need. The Highest Possible
/// Score is the number of questions; a test whose answer key isn't
/// finished doesn't count yet.

/// [tag] as it applies under [policy]: a class can switch between DO 8
/// and DO 015 after tests were tagged. Under DO 015 a Quarterly Assessment
/// counts as the Term Exam; under DO 8 every exam is the Quarterly
/// Assessment. Grades and the class-record fill use the same rule.
GradeTag effectiveTag(GradeTag tag, GradingPolicy policy) {
  final part = tag.examPart;
  if (tag.component != GradeComponent.exam ||
      (part != null && policy.examParts.containsKey(part))) {
    return tag;
  }
  final parts = policy.examParts.keys;
  final mapped = parts.contains(ExamPart.quarterlyAssessment)
      ? ExamPart.quarterlyAssessment
      : ExamPart.termExam;
  return GradeTag(
    period: tag.period,
    component: tag.component,
    examPart: mapped,
  );
}

/// True when [exam] counts toward a period that [policy] doesn't have
/// (e.g. Quarter 4 after switching to three terms).
bool isOutsidePolicy(Exam exam, GradingPolicy policy) =>
    (exam.gradeTag?.period ?? 0) > policy.periodCount;

Map<int, int> _scoresOf(Exam exam, List<ExamResult> results) => {
  for (final r in results)
    if (r.examId == exam.id) r.studentNumber: scoreAnswers(exam, r.answers),
};

/// Tests counted toward [period], ready for [computeTermGrades].
List<GradedActivity> gradedActivities(
  int period,
  GradingPolicy policy,
  List<Exam> exams,
  List<ExamResult> results,
) => [
  for (final exam in exams)
    if (exam.gradeTag case final tag?
        when tag.period == period && exam.hasCompleteKey)
      if (effectiveTag(tag, policy) case final t)
        GradedActivity(
          component: t.component,
          examPart: t.examPart,
          highestScore: exam.questionCount,
          scores: _scoresOf(exam, results),
        ),
];

/// Every counted test that has at least one scanned paper, oldest first,
/// so they fill the class record's columns in the order they were given.
/// A test with an unfinished key comes with HPS 0, so the fill reports it
/// instead of writing a wrong Highest Possible Score.
List<RecordActivity> recordActivities(
  GradingPolicy policy,
  List<Exam> exams,
  List<ExamResult> results,
) {
  final counted = [
    for (final e in exams)
      if (e.gradeTag != null) e,
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return [
    for (final exam in counted)
      if (_scoresOf(exam, results) case final scores when scores.isNotEmpty)
        if (effectiveTag(exam.gradeTag!, policy) case final t)
          RecordActivity(
            id: exam.id,
            title: exam.title,
            period: t.period,
            component: t.component,
            examPart: t.examPart,
            highestScore: exam.hasCompleteKey ? exam.questionCount : 0,
            scores: scores,
          ),
  ];
}
