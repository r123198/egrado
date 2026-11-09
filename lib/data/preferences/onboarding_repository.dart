import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether this device has seen the welcome tour.
abstract interface class OnboardingRepository {
  Future<bool> isComplete();
  Future<void> markComplete();
}

class PrefsOnboardingRepository implements OnboardingRepository {
  PrefsOnboardingRepository([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _key = 'onboarding_complete_v1';

  final SharedPreferencesAsync _prefs;

  @override
  Future<bool> isComplete() async => await _prefs.getBool(_key) ?? false;

  @override
  Future<void> markComplete() => _prefs.setBool(_key, true);
}
