import 'package:egrado/grading/grading_policy.dart';
import 'package:meta/meta.dart';

/// What a test counts toward in the grade: which term/quarter, and
/// whether it is Written Work, a Performance Task or an exam.
@immutable
class GradeTag {
  const GradeTag({required this.period, required this.component, this.examPart})
    : assert(period >= 1);

  final int period;
  final GradeComponent component;

  /// ST1, ST2, TE or QA when [component] is [GradeComponent.exam].
  final ExamPart? examPart;

  /// "Written Work", "Summative Test 1", …
  String get label => examPart?.label ?? component.label;

  @override
  bool operator ==(Object other) =>
      other is GradeTag &&
      other.period == period &&
      other.component == component &&
      other.examPart == examPart;

  @override
  int get hashCode => Object.hash(period, component, examPart);
}

@immutable
class Exam {
  Exam({
    required this.id,
    required this.classId,
    required this.title,
    required this.questionCount,
    required this.choiceCount,
    required List<int?> answerKey,
    required this.createdAt,
    this.gradeTag,
  }) : answerKey = List.unmodifiable(
         List<int?>.generate(
           questionCount,
           (i) => i < answerKey.length ? answerKey[i] : null,
         ),
       );

  final String id;
  final String classId;
  final String title;
  final int questionCount;
  final int choiceCount;

  /// Correct choice per question; null while the teacher hasn't set it.
  final List<int?> answerKey;
  final DateTime createdAt;

  /// Null when the test doesn't count toward the grade (e.g. practice).
  final GradeTag? gradeTag;

  bool get hasCompleteKey => answerKey.every((c) => c != null);

  Exam copyWith({
    String? title,
    int? questionCount,
    int? choiceCount,
    List<int?>? answerKey,
    GradeTag? Function()? gradeTag,
  }) {
    final choices = choiceCount ?? this.choiceCount;
    return Exam(
      id: id,
      classId: classId,
      title: title ?? this.title,
      questionCount: questionCount ?? this.questionCount,
      choiceCount: choices,
      // Drop key entries that no longer exist after fewer choices.
      answerKey: [
        for (final c in answerKey ?? this.answerKey)
          c != null && c < choices ? c : null,
      ],
      createdAt: createdAt,
      gradeTag: gradeTag == null ? this.gradeTag : gradeTag(),
    );
  }
}
