import 'package:egrado/domain/app_user.dart';

/// A sign-in problem, already phrased for the teacher.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}

abstract interface class AuthRepository {
  /// The signed-in teacher, or null; emits on every sign-in and sign-out.
  Stream<AppUser?> watchUser();

  AppUser? get currentUser;

  /// Returns null if the teacher closed the Google window.
  /// Throws [AuthFailure].
  Future<AppUser?> signInWithGoogle();

  /// Throws [AuthFailure].
  Future<AppUser> signInWithEmail(String email, String password);

  /// Throws [AuthFailure].
  Future<AppUser> createAccount({
    required String name,
    required String email,
    required String password,
  });

  /// Throws [AuthFailure].
  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
