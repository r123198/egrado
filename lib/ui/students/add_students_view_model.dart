import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/services/name_list_reader.dart';
import 'package:egrado/services/photo_service.dart';
import 'package:egrado/ui/core/view_model.dart';

/// What happened when the teacher tried to read names from a photo.
sealed class NamePhotoOutcome {
  const NamePhotoOutcome();
}

final class NamesFound extends NamePhotoOutcome {
  const NamesFound(this.count);

  final int count;
}

final class NoNamesFound extends NamePhotoOutcome {
  const NoNamesFound();
}

final class NamePhotoCancelled extends NamePhotoOutcome {
  const NamePhotoCancelled();
}

final class NamePhotoFailed extends NamePhotoOutcome {
  const NamePhotoFailed(this.message);

  final String message;
}

/// Adding many students at once: typed, pasted, or read from a photo of
/// the class list.
class AddStudentsViewModel extends ViewModel {
  AddStudentsViewModel(
    this.classId,
    this._classes, {
    required this._photos,
    required this._nameReader,
  }) {
    listen(_classes.watchClass(classId), (c) {
      _schoolClass = c;
      notifyListeners();
    });
  }

  final String classId;
  final ClassRepository _classes;
  final PhotoService _photos;
  final NameListReader _nameReader;

  SchoolClass? _schoolClass;
  String _text = '';
  List<String> _names = const [];
  bool _isReadingPhoto = false;

  /// The names box, one name per line. The View mirrors this.
  String get text => _text;

  /// True while a photo is being read; the screen shows a spinner.
  bool get isReadingPhoto => _isReadingPhoto;

  /// One name per line; blank lines and extra spaces are ignored.
  void updateNames(String text) {
    _text = text;
    _names = text
        .split('\n')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    notifyListeners();
  }

  /// Reads names from a photo and adds them below any already typed, so
  /// the teacher can check and fix them before saving.
  Future<NamePhotoOutcome> readNamesFromPhoto(PhotoSource source) async {
    if (_isReadingPhoto) return const NamePhotoCancelled();
    try {
      final photo = await _photos.take(source);
      if (photo == null) return const NamePhotoCancelled();
      _isReadingPhoto = true;
      notifyListeners();
      final found = await _nameReader.readNames(photo);
      if (found.isEmpty) return const NoNamesFound();
      final typed = _text.trimRight();
      updateNames([if (typed.isNotEmpty) typed, ...found].join('\n'));
      return NamesFound(found.length);
    } on PhotoUnavailableException catch (e) {
      return NamePhotoFailed(
        e.permissionDenied
            ? 'eGrado needs permission to use the camera and photos. '
                  'Please allow it in your phone Settings.'
            : 'The camera could not be opened. Please try again.',
      );
    } on NameReadException {
      return const NamePhotoFailed(
        'The names could not be read on this phone. '
        'Please type them instead.',
      );
    } finally {
      if (_isReadingPhoto) {
        _isReadingPhoto = false;
        notifyListeners();
      }
    }
  }

  /// The students that will be added, with their numbers.
  List<Student> get preview =>
      _schoolClass?.numberNewStudents(_names) ?? const [];

  /// Names left out because the class has run out of numbers.
  int get droppedCount => _names.length - preview.length;

  Future<bool> save() {
    final added = preview;
    return runCommand(() => _classes.addStudents(classId, added));
  }
}
