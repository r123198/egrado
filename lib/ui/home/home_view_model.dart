import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/workspace_repository.dart';
import 'package:egrado/domain/overviews.dart';
import 'package:egrado/domain/teaching_level.dart';
import 'package:egrado/grading/scheme_presets.dart';
import 'package:egrado/ui/core/view_model.dart';

class HomeViewModel extends ViewModel {
  HomeViewModel(this._classes, this._workspace) {
    listen(_classes.watchOverviews(), (list) {
      _overviews = list;
      notifyListeners();
    });
    listen(_workspace.watchLevel(), (level) {
      _level = level;
      _isLevelLoaded = true;
      notifyListeners();
    });
  }

  final ClassRepository _classes;
  final WorkspaceRepository _workspace;

  List<ClassOverview>? _overviews;
  TeachingLevel? _level;
  bool _isLevelLoaded = false;

  bool get isLoading => _overviews == null || !_isLevelLoaded;
  List<ClassOverview> get classes => _overviews ?? const [];

  /// True before the very first class: the teacher hasn't said whether
  /// they teach under DepEd or in college. Asked once, never again.
  bool get needsLevel => _level == null && classes.isEmpty;

  /// What new classes are set up for. A teacher who had classes before
  /// the question existed was on DepEd, the only kind there was.
  TeachingLevel get level => _level ?? TeachingLevel.depEd;

  /// Adds a class set up for [chosenLevel] (the answer just given, which
  /// is then remembered) or the workspace's level. Returns the new
  /// class's id, or null if it could not be saved.
  Future<String?> addClass(String name, {TeachingLevel? chosenLevel}) async {
    String? id;
    final ok = await runCommand(() async {
      if (chosenLevel != null) await _workspace.setLevel(chosenLevel);
      id = await _classes.createClass(
        name.trim(),
        customScheme: (chosenLevel ?? level) == TeachingLevel.college
            ? collegeScheme
            : null,
      );
    });
    return ok ? id : null;
  }
}
