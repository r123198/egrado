import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/domain/overviews.dart';
import 'package:egrado/ui/core/view_model.dart';

/// The Tests tab: every test in every class, newest first.
class AllTestsViewModel extends ViewModel {
  AllTestsViewModel(ExamRepository exams, ClassRepository classes) {
    listen(exams.watchAllOverviews(), (list) {
      _tests = list;
      notifyListeners();
    });
    listen(classes.watchOverviews(), (list) {
      _classes = list;
      notifyListeners();
    });
  }

  List<ExamOverview>? _tests;
  List<ClassOverview>? _classes;

  bool get isLoading => _tests == null || _classes == null;
  List<ExamOverview> get tests => _tests ?? const [];

  /// Classes a new test can be added to.
  List<ClassOverview> get classes => _classes ?? const [];
  bool get hasClasses => classes.isNotEmpty;
}
