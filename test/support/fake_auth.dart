import 'dart:async';

import 'package:egrado/data/auth/auth_repository.dart';
import 'package:egrado/data/preferences/onboarding_repository.dart';
import 'package:egrado/domain/app_user.dart';

const teacher = AppUser(
  uid: 'teacher-1',
  displayName: 'Maria Clara Santos',
  email: 'maria@school.ph',
);

/// In-memory sign-in. Any email works with password "secret1"; set
/// [nextFailure] to make the next attempt fail with that message.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? signedIn}) : _user = signedIn;

  final _changes = StreamController<AppUser?>.broadcast();
  AppUser? _user;
  String? nextFailure;
  bool googleCancels = false;
  String? lastResetEmail;

  void _set(AppUser? user) {
    _user = user;
    _changes.add(user);
  }

  void _maybeFail() {
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      throw AuthFailure(failure);
    }
  }

  @override
  Stream<AppUser?> watchUser() async* {
    yield _user;
    yield* _changes.stream;
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser?> signInWithGoogle() async {
    _maybeFail();
    if (googleCancels) return null;
    _set(teacher);
    return teacher;
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    _maybeFail();
    if (password != 'secret1') {
      throw const AuthFailure('The email or password is not correct.');
    }
    final user = AppUser(uid: 'u-$email', email: email.trim());
    _set(user);
    return user;
  }

  @override
  Future<AppUser> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    _maybeFail();
    final user = AppUser(uid: 'u-$email', displayName: name, email: email);
    _set(user);
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    _maybeFail();
    lastResetEmail = email.trim();
  }

  @override
  Future<void> signOut() async => _set(null);
}

class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({this.complete = false});

  bool complete;

  @override
  Future<bool> isComplete() async => complete;

  @override
  Future<void> markComplete() async => complete = true;
}
