import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/domain/overviews.dart';
import 'package:egrado/ui/core/view_model.dart';

class HomeViewModel extends ViewModel {
  HomeViewModel(this._classes) {
    listen(_classes.watchOverviews(), (list) {
      _overviews = list;
      notifyListeners();
    });
  }

  final ClassRepository _classes;

  List<ClassOverview>? _overviews;

  bool get isLoading => _overviews == null;
  List<ClassOverview> get classes => _overviews ?? const [];

  /// Returns the new class's id, or null if it could not be saved.
  Future<String?> addClass(String name) async {
    String? id;
    final ok = await runCommand(
      () async => id = await _classes.createClass(name.trim()),
    );
    return ok ? id : null;
  }
}
