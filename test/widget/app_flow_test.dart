import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/ui/root/root_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fake_auth.dart';
import '../support/fixtures.dart';
import '../support/seed.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  required FakeAuthRepository auth,
  bool toured = true,
  Future<void> Function(AppDatabase db)? seed,
  Size size = const Size(400, 860),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final db = memoryDatabase();
  if (seed != null) await tester.runAsync(() => seed(db));
  await tester.pumpWidget(
    EgradoApp(
      auth: auth,
      onboarding: FakeOnboardingRepository(complete: toured),
      openDatabase: (_) => db,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testAppWidgets('first launch: tour, then sign in, then the Tests tab', (
    tester,
  ) async {
    await _pumpApp(tester, auth: FakeAuthRepository(), toured: false);
    expect(find.text('Check papers in seconds'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('3. Your grades, ready'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'a@b.ph');
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'secret1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('My tests'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testAppWidgets('skip goes straight to sign-in', (tester) async {
    await _pumpApp(tester, auth: FakeAuthRepository(), toured: false);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testAppWidgets('bottom tabs switch, and the tab bar stays inside a class', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      auth: FakeAuthRepository(signedIn: teacher),
      seed: seedSchool,
    );
    expect(find.text('Science Quiz'), findsOneWidget);
    expect(find.text('Grade 7 – Rizal'), findsOneWidget);

    await tester.tap(find.text('Classes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grade 7 – Rizal'));
    await tester.pumpAndSettle();
    expect(find.text('3 in this class'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Maria Clara Santos'), findsOneWidget);
  });

  testAppWidgets(
    'a test opens with its Key · Print · Scan · Export · Edit bar',
    (tester) async {
      await _pumpApp(
        tester,
        auth: FakeAuthRepository(signedIn: teacher),
        seed: (db) => seedSchool(db, key: [0, null, 2, 3, 0]),
      );
      await tester.tap(find.text('Science Quiz'));
      await tester.pumpAndSettle();

      for (final label in ['Key', 'Print', 'Scan', 'Export', 'Edit']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.byType(NavigationBar), findsNothing);

      // Scan before the key is finished leads the teacher to the key.
      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();
      expect(find.text('Save answer key'), findsOneWidget);
    },
  );

  testAppWidgets('signing out returns to the sign-in screen', (tester) async {
    await _pumpApp(tester, auth: FakeAuthRepository(signedIn: teacher));
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);
  });

  group('large text on a small phone', () {
    testAppWidgets('tour, sign-in and tabs have no overflow at 1.6×', (
      tester,
    ) async {
      const small = Size(360, 740);
      await _pumpApp(
        tester,
        auth: FakeAuthRepository(),
        toured: false,
        size: small,
        textScale: 1.6,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      for (final tab in ['Classes', 'Account', 'Tests']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tab);
      }
    });
  });
}
