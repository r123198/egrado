import 'package:egrado/data/repositories/class_record_repository.dart';
import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/data/repositories/workspace_repository.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/exam_result.dart';
import 'package:egrado/domain/grade_book.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/domain/teaching_level.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/grading/grading_scheme.dart';
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
    required WorkspaceRepository workspace,
  }) {
    listen(workspace.watchLevel(), (level) {
      _workspaceLevel = level;
      notifyListeners();
    });
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
  TeachingLevel? _workspaceLevel;

  /// Which kind of rules this class picks from: what it already follows,
  /// or the teacher's workspace while nothing is chosen yet.
  TeachingLevel get level {
    if (customScheme != null) return TeachingLevel.college;
    if (subject != null) return TeachingLevel.depEd;
    return _workspaceLevel ?? TeachingLevel.depEd;
  }

  bool get isLoading => !_isClassLoaded || _exams == null || _results == null;

  /// Null after the class was deleted.
  SchoolClass? get schoolClass => _schoolClass;

  /// The DepEd order the class follows (or last followed, once it has
  /// its own scheme).
  GradingPolicy get policy => _schoolClass?.gradingPolicy ?? policyById(null);

  /// The DepEd subject; null until picked, and unused with a custom scheme.
  SubjectGroup? get subject => _schoolClass?.subjectGroup;

  /// The rules in force. Only good for grades once [hasGradingSetup].
  GradingScheme get scheme =>
      _schoolClass?.scheme ??
      depEdScheme(policy, policy.subjects.first.weights);

  /// The teacher's own scheme, when the class isn't on DepEd's rules.
  GradingScheme? get customScheme => _schoolClass?.customScheme;

  /// False until the teacher picks a subject or their own scheme.
  bool get hasGradingSetup => _schoolClass?.hasGradingSetup ?? false;

  int get period => _period.clamp(1, scheme.periodCount);

  void selectPeriod(int value) {
    _period = value.clamp(1, scheme.periodCount);
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

  /// Tests counted toward a period or category these rules don't have
  /// (Quarter 4 after switching to three terms, Written Work after
  /// switching to college grading).
  int get outOfRangeCount => (_exams ?? const <Exam>[])
      .where((e) => isOutsideScheme(e, scheme))
      .length;

  /// Tests counted here whose answer key isn't finished.
  int get unkeyedCount => periodExams.where((e) => !e.hasCompleteKey).length;

  List<GradeLine> get lines {
    final schoolClass = _schoolClass;
    if (schoolClass == null || !hasGradingSetup) return const [];
    final grades = computePeriodGrades(
      scheme: scheme,
      period: period,
      studentNumbers: schoolClass.students.map((s) => s.number),
      activitiesByPeriod: gradedActivities(
        scheme,
        _exams ?? const [],
        _results ?? const [],
      ),
    );
    return [
      for (var i = 0; i < grades.length; i++)
        GradeLine(student: schoolClass.students[i], grade: grades[i]),
    ];
  }

  /// Categories with weight but no test yet in the selected period.
  List<GradeCategory> get missingComponents =>
      lines.firstOrNull?.grade.missingComponents ?? const [];

  /// True when this period builds on the one before and that one has no
  /// grade yet.
  bool get needsPreviousPeriod =>
      lines.firstOrNull?.grade.needsPreviousPeriod ?? false;

  /// Follow a DepEd order. Clears the class's own scheme, if any.
  Future<bool> setGrading(GradingPolicy policy, SubjectGroup? subject) =>
      runCommand(
        () => _classes.setGrading(
          classId,
          policyId: policy.id,
          subjectGroupId: subject?.id,
        ),
      );

  /// Follow the teacher's own [scheme] (college, or any edited rules).
  /// The DepEd choice is kept underneath in case they switch back.
  Future<bool> setCustomScheme(GradingScheme scheme) => runCommand(
    () => _classes.setGrading(
      classId,
      policyId: policy.id,
      subjectGroupId: subject?.id,
      customScheme: scheme,
    ),
  );
}
