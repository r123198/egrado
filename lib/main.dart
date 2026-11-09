import 'package:egrado/data/auth/firebase_auth_repository.dart';
import 'package:egrado/data/preferences/onboarding_repository.dart';
import 'package:egrado/firebase_options.dart';
import 'package:egrado/ui/root/root_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    EgradoApp(
      auth: FirebaseAuthRepository(),
      onboarding: PrefsOnboardingRepository(),
    ),
  );
}
