import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/omr/omr_reading.dart';
import 'package:egrado/services/photo_service.dart';
import 'package:egrado/services/sheet_reader.dart';
import 'package:egrado/ui/core/view_model.dart';

/// What happened when the teacher scanned a filled-in key.
sealed class KeyScanOutcome {
  const KeyScanOutcome();
}

final class KeyScanRead extends KeyScanOutcome {
  const KeyScanRead({required this.unreadable});

  /// Questions that need the teacher to set them by hand.
  final int unreadable;
}

final class KeyScanFailed extends KeyScanOutcome {
  const KeyScanFailed(this.message);

  final String message;
}

/// The teacher backed out of the camera.
final class KeyScanCancelled extends KeyScanOutcome {
  const KeyScanCancelled();
}

class AnswerKeyViewModel extends ViewModel {
  AnswerKeyViewModel({
    required this.examId,
    required this._exams,
    required this._reader,
    required this._photos,
  }) {
    listen(_exams.watchExam(examId), (exam) {
      _exam = exam;
      // Start editing from the saved key, once.
      _draft ??= exam == null ? null : [...exam.answerKey];
      notifyListeners();
    });
  }

  final String examId;
  final ExamRepository _exams;
  final SheetReader _reader;
  final PhotoService _photos;

  Exam? _exam;
  List<int?>? _draft;
  Set<int> _needsCheck = const {};
  bool _isReading = false;

  bool get isLoading => _draft == null;
  Exam? get exam => _exam;
  List<int?> get draft => _draft ?? const [];
  bool get isReading => _isReading;
  bool needsCheck(int question) => _needsCheck.contains(question);
  int get setCount => draft.where((c) => c != null).length;

  bool get isDirty {
    final saved = _exam?.answerKey ?? const [];
    final key = draft;
    for (var i = 0; i < key.length; i++) {
      if (i >= saved.length || key[i] != saved[i]) return true;
    }
    return false;
  }

  void setAnswer(int question, int? choice) {
    final draft = _draft;
    if (draft == null) return;
    _draft = [...draft]..[question] = choice;
    _needsCheck = {..._needsCheck}..remove(question);
    notifyListeners();
  }

  /// Fills the key from a photo of a sheet shaded with the right answers.
  Future<KeyScanOutcome> scanKey(PhotoSource source) async {
    final exam = _exam;
    if (exam == null || _isReading) return const KeyScanCancelled();
    final SheetScan scan;
    try {
      final photo = await _photos.take(source);
      if (photo == null) return const KeyScanCancelled();
      _isReading = true;
      notifyListeners();
      scan = await _reader.read(photo, exam);
    } on PhotoUnavailableException {
      return const KeyScanFailed(
        'The camera could not be opened. Please check eGrado is allowed '
        'to use it in your phone Settings.',
      );
    } finally {
      _isReading = false;
      notifyListeners();
    }
    switch (scan) {
      case SheetScanFailure(:final problem):
        return KeyScanFailed('${problem.title} ${problem.advice}');
      case SheetScanSuccess(:final reading):
        final answers = reading.answers;
        _draft = [
          for (final a in answers)
            a.status == MarkStatus.clear ? a.choice : null,
        ];
        _needsCheck = {
          for (var q = 0; q < answers.length; q++)
            if (answers[q].status != MarkStatus.clear) q,
        };
        notifyListeners();
        return KeyScanRead(unreadable: _needsCheck.length);
    }
  }

  Future<bool> save() async {
    final exam = _exam;
    if (exam == null) return false;
    return runCommand(() => _exams.updateExam(exam.copyWith(answerKey: draft)));
  }
}
