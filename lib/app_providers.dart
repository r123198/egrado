import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/data/repositories/class_record_repository.dart';
import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/data/repositories/result_repository.dart';
import 'package:egrado/services/class_record_engine.dart';
import 'package:egrado/services/class_record_file_service.dart';
import 'package:egrado/services/name_list_reader.dart';
import 'package:egrado/services/photo_service.dart';
import 'package:egrado/services/results_export_service.dart';
import 'package:egrado/services/sheet_print_service.dart';
import 'package:egrado/services/sheet_reader.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Composition root: every repository and service the ViewModels use.
/// Tests pass their own [database] and fakes for device features.
List<SingleChildWidget> appProviders({
  required AppDatabase database,
  PhotoService? photos,
  SheetReader? reader,
  NameListReader? nameReader,
  SheetPrintService? printer,
  ResultsExportService? exporter,
  ClassRecordFileService? recordFiles,
  ClassRecordEngine? recordEngine,
}) => [
  Provider<AppDatabase>(
    create: (_) => database,
    dispose: (_, db) => db.close(),
  ),
  Provider<ClassRepository>(
    create: (c) => DriftClassRepository(c.read<AppDatabase>()),
  ),
  Provider<ExamRepository>(
    create: (c) => DriftExamRepository(c.read<AppDatabase>()),
  ),
  Provider<ResultRepository>(
    create: (c) => DriftResultRepository(c.read<AppDatabase>()),
  ),
  Provider<ClassRecordRepository>(
    create: (c) => DriftClassRecordRepository(c.read<AppDatabase>()),
  ),
  Provider<PhotoService>(create: (_) => photos ?? ImagePickerPhotoService()),
  Provider<SheetReader>(create: (_) => reader ?? const BackgroundSheetReader()),
  Provider<NameListReader>(
    create: (_) => nameReader ?? const OnDeviceNameListReader(),
  ),
  Provider<SheetPrintService>(
    create: (_) => printer ?? const PdfSheetPrintService(),
  ),
  Provider<ResultsExportService>(
    create: (_) => exporter ?? const CsvShareExportService(),
  ),
  Provider<ClassRecordFileService>(
    create: (_) => recordFiles ?? const DeviceClassRecordFileService(),
  ),
  Provider<ClassRecordEngine>(
    create: (_) => recordEngine ?? const IsolateClassRecordEngine(),
  ),
];

/// Wraps [child] with [appProviders].
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.database, required this.child});

  final AppDatabase database;
  final Widget child;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: appProviders(database: database),
    child: child,
  );
}
