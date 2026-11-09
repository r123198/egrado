import 'package:egrado/ui/root/root_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/fake_auth.dart';

/// Runs the real app on a device with the teacher's real SQLite file
/// (sign-in is faked so the test doesn't need a Firebase account): sets up
/// a class, closes the app, opens it again, and checks nothing was lost.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final className = 'Persist ${DateTime.now().millisecondsSinceEpoch}';

  Future<void> openApp(WidgetTester tester) async {
    await tester.pumpWidget(
      EgradoApp(
        auth: FakeAuthRepository(signedIn: teacher),
        onboarding: FakeOnboardingRepository(complete: true),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets('class and students survive closing the app', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Classes'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add a class'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), className);
    await tester.tap(find.text('Add class'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Students'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add students'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Santos, María\nReyes, Ana');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add 2 students'));
    await tester.pumpAndSettle();
    expect(find.text('Reyes, Ana'), findsOneWidget);

    await closeApp(tester);
    await openApp(tester);

    await tester.tap(find.text('Classes'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(className), 300);
    await tester.tap(find.text(className));
    await tester.pumpAndSettle();
    expect(find.text('2 in this class'), findsOneWidget);

    // Clean up so repeated runs don't pile up classes.
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete class'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete class'));
    await tester.pumpAndSettle();
    expect(find.text(className), findsNothing);
  });
}
