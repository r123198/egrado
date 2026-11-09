import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/data/repositories/result_repository.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/exam_result.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/omr/omr_reading.dart';
import 'package:egrado/ui/core/view_model.dart';

/// A paper's score before saving (fresh scan) or after (opening a saved
/// score). Everything is fixed by tapping — no typing.
class ResultReviewViewModel extends ViewModel {
  /// Review a paper that was just scanned.
  ResultReviewViewModel.scanned({
    required this.examId,
    required OmrReading reading,
    required ExamRepository exams,
    required ClassRepository classes,
    required this._results,
  }) : savedStudent = null,
       _student = reading.studentNumber,
       _answers = [for (final a in reading.answers) a.choice],
       _needsCheck = {
         for (var q = 0; q < reading.answers.length; q++)
           if (reading.answers[q].needsReview) q,
       } {
    _watch(exams, classes);
  }

  /// Open a score that is already saved.
  ResultReviewViewModel.saved({
    required this.examId,
    required int this.savedStudent,
    required ExamRepository exams,
    required ClassRepository classes,
    required this._results,
  }) : _student = savedStudent,
       _answers = null,
       _needsCheck = const {} {
    _watch(exams, classes);
  }

  final String examId;

  /// Set when reviewing a saved score; null for a fresh scan.
  final int? savedStudent;
  final ResultRepository _results;

  Exam? _exam;
  SchoolClass? _schoolClass;
  Map<int, ExamResult>? _saved;
  int? _student;
  List<int?>? _answers;
  Set<int> _needsCheck;

  void _watch(ExamRepository exams, ClassRepository classes) {
    listen(exams.watchExam(examId), (exam) {
      final isFirst = _exam == null && exam != null;
      _exam = exam;
      if (isFirst) {
        listen(classes.watchClass(exam.classId), (c) {
          _schoolClass = c;
          notifyListeners();
        });
      }
      _fillSavedAnswers();
      notifyListeners();
    });
    listen(_results.watchResults(examId), (list) {
      _saved = {for (final r in list) r.studentNumber: r};
      _fillSavedAnswers();
      notifyListeners();
    });
  }

  /// A saved paper is padded/trimmed to the test's current length, since
  /// the test may have been edited after it was scanned.
  void _fillSavedAnswers() {
    final number = savedStudent;
    final exam = _exam;
    final saved = _saved;
    if (_answers != null || number == null || exam == null || saved == null) {
      return;
    }
    final stored = saved[number]?.answers ?? const <int?>[];
    _answers = [
      for (var q = 0; q < exam.questionCount; q++)
        q < stored.length ? stored[q] : null,
    ];
  }

  bool get isLoading =>
      _exam == null || _schoolClass == null || _answers == null;
  bool get isNewScan => savedStudent == null;
  Exam? get exam => _exam;
  SchoolClass? get schoolClass => _schoolClass;
  List<int?> get answers => _answers ?? const [];
  Set<int> get needsCheck => _needsCheck;

  int? get studentNumber => _student;

  /// Null when the number is unreadable or not on the class list.
  Student? get student => switch (_student) {
    final number? => _schoolClass?.studentByNumber(number),
    null => null,
  };

  /// A paper can be saved once it has a number, even one not on the class
  /// list (the View warns about that case).
  bool get canSave => _student != null;

  /// Numbers that already have a saved paper (for the student picker).
  Set<int> get checkedNumbers => _saved?.keys.toSet() ?? const {};

  /// The earlier score that saving would overwrite, if any.
  int? get replacedScore {
    final exam = _exam;
    final number = _student;
    if (exam == null || number == null || number == savedStudent) return null;
    final earlier = _saved?[number];
    return earlier == null ? null : scoreAnswers(exam, earlier.answers);
  }

  int get score => switch (_exam) {
    final exam? => scoreAnswers(exam, answers),
    null => 0,
  };
  int get total => switch (_exam) {
    final exam? => gradableQuestions(exam),
    null => 0,
  };
  int get percent => total == 0 ? 0 : (score * 100 / total).round();

  void chooseStudent(int number) {
    _student = number;
    notifyListeners();
  }

  void setAnswer(int question, int? choice) {
    _answers = [...answers]..[question] = choice;
    _needsCheck = {..._needsCheck}..remove(question);
    notifyListeners();
  }

  Future<bool> save() async {
    final number = _student;
    if (number == null) return false;
    return runCommand(
      () => _results.saveResult(
        ExamResult(
          examId: examId,
          studentNumber: number,
          answers: answers,
          scannedAt: DateTime.now(),
        ),
        replacing: savedStudent,
      ),
    );
  }

  Future<bool> delete() async {
    final number = savedStudent;
    if (number == null) return false;
    return runCommand(() => _results.deleteResult(examId, number));
  }
}
