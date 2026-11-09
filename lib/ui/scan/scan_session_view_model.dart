import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/data/repositories/result_repository.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/omr/omr_reading.dart';
import 'package:egrado/services/photo_service.dart';
import 'package:egrado/services/sheet_reader.dart';
import 'package:egrado/ui/core/view_model.dart';

/// Where the session is between papers.
sealed class ScanStep {
  const ScanStep();
}

final class ScanWaiting extends ScanStep {
  const ScanWaiting();
}

final class ScanReading extends ScanStep {
  const ScanReading();
}

final class ScanFailed extends ScanStep {
  const ScanFailed(this.message);

  final String message;
}

/// Checks a stack of papers one after another:
/// photo → read → (View shows review) → saved → next photo.
class ScanSessionViewModel extends ViewModel {
  ScanSessionViewModel({
    required this.examId,
    required ExamRepository exams,
    required ClassRepository classes,
    required ResultRepository results,
    required this._photos,
    required this._reader,
  }) {
    listen(exams.watchExam(examId), (exam) {
      final isFirst = _exam == null && exam != null;
      _exam = exam;
      if (isFirst) {
        listen(classes.watchClass(exam.classId), (c) {
          _classSize = c?.students.length ?? 0;
          notifyListeners();
        });
      }
      notifyListeners();
    });
    listen(results.watchResults(examId), (list) {
      _checkedCount = list.length;
      notifyListeners();
    });
  }

  final String examId;
  final PhotoService _photos;
  final SheetReader _reader;

  Exam? _exam;
  int _classSize = 0;
  int _checkedCount = 0;
  ScanStep _step = const ScanWaiting();
  PhotoSource? _source;
  bool _isBusy = false;
  int _savedThisSession = 0;

  Exam? get exam => _exam;
  int get classSize => _classSize;
  int get checkedCount => _checkedCount;
  ScanStep get step => _step;
  bool get isBusy => _isBusy;
  int get savedThisSession => _savedThisSession;

  /// The camera/gallery choice is remembered for the whole session.
  PhotoSource? get source => _source;

  /// Takes a photo and reads it. Returns the reading for the View to show
  /// for review, or null if cancelled, busy or unreadable (see [step]).
  Future<OmrReading?> captureAndRead(PhotoSource source) async {
    final exam = _exam;
    if (_isBusy || exam == null) return null;
    _source = source;
    _setBusy(true);
    try {
      final photo = await _photos.take(source);
      if (photo == null) {
        _step = const ScanWaiting();
        return null;
      }
      _step = const ScanReading();
      notifyListeners();
      final scan = await _reader.read(photo, exam);
      switch (scan) {
        case SheetScanFailure(:final problem):
          _step = ScanFailed(problem.title);
          return null;
        case SheetScanSuccess(:final reading):
          _step = const ScanWaiting();
          return reading;
      }
    } on PhotoUnavailableException catch (e) {
      _step = ScanFailed(
        e.permissionDenied
            ? 'eGrado needs permission to use the camera. '
                  'Please allow it in your phone Settings.'
            : 'The camera could not be opened. Please try again.',
      );
      return null;
    } finally {
      // Covers an unexpected reader crash: never leave the spinner up.
      if (_step is ScanReading) {
        _step = const ScanFailed('The photo could not be read.');
      }
      _setBusy(false);
    }
  }

  void recordSaved() {
    _savedThisSession++;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }
}
