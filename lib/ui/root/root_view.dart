import 'package:egrado/app_providers.dart';
import 'package:egrado/data/auth/auth_repository.dart';
import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/data/preferences/onboarding_repository.dart';
import 'package:egrado/ui/auth/sign_in_view.dart';
import 'package:egrado/ui/onboarding/onboarding_view.dart';
import 'package:egrado/ui/root/root_view_model.dart';
import 'package:egrado/ui/shell/shell_view.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The base type is already large, so system text scaling is honoured up
/// to 1.6× — enough for low vision without breaking the layouts.
const double _maxTextScale = 1.6;

/// The whole app. Each stage (tour, sign-in, signed in) gets a fresh
/// navigator; a signed-in teacher's data providers sit above it so every
/// screen can reach them.
class EgradoApp extends StatelessWidget {
  const EgradoApp({
    super.key,
    required this.auth,
    required this.onboarding,
    this.openDatabase = AppDatabase.forUser,
  });

  final AuthRepository auth;
  final OnboardingRepository onboarding;
  final AppDatabase Function(String uid) openDatabase;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: auth),
        Provider<OnboardingRepository>.value(value: onboarding),
        ChangeNotifierProvider(create: (_) => RootViewModel(auth, onboarding)),
      ],
      child: Builder(
        builder: (context) {
          final state = context.watch<RootViewModel>().state;
          final app = switch (state) {
            RootLoading() => _app(const _LaunchView(), 'loading'),
            RootOnboarding() => _app(
              OnboardingPage(
                onDone: context.read<RootViewModel>().finishOnboarding,
              ),
              'onboarding',
            ),
            RootSignedOut() => _app(const SignInPage(), 'signed-out'),
            RootSignedIn(:final user) => AppProviders(
              key: ValueKey(user.uid),
              database: openDatabase(user.uid),
              child: _app(const ShellPage(), 'signed-in-${user.uid}'),
            ),
          };
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: app,
          );
        },
      ),
    );
  }

  static Widget _app(Widget home, String stage) => MaterialApp(
    key: ValueKey(stage),
    title: 'eGrado',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    builder: (context, child) => MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxTextScale,
      child: child ?? const SizedBox.shrink(),
    ),
    home: home,
  );
}

/// Matches the native splash so the hand-over is seamless.
class _LaunchView extends StatelessWidget {
  const _LaunchView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: BrandMark(size: 96, showName: false)),
    );
  }
}
