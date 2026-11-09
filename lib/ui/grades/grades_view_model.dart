import 'package:egrado/data/repositories/class_record_repository.dart';
import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/exam_result.dart';
import 'package:egrado/domain/grade_book.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/grading/term_grade.dart';
import 'package:egrado/ui/core/view_model.dart';

/// One learner's line on the Grades screen.
class GradeLine {
  const GradeLine({required this.student, required this.grade});

  final Student student;
  final TermGrade grade;
}

/// A class's grades per term, worked out live from the scanned tests.
class GradesViewModel extends ViewModel {
  GradesViewModel({
    required this.classId,
    required this._classes,
    required ExamRepository exams,
    required ClassRecordRepository records,
  }) {
    listen(_classes.watchClass(classId), (c) {
      _schoolClass = c;
      _isClassLoaded = true;
      notifyListeners();
    });
    listen(exams.watchOverviews(classId), (list) {
      _exams = [for (final o in list) o.exam];
      notifyListeners();
    });
    listen(records.watchClassResults(classId), (list) {
      _results = list;
      notifyListeners();
    });
  }

  final String classId;
  final ClassRepository _classes;

  SchoolClass? _schoolClass;
  bool _isClassLoaded = false;
  List<Exam>? _exams;
  List<ExamResult>? _results;
  int _period = 1;

  bool get isLoading => !_isClassLoaded || _exams == null || _results == null;

  /// Null after the class was deleted.
  SchoolClass? get schoolClass => _schoolClass;

  GradingPolicy get policy => _schoolClass?.gradingPolicy ?? policyById(null);

  /// Null until the teacher picks the subject.
  SubjectGroup? get subject => _schoolClass?.subjectGroup;

  int get period => _period.clamp(1, policy.periodCount);

  void selectPeriod(int value) {
    _period = value.clamp(1, policy.periodCount);
    notifyListeners();
  }

  /// Tests counted toward the selected period.
  List<Exam> get periodExams => [
    for (final e in _exams ?? const <Exam>[])
      if (e.gradeTag?.period == period) e,
  ];

  /// Tests that don't count toward any grade yet.
  int get untaggedCount =>
      (_exams ?? const <Exam>[]).where((e) => e.gradeTag == null).length;

  /// Tests set to a term/quarter this class's rules don't have (e.g.
  /// Quarter 4 after switching to three terms).
  int get outOfRangeCount => (_exams ?? const <Exam>[])
      .where((e) => isOutsidePolicy(e, policy))
      .length;

  /// Tests counted here whose answer key isn't finished.
  int get unkeyedCount => periodExams.where((e) => !e.hasCompleteKey).length;

  List<GradeLine> get lines {
    final schoolClass = _schoolClass;
    final subject = this.subject;
    if (schoolClass == null || subject == null) return const [];
    final grades = computeTermGrades(
      policy: policy,
      weights: subject.weights,
      studentNumbers: schoolClass.students.map((s) => s.number),
      activities: gradedActivities(
        period,
        policy,
        _exams ?? const [],
        _results ?? const [],
      ),
    );
    return [
      for (var i = 0; i < grades.length; i++)
        GradeLine(student: schoolClass.students[i], grade: grades[i]),
    ];
  }

  /// Components with weight but no test yet in the selected period.
  List<GradeComponent> get missingComponents {
    final first = lines.firstOrNull;
    return first?.grade.missingComponents ?? const [];
  }

  Future<bool> setGrading(GradingPolicy policy, SubjectGroup? subject) =>
      runCommand(
        () => _classes.setGrading(
          classId,
          policyId: policy.id,
          subjectGroupId: subject?.id,
        ),
      );
}
