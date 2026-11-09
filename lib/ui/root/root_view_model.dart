import 'package:egrado/data/auth/auth_repository.dart';
import 'package:egrado/data/preferences/onboarding_repository.dart';
import 'package:egrado/domain/app_user.dart';
import 'package:egrado/ui/core/view_model.dart';

sealed class RootState {
  const RootState();
}

final class RootLoading extends RootState {
  const RootLoading();
}

/// First launch on this device: show the welcome tour.
final class RootOnboarding extends RootState {
  const RootOnboarding();
}

final class RootSignedOut extends RootState {
  const RootSignedOut();
}

final class RootSignedIn extends RootState {
  const RootSignedIn(this.user);

  final AppUser user;
}

/// Decides what the app shows: tour → sign-in → the teacher's classes.
class RootViewModel extends ViewModel {
  RootViewModel(this._auth, this._onboarding) {
    _start();
  }

  final AuthRepository _auth;
  final OnboardingRepository _onboarding;

  bool? _onboardingDone;
  AppUser? _user;
  bool _authKnown = false;

  RootState get state {
    if (_onboardingDone == null || !_authKnown) return const RootLoading();
    final user = _user;
    if (user != null) return RootSignedIn(user);
    if (_onboardingDone == false) return const RootOnboarding();
    return const RootSignedOut();
  }

  Future<void> _start() async {
    listen(_auth.watchUser(), (user) {
      _user = user;
      _authKnown = true;
      notifyListeners();
    });
    try {
      _onboardingDone = await _onboarding.isComplete();
    } on Exception {
      _onboardingDone = false; // Unreadable flag: showing the tour is safe.
    }
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    _onboardingDone = true;
    notifyListeners();
    try {
      await _onboarding.markComplete();
    } on Exception {
      // Worst case the tour shows once more next launch.
    }
  }
}
