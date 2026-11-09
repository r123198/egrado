import 'package:egrado/app_providers.dart';
import 'package:egrado/data/auth/auth_repository.dart';
import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/omr/omr_reading.dart';
import 'package:egrado/services/name_list_reader.dart';
import 'package:egrado/services/photo_service.dart';
import 'package:egrado/services/sheet_reader.dart';
import 'package:egrado/ui/shell/shell_view_model.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';

import 'fake_auth.dart';
import 'fakes.dart';
import 'fixtures.dart';

/// Pumps [page] with the real theme and real Drift repositories on an
/// in-memory database (seeded by [seed]); device features are faked.
Future<AppDatabase> pumpPage(
  WidgetTester tester,
  Widget page, {
  Future<void> Function(AppDatabase db)? seed,
  Size size = const Size(400, 860),
  double textScale = 1,
  PhotoService? photos,
  SheetReader? reader,
  NameListReader? nameReader,
  AuthRepository? auth,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = memoryDatabase();
  if (seed != null) await tester.runAsync(() => seed(db));
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(
          value: auth ?? FakeAuthRepository(signedIn: teacher),
        ),
        ChangeNotifierProvider(create: (_) => ShellViewModel()),
        ...appProviders(
          database: db,
          photos: photos ?? FakePhotoService(),
          reader:
              reader ??
              FakeSheetReader(
                const SheetScanFailure(ScanProblem.cornersNotFound),
              ),
          nameReader: nameReader ?? FakeNameListReader(),
          printer: FakePrintService(),
          exporter: FakeExportService(),
        ),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

/// [testWidgets] for screens backed by Drift: unmounts the app at the end
/// so Drift's stream-cleanup timers and the database close can finish
/// inside the test's fake clock.
@isTest
void testAppWidgets(String description, WidgetTesterCallback body) {
  testWidgets(description, (tester) async {
    await body(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
