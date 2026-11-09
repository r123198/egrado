import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/omr/sheet_layout.dart';
import 'package:egrado/ui/core/view_model.dart';

enum FormSaveOutcome { saved, invalid, failed }

/// One choice under "Counts toward": not counted, WW, PT, or an exam part.
class GradeKind {
  const GradeKind(this.label, [this.component, this.examPart]);

  static const notCounted = GradeKind('Not counted');

  final String label;
  final GradeComponent? component;
  final ExamPart? examPart;

  bool matches(GradeTag? tag) =>
      tag?.component == component && tag?.examPart == examPart;
}

/// Creating a new test, or changing an existing test's settings.
class ExamFormViewModel extends ViewModel {
  ExamFormViewModel({
    required this.classId,
    required this._exams,
    ClassRepository? classes,
    Exam? existing,
  }) : _existing = existing,
       _title = existing?.title ?? '',
       _questions = existing?.questionCount ?? 20,
       _choices = existing?.choiceCount ?? 4,
       _tag = existing == null ? _defaultTag : existing.gradeTag {
    if (classes != null) {
      listen(classes.watchClass(classId), (c) {
        _policy = c?.gradingPolicy ?? _policy;
        notifyListeners();
      });
    }
    if (existing == null) {
      // A new test counts toward the same term as the latest counted one.
      listen(_exams.watchOverviews(classId), (list) {
        if (_tagTouched) return;
        for (final o in list) {
          final period = o.exam.gradeTag?.period;
          if (period != null) {
            _tag = GradeTag(
              period: period,
              component: _tag?.component ?? GradeComponent.writtenWork,
              examPart: _tag?.examPart,
            );
            notifyListeners();
            return;
          }
        }
      });
    }
  }

  static const _defaultTag = GradeTag(
    period: 1,
    component: GradeComponent.writtenWork,
  );

  static const quickCounts = [10, 15, 20, 25, 30, 40, 50, 60];
  static const choiceOptions = [3, 4, 5];

  final String classId;
  final ExamRepository _exams;
  final Exam? _existing;

  String _title;
  int _questions;
  int _choices;
  bool _showTitleError = false;
  String? _savedExamId;
  GradeTag? _tag;
  bool _tagTouched = false;
  GradingPolicy _policy = policyById(null);

  GradingPolicy get policy => _policy;

  /// Null when the test doesn't count toward the grade.
  GradeTag? get gradeTag => _tag;

  /// The selected term/quarter (kept even while "Not counted").
  int get period => (_tag?.period ?? _lastPeriod).clamp(1, _policy.periodCount);
  int _lastPeriod = 1;

  List<GradeKind> get kinds => [
    const GradeKind('Written Work', GradeComponent.writtenWork),
    const GradeKind('Performance Task', GradeComponent.performanceTask),
    for (final part in _policy.examParts.keys)
      GradeKind(part.label, GradeComponent.exam, part),
    GradeKind.notCounted,
  ];

  GradeKind get kind => kinds.firstWhere(
    (k) => k.matches(_tag),
    orElse: () => GradeKind.notCounted,
  );

  void setPeriod(int value) {
    _tagTouched = true;
    _lastPeriod = value.clamp(1, _policy.periodCount);
    final tag = _tag;
    if (tag != null) {
      _tag = GradeTag(
        period: _lastPeriod,
        component: tag.component,
        examPart: tag.examPart,
      );
    }
    notifyListeners();
  }

  void setKind(GradeKind value) {
    _tagTouched = true;
    final component = value.component;
    _lastPeriod = period;
    _tag = component == null
        ? null
        : GradeTag(
            period: _lastPeriod,
            component: component,
            examPart: value.examPart,
          );
    notifyListeners();
  }

  bool get isNew => _existing == null;
  String get initialTitle => _existing?.title ?? '';
  int get questions => _questions;
  int get choices => _choices;
  bool get showTitleError => _showTitleError;

  /// Id of the test after a successful save.
  String? get savedExamId => _savedExamId;

  bool get canDecrease => _questions > 1;
  bool get canIncrease => _questions < kMaxQuestions;

  /// Editing down the question count drops questions from the scores.
  bool get removesQuestions => (_existing?.questionCount ?? 0) > _questions;

  void setTitle(String value) {
    _title = value;
    if (_showTitleError && value.trim().isNotEmpty) {
      _showTitleError = false;
      notifyListeners();
    }
  }

  void setQuestions(int value) {
    _questions = value.clamp(1, kMaxQuestions);
    notifyListeners();
  }

  void setChoices(int value) {
    _choices = value.clamp(kMinChoices, kMaxChoices);
    notifyListeners();
  }

  Future<FormSaveOutcome> save() async {
    final title = _title.trim();
    if (title.isEmpty) {
      _showTitleError = true;
      notifyListeners();
      return FormSaveOutcome.invalid;
    }
    final existing = _existing;
    final ok = await runCommand(() async {
      if (existing == null) {
        _savedExamId = await _exams.createExam(
          classId: classId,
          title: title,
          questionCount: _questions,
          choiceCount: _choices,
          gradeTag: _clampedTag,
        );
      } else {
        await _exams.updateExam(
          existing.copyWith(
            title: title,
            questionCount: _questions,
            choiceCount: _choices,
            gradeTag: () => _clampedTag,
          ),
        );
        _savedExamId = existing.id;
      }
    });
    return ok ? FormSaveOutcome.saved : FormSaveOutcome.failed;
  }

  /// The tag with its period inside the policy's range.
  GradeTag? get _clampedTag => switch (_tag) {
    final t? => GradeTag(
      period: t.period.clamp(1, _policy.periodCount),
      component: t.component,
      examPart: t.examPart,
    ),
    null => null,
  };
}
