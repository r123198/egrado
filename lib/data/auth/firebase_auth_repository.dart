import 'package:egrado/data/auth/auth_repository.dart';
import 'package:egrado/domain/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, GoogleSignIn? google})
    : _auth = auth ?? FirebaseAuth.instance,
      _google = google ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleReady;

  @override
  Stream<AppUser?> watchUser() => _auth.authStateChanges().map(_toAppUser);

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      await (_googleReady ??= _google.initialize());
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(
          'Google sign-in is not set up yet. Please use email for now.',
        );
      }
      final result = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return _toAppUser(result.user);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      debugPrint('Google sign-in failed: ${e.code.name} ${e.description}');
      throw AuthFailure(_googleMessage(e));
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Google sign-in failed: ${e.code} ${e.message}');
      throw AuthFailure('${_message(e.code)} (${e.code})');
    }
  }

  /// A plain explanation, plus the technical reason in small print so a
  /// teacher can read it out to whoever supports them.
  static String _googleMessage(GoogleSignInException e) {
    final reason = switch (e.code) {
      GoogleSignInExceptionCode.interrupted =>
        'Google sign-in was interrupted. Please try again.',
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        'Google sign-in is not set up correctly for this copy of the app. '
            'Please use email for now.',
      GoogleSignInExceptionCode.uiUnavailable =>
        'The Google sign-in window could not open. Please try again.',
      _ =>
        'Google sign-in did not work. Make sure this phone has a Google '
            'account and internet, or use email.',
    };
    final detail = e.description?.trim();
    return [
      reason,
      'Details: ${e.code.name}'
          '${detail == null || detail.isEmpty ? '' : ' – $detail'}',
    ].join('\n');
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _requireUser(result.user);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code));
    }
  }

  @override
  Future<AppUser> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = result.user;
      await user?.updateDisplayName(name.trim());
      await user?.reload();
      return _requireUser(_auth.currentUser);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code));
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    // Also forget the Google account so the next teacher can choose theirs.
    if (_googleReady != null) {
      try {
        await _google.signOut();
      } on GoogleSignInException {
        // Already signed out of Google: nothing to do.
      }
    }
  }

  static AppUser? _toAppUser(User? user) => user == null
      ? null
      : AppUser(
          uid: user.uid,
          displayName: user.displayName,
          email: user.email,
        );

  static AppUser _requireUser(User? user) =>
      _toAppUser(user) ??
      (throw const AuthFailure('Sign-in did not finish. Please try again.'));

  /// Firebase error codes in words a teacher understands.
  static String _message(String code) => switch (code) {
    'invalid-email' => 'That email address does not look right.',
    'user-disabled' => 'This account has been turned off.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'The email or password is not correct.',
    'email-already-in-use' =>
      'There is already an account with this email. Try signing in.',
    'weak-password' => 'Please use a password with at least 6 characters.',
    'too-many-requests' =>
      'Too many tries. Please wait a few minutes and try again.',
    'network-request-failed' =>
      'No internet connection. Sign-in needs internet the first time.',
    'operation-not-allowed' =>
      'This sign-in method is not turned on yet. Please contact support.',
    'account-exists-with-different-credential' =>
      'This email already signs in another way. Try email and password.',
    _ => 'Sign-in did not work. Please try again.',
  };
}
