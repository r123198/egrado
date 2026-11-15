import 'package:egrado/class_record/class_record_fill.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/exam_result.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/grading/grading_scheme.dart';
import 'package:egrado/grading/term_grade.dart';

/// Turns a class's tagged tests and scanned papers into what the grade
/// calculator and the class-record filler need. The Highest Possible
/// Score is the number of questions; a test whose answer key isn't
/// finished doesn't count yet.

/// [tag] as it applies under [scheme], or null when the scheme has no
/// such category (the class switched rules after the test was tagged).
///
/// DepEd exams carry over between DepEd orders: under DO 015 a Quarterly
/// Assessment counts as the Term Exam; under DO 8 every exam is the
/// Quarterly Assessment. Grades and the class-record fill use this rule.
GradeTag? effectiveTag(GradeTag tag, GradingScheme scheme) {
  if (scheme.leaf(tag.categoryId) != null) return tag;
  if (!DepEdCategory.examIds.contains(tag.categoryId)) return null;
  for (final id in const [
    DepEdCategory.quarterlyAssessment,
    DepEdCategory.termExam,
  ]) {
    if (scheme.leaf(id) != null) return tag.copyWith(categoryId: id);
  }
  return null;
}

/// True when [exam] is counted toward something [scheme] doesn't have:
/// a period past its last (Quarter 4 after switching to three terms), or
/// a category from other rules (Written Work after switching to college).
bool isOutsideScheme(Exam exam, GradingScheme scheme) {
  final tag = exam.gradeTag;
  if (tag == null) return false;
  return tag.period > scheme.periodCount || effectiveTag(tag, scheme) == null;
}

Map<int, int> _scoresOf(Exam exam, List<ExamResult> results) => {
  for (final r in results)
    if (r.examId == exam.id) r.studentNumber: scoreAnswers(exam, r.answers),
};

/// Every counted test with a finished key, by grading period, ready for
/// [computePeriodGrades].
Map<int, List<GradedActivity>> gradedActivities(
  GradingScheme scheme,
  List<Exam> exams,
  List<ExamResult> results,
) {
  final byPeriod = <int, List<GradedActivity>>{};
  for (final exam in exams) {
    final tag = exam.gradeTag;
    if (tag == null || !exam.hasCompleteKey) continue;
    final effective = effectiveTag(tag, scheme);
    if (effective == null) continue;
    (byPeriod[tag.period] ??= []).add(
      GradedActivity(
        categoryId: effective.categoryId,
        highestScore: exam.questionCount,
        scores: _scoresOf(exam, results),
      ),
    );
  }
  return byPeriod;
}

/// Every counted test that has at least one scanned paper, oldest first,
/// so they fill the class record's columns in the order they were given.
/// A test with an unfinished key comes with HPS 0, so the fill reports it
/// instead of writing a wrong Highest Possible Score. Only DepEd
/// categories have a place in an E-Class Record; other tests are left out.
List<RecordActivity> recordActivities(
  GradingScheme scheme,
  List<Exam> exams,
  List<ExamResult> results,
) {
  final counted = [
    for (final e in exams)
      if (e.gradeTag != null) e,
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final activities = <RecordActivity>[];
  for (final exam in counted) {
    final tag = exam.gradeTag;
    final effective = tag == null ? null : effectiveTag(tag, scheme);
    final slot = effective == null ? null : depEdSlot(effective.categoryId);
    final scores = _scoresOf(exam, results);
    if (effective == null || slot == null || scores.isEmpty) continue;
    final (component, examPart) = slot;
    activities.add(
      RecordActivity(
        id: exam.id,
        title: exam.title,
        period: effective.period,
        component: component,
        examPart: examPart,
        highestScore: exam.hasCompleteKey ? exam.questionCount : 0,
        scores: scores,
      ),
    );
  }
  return activities;
}
