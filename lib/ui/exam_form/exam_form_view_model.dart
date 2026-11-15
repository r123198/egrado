import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/grade_book.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/grading/grading_scheme.dart';
import 'package:egrado/omr/sheet_layout.dart';
import 'package:egrado/ui/core/view_model.dart';

enum FormSaveOutcome { saved, invalid, failed }

/// One choice under "Counts toward": a category of the class's grading
/// scheme, or not counted.
class GradeKind {
  const GradeKind(this.label, [this.categoryId]);

  static const notCounted = GradeKind('Not counted');

  final String label;

  /// Null for [notCounted].
  final String? categoryId;

  bool matches(GradeTag? tag) => tag?.categoryId == categoryId;
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
        _scheme = c?.scheme ?? _scheme;
        _useSchemeDefault();
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
            _tag = _tag?.copyWith(period: period);
            notifyListeners();
            return;
          }
        }
      });
    }
  }

  static const _defaultTag = GradeTag(
    period: 1,
    categoryId: DepEdCategory.writtenWork,
  );

  /// A new test the teacher hasn't tagged yet starts under the scheme's
  /// first category (Written Work for DepEd, Quizzes for college).
  void _useSchemeDefault() {
    final tag = _tag;
    if (!isNew || _tagTouched || tag == null) return;
    if (_scheme.leaf(tag.categoryId) != null) return;
    final first = _scheme.leaves.firstOrNull;
    if (first != null) _tag = tag.copyWith(categoryId: first.id);
  }

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
  GradingScheme _scheme = _fallbackScheme;

  static final _fallbackScheme = depEdScheme(
    do015Sy2026,
    do015Sy2026.subjects.first.weights,
  );

  GradingScheme get scheme => _scheme;

  /// Null when the test doesn't count toward the grade.
  GradeTag? get gradeTag => _tag;

  /// The selected grading period (kept even while "Not counted").
  int get period => (_tag?.period ?? _lastPeriod).clamp(1, _scheme.periodCount);
  int _lastPeriod = 1;

  List<GradeKind> get kinds => [
    for (final leaf in _scheme.leaves) GradeKind(leaf.label, leaf.id),
    GradeKind.notCounted,
  ];

  /// The chosen kind, as these rules count it: a DepEd exam tagged under
  /// another DepEd order shows as the exam it counts as, and a test
  /// counted under a category these rules don't have shows as "Not
  /// counted", which is how it is being graded.
  GradeKind get kind {
    final tag = switch (_tag) {
      final t? => effectiveTag(t, _scheme),
      null => null,
    };
    return kinds.firstWhere(
      (k) => k.matches(tag),
      orElse: () => GradeKind.notCounted,
    );
  }

  /// False for practice tests and for ones these rules can't place.
  bool get isCounted => kind.categoryId != null;

  void setPeriod(int value) {
    _tagTouched = true;
    _lastPeriod = value.clamp(1, _scheme.periodCount);
    _tag = _tag?.copyWith(period: _lastPeriod);
    notifyListeners();
  }

  void setKind(GradeKind value) {
    _tagTouched = true;
    final categoryId = value.categoryId;
    _lastPeriod = period;
    _tag = categoryId == null
        ? null
        : GradeTag(period: _lastPeriod, categoryId: categoryId);
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

  /// The tag with its period inside the scheme's range.
  GradeTag? get _clampedTag =>
      _tag?.copyWith(period: _tag?.period.clamp(1, _scheme.periodCount));
}
