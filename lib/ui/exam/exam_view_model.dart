import 'dart:ui';

import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/data/repositories/result_repository.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/exam_result.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/services/results_export_service.dart';
import 'package:egrado/services/sheet_print_service.dart';
import 'package:egrado/ui/core/view_model.dart';

/// One line in the scores list.
class ScoreLine {
  const ScoreLine({required this.number, required this.name, this.score});

  final int number;

  /// Null when the number is not on the class list.
  final String? name;

  /// Null when this student's paper hasn't been checked yet.
  final int? score;

  bool get isChecked => score != null;
}

class ScoreSummary {
  const ScoreSummary({
    required this.checked,
    required this.classSize,
    required this.total,
    this.average,
    this.highest,
  });

  final int checked;
  final int classSize;
  final int total;
  final double? average;
  final int? highest;
}

enum ActionOutcome { done, unavailable }

/// Everything about one test: scores, key status, printing and export.
class ExamViewModel extends ViewModel {
  ExamViewModel({
    required this.examId,
    required this._exams,
    required ClassRepository classes,
    required ResultRepository results,
    required this._printer,
    required this._exporter,
  }) {
    listen(_exams.watchExam(examId), (exam) {
      final classChanged = exam?.classId != _exam?.classId;
      _exam = exam;
      _isExamLoaded = true;
      if (exam != null && classChanged) {
        listen(classes.watchClass(exam.classId), (c) {
          _schoolClass = c;
          notifyListeners();
        });
      }
      notifyListeners();
    });
    listen(results.watchResults(examId), (list) {
      _results = list;
      notifyListeners();
    });
  }

  final String examId;
  final ExamRepository _exams;
  final SheetPrintService _printer;
  final ResultsExportService _exporter;

  Exam? _exam;
  bool _isExamLoaded = false;
  SchoolClass? _schoolClass;
  List<ExamResult>? _results;

  bool get isLoading =>
      !_isExamLoaded ||
      _results == null ||
      (_exam != null && _schoolClass == null);

  /// Null after the test was deleted.
  Exam? get exam => _exam;
  SchoolClass? get schoolClass => _schoolClass;
  bool get canCheckPapers => _exam?.hasCompleteKey ?? false;
  bool get hasResults => (_results ?? const []).isNotEmpty;
  bool get hasStudents => (_schoolClass?.students ?? const []).isNotEmpty;

  /// Every student on the list, plus any scanned number that isn't.
  List<ScoreLine> get scoreLines {
    final exam = _exam;
    final schoolClass = _schoolClass;
    if (exam == null || schoolClass == null) return const [];
    final byNumber = {for (final r in _results ?? const []) r.studentNumber: r};
    final numbers = {
      ...schoolClass.students.map((s) => s.number),
      ...byNumber.keys,
    }.toList()..sort();
    return [
      for (final n in numbers)
        ScoreLine(
          number: n,
          name: schoolClass.studentByNumber(n)?.name,
          score: switch (byNumber[n]) {
            final result? => scoreAnswers(exam, result.answers),
            null => null,
          },
        ),
    ];
  }

  ScoreSummary get summary {
    final exam = _exam;
    final total = exam == null ? 0 : gradableQuestions(exam);
    final scores = [
      if (exam != null)
        for (final r in _results ?? const <ExamResult>[])
          scoreAnswers(exam, r.answers),
    ];
    return ScoreSummary(
      checked: scores.length,
      classSize: _schoolClass?.students.length ?? 0,
      total: total,
      average: scores.isEmpty
          ? null
          : scores.reduce((a, b) => a + b) / scores.length,
      highest: scores.isEmpty ? null : scores.reduce((a, b) => a > b ? a : b),
    );
  }

  Future<bool> delete() => runCommand(() => _exams.deleteExam(examId));

  Future<ActionOutcome> printSheets({required bool named}) async {
    final exam = _exam;
    final schoolClass = _schoolClass;
    if (exam == null || schoolClass == null) return ActionOutcome.unavailable;
    try {
      await _printer.printSheets(exam, schoolClass, named: named);
      return ActionOutcome.done;
    } on PrintUnavailableException {
      return ActionOutcome.unavailable;
    }
  }

  Future<ActionOutcome> exportScores({Rect? origin}) async {
    final exam = _exam;
    final schoolClass = _schoolClass;
    if (exam == null || schoolClass == null) return ActionOutcome.unavailable;
    try {
      await _exporter.export(
        schoolClass: schoolClass,
        exam: exam,
        results: _results ?? const [],
        origin: origin,
      );
      return ActionOutcome.done;
    } on ExportFailedException {
      return ActionOutcome.unavailable;
    }
  }
}
