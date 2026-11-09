import 'package:egrado/data/auth/auth_repository.dart';
import 'package:egrado/domain/app_user.dart';
import 'package:egrado/ui/core/view_model.dart';

class AccountViewModel extends ViewModel {
  AccountViewModel(this._auth, {Future<String> Function()? loadVersion}) {
    listen(_auth.watchUser(), (user) {
      _user = user;
      notifyListeners();
    });
    if (loadVersion != null) _loadVersion(loadVersion);
  }

  final AuthRepository _auth;

  AppUser? _user;
  String? _version;

  AppUser? get user => _user ?? _auth.currentUser;
  String? get version => _version;

  /// Initials for the profile circle.
  String get initials {
    final name = user?.displayName?.trim() ?? '';
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    if (letters.isNotEmpty) return letters;
    return (user?.email ?? '?').substring(0, 1).toUpperCase();
  }

  /// The app then returns to the sign-in screen by itself.
  Future<bool> signOut() => runCommand(_auth.signOut);

  Future<void> _loadVersion(Future<String> Function() load) async {
    try {
      _version = await load();
      notifyListeners();
    } on Exception {
      // The version line is optional.
    }
  }
}
