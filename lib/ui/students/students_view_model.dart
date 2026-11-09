import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/ui/core/view_model.dart';

class StudentsViewModel extends ViewModel {
  StudentsViewModel(this.classId, this._classes) {
    listen(_classes.watchClass(classId), (c) {
      _schoolClass = c;
      _isLoaded = true;
      notifyListeners();
    });
  }

  final String classId;
  final ClassRepository _classes;

  SchoolClass? _schoolClass;
  bool _isLoaded = false;

  bool get isLoading => !_isLoaded;
  SchoolClass? get schoolClass => _schoolClass;
  List<Student> get students => _schoolClass?.students ?? const [];
  bool get isFull => _schoolClass?.nextFreeNumber == null;

  Future<bool> rename(int number, String name) =>
      runCommand(() => _classes.renameStudent(classId, number, name.trim()));

  Future<bool> remove(int number) =>
      runCommand(() => _classes.removeStudent(classId, number));
}
