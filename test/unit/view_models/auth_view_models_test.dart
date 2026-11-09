import 'package:egrado/domain/app_user.dart';
import 'package:egrado/ui/account/account_view_model.dart';
import 'package:egrado/ui/auth/sign_in_view_model.dart';
import 'package:egrado/ui/onboarding/onboarding_view_model.dart';
import 'package:egrado/ui/root/root_view_model.dart';
import 'package:egrado/ui/shell/shell_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('RootViewModel', () {
    test('first launch: loading, then the welcome tour', () async {
      final vm = RootViewModel(
        FakeAuthRepository(),
        FakeOnboardingRepository(),
      );
      expect(vm.state, isA<RootLoading>());
      await _settle();
      expect(vm.state, isA<RootOnboarding>());
      await vm.finishOnboarding();
      expect(vm.state, isA<RootSignedOut>());
      vm.dispose();
    });

    test('a returning signed-in teacher goes straight to the app', () async {
      final vm = RootViewModel(
        FakeAuthRepository(signedIn: teacher),
        FakeOnboardingRepository(),
      );
      await _settle();
      expect((vm.state as RootSignedIn).user.uid, teacher.uid);
      vm.dispose();
    });

    test('signing in and out moves between screens', () async {
      final auth = FakeAuthRepository();
      final vm = RootViewModel(auth, FakeOnboardingRepository(complete: true));
      await _settle();
      expect(vm.state, isA<RootSignedOut>());
      await auth.signInWithGoogle();
      await _settle();
      expect(vm.state, isA<RootSignedIn>());
      await auth.signOut();
      await _settle();
      expect(vm.state, isA<RootSignedOut>());
      vm.dispose();
    });

    test('finishing the tour is remembered', () async {
      final store = FakeOnboardingRepository();
      final vm = RootViewModel(FakeAuthRepository(), store);
      await _settle();
      await vm.finishOnboarding();
      expect(store.complete, isTrue);
      vm.dispose();
    });
  });

  group('SignInViewModel', () {
    late FakeAuthRepository auth;
    late SignInViewModel vm;

    setUp(() {
      auth = FakeAuthRepository();
      vm = SignInViewModel(auth);
    });
    tearDown(() => vm.dispose());

    test('checks the fields before trying to sign in', () async {
      await vm.submit();
      expect(vm.emailError, isNotNull);
      expect(vm.passwordError, isNotNull);
      expect(auth.currentUser, isNull);
    });

    test('signs in with a correct email and password', () async {
      vm
        ..setEmail(' ana@school.ph ')
        ..setPassword('secret1');
      await vm.submit();
      expect(vm.error, isNull);
      expect(auth.currentUser?.email, 'ana@school.ph');
    });

    test('shows the plain-language reason when sign-in fails', () async {
      vm
        ..setEmail('ana@school.ph')
        ..setPassword('wrong-pw');
      await vm.submit();
      expect(vm.error, 'The email or password is not correct.');
      expect(vm.isBusy, isFalse);
    });

    test('creating an account also needs a name', () async {
      vm
        ..toggleMode()
        ..setEmail('ana@school.ph')
        ..setPassword('secret1');
      await vm.submit();
      expect(vm.nameError, isNotNull);
      vm.setName('Ana Reyes');
      await vm.submit();
      expect(auth.currentUser?.displayName, 'Ana Reyes');
    });

    test('closing the Google window is not an error', () async {
      auth.googleCancels = true;
      await vm.signInWithGoogle();
      expect(vm.error, isNull);
      expect(auth.currentUser, isNull);
    });

    test('password reset asks for the email first', () async {
      await vm.sendPasswordReset();
      expect(vm.error, contains('email'));
      vm.setEmail('ana@school.ph');
      await vm.sendPasswordReset();
      expect(auth.lastResetEmail, 'ana@school.ph');
      expect(vm.info, contains('ana@school.ph'));
    });
  });

  test('onboarding steps forward and knows the last page', () {
    final vm = OnboardingViewModel();
    expect(vm.isLast, isFalse);
    vm.goTo(OnboardingViewModel.steps.length - 1);
    expect(vm.isLast, isTrue);
    vm
      ..goTo(99)
      ..dispose();
  });

  group('AccountViewModel', () {
    test('initials come from the name, else the email', () async {
      final vm = AccountViewModel(FakeAuthRepository(signedIn: teacher));
      await _settle();
      expect(vm.initials, 'MC');
      vm.dispose();

      final emailOnly = AccountViewModel(
        FakeAuthRepository(
          signedIn: const AppUser(uid: 'x', email: 'ben@x.ph'),
        ),
      );
      await _settle();
      expect(emailOnly.initials, 'B');
      emailOnly.dispose();
    });

    test('signs out', () async {
      final auth = FakeAuthRepository(signedIn: teacher);
      final vm = AccountViewModel(auth);
      expect(await vm.signOut(), isTrue);
      expect(auth.currentUser, isNull);
      vm.dispose();
    });
  });

  test('tapping the current tab asks to go back to its top', () {
    final vm = ShellViewModel();
    expect(vm.select(AppTab.classes), isFalse);
    expect(vm.select(AppTab.classes), isTrue);
    vm.dispose();
  });
}
