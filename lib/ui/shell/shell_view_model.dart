import 'package:egrado/ui/core/view_model.dart';

enum AppTab { tests, classes, account }

class ShellViewModel extends ViewModel {
  AppTab _tab = AppTab.tests;

  AppTab get tab => _tab;

  /// Returns true when the teacher tapped the tab they're already on, which
  /// takes them back to the top of that tab.
  bool select(AppTab tab) {
    if (tab == _tab) return true;
    _tab = tab;
    notifyListeners();
    return false;
  }
}
