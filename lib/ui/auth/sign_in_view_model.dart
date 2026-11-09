import 'package:egrado/data/auth/auth_repository.dart';
import 'package:egrado/ui/core/view_model.dart';

enum SignInMode { signIn, createAccount }

/// Sign in with Google, or with email and password. On success the app
/// switches to the teacher's classes on its own (via the auth stream).
class SignInViewModel extends ViewModel {
  SignInViewModel(this._auth);

  static const minPasswordLength = 6;

  final AuthRepository _auth;

  SignInMode _mode = SignInMode.signIn;
  String _name = '';
  String _email = '';
  String _password = '';
  bool _isBusy = false;
  bool _showErrors = false;
  String? _error;
  String? _info;

  SignInMode get mode => _mode;
  bool get isCreating => _mode == SignInMode.createAccount;
  bool get isBusy => _isBusy;

  /// A problem from the last attempt, phrased for the teacher.
  String? get error => _error;

  /// A confirmation, e.g. "reset email sent".
  String? get info => _info;

  String? get nameError => _showErrors && isCreating && _name.trim().isEmpty
      ? 'Please type your name'
      : null;

  String? get emailError => _showErrors && !_looksLikeEmail(_email)
      ? 'Please type your email address'
      : null;

  String? get passwordError =>
      _showErrors && _password.length < minPasswordLength
      ? 'At least $minPasswordLength characters'
      : null;

  void setName(String value) => _name = value;
  void setEmail(String value) => _email = value;
  void setPassword(String value) => _password = value;

  void toggleMode() {
    _mode = isCreating ? SignInMode.signIn : SignInMode.createAccount;
    _showErrors = false;
    _error = null;
    _info = null;
    notifyListeners();
  }

  Future<void> signInWithGoogle() => _attempt(() => _auth.signInWithGoogle());

  Future<void> submit() async {
    _showErrors = true;
    if (nameError != null || emailError != null || passwordError != null) {
      _error = null;
      notifyListeners();
      return;
    }
    await _attempt(
      () => isCreating
          ? _auth.createAccount(name: _name, email: _email, password: _password)
          : _auth.signInWithEmail(_email, _password),
    );
  }

  Future<void> sendPasswordReset() async {
    if (!_looksLikeEmail(_email)) {
      _info = null;
      _error =
          'Type your email address above first, then tap '
          '"Forgot password?" again.';
      notifyListeners();
      return;
    }
    await _attempt(() => _auth.sendPasswordReset(_email));
    if (_error == null) {
      _info =
          'We sent a link to ${_email.trim()}. '
          'Open it to choose a new password.';
      notifyListeners();
    }
  }

  Future<void> _attempt(Future<Object?> Function() action) async {
    if (_isBusy) return;
    _isBusy = true;
    _error = null;
    _info = null;
    notifyListeners();
    try {
      await action();
    } on AuthFailure catch (e) {
      _error = e.message;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  static bool _looksLikeEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
}
