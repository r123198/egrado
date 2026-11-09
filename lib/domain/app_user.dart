import 'package:meta/meta.dart';

/// The signed-in teacher.
@immutable
class AppUser {
  const AppUser({required this.uid, this.displayName, this.email});

  final String uid;
  final String? displayName;
  final String? email;

  /// What to call the teacher on screen.
  String get greetingName {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name.split(' ').first;
    return email?.split('@').first ?? 'Teacher';
  }
}
