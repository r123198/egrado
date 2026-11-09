import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/domain/overviews.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/ui/core/view_model.dart';

class ClassViewModel extends ViewModel {
  ClassViewModel(this.classId, this._classes, ExamRepository exams) {
    listen(_classes.watchClass(classId), (c) {
      _schoolClass = c;
      _isClassLoaded = true;
      notifyListeners();
    });
    listen(exams.watchOverviews(classId), (list) {
      _exams = list;
      notifyListeners();
    });
  }

  final String classId;
  final ClassRepository _classes;

  SchoolClass? _schoolClass;
  bool _isClassLoaded = false;
  List<ExamOverview>? _exams;

  bool get isLoading => !_isClassLoaded || _exams == null;

  /// Null after the class was deleted.
  SchoolClass? get schoolClass => _schoolClass;
  List<ExamOverview> get exams => _exams ?? const [];
  int get studentCount => _schoolClass?.students.length ?? 0;

  Future<bool> rename(String name) =>
      runCommand(() => _classes.renameClass(classId, name.trim()));

  Future<bool> delete() => runCommand(() => _classes.deleteClass(classId));
}
