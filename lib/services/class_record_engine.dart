import 'dart:isolate';
import 'dart:typed_data';

import 'package:egrado/class_record/class_record_fill.dart';
import 'package:egrado/class_record/class_record_layout.dart';
import 'package:egrado/class_record/xlsx_workbook.dart';
import 'package:meta/meta.dart';

/// Why a chosen file can't be used.
enum RecordProblem {
  /// Not an .xlsx workbook (or damaged).
  notAWorkbook,

  /// A workbook, but no sheet with a "HIGHEST POSSIBLE SCORE" row.
  notAClassRecord,

  /// A class record whose learner list is still empty.
  noLearners,
}

class RecordProblemException implements Exception {
  const RecordProblemException(this.problem);

  final RecordProblem problem;
}

/// What the teacher's class record contains, for the review screen.
@immutable
class RecordSummary {
  RecordSummary({
    required List<String> learnerNames,
    required List<String> periodSheets,
  }) : learnerNames = List.unmodifiable(learnerNames),
       periodSheets = List.unmodifiable(periodSheets);

  final List<String> learnerNames;

  /// e.g. ["TERM 1", "TERM 2", "TERM 3"].
  final List<String> periodSheets;
}

@immutable
class FilledRecord {
  const FilledRecord(this.bytes, this.report);

  final Uint8List bytes;
  final FillReport report;
}

/// Reads and fills class records off the UI thread.
abstract interface class ClassRecordEngine {
  /// Throws [RecordProblemException].
  Future<RecordSummary> inspect(Uint8List bytes);

  /// Throws [RecordProblemException].
  Future<FilledRecord> fill(
    Uint8List bytes, {
    required List<RecordActivity> activities,
    required Map<int, String> recordNames,
    required Map<String, ColumnPlacement> previous,
  });
}

class IsolateClassRecordEngine implements ClassRecordEngine {
  const IsolateClassRecordEngine();

  @override
  Future<RecordSummary> inspect(Uint8List bytes) =>
      Isolate.run(() => inspectRecord(bytes));

  @override
  Future<FilledRecord> fill(
    Uint8List bytes, {
    required List<RecordActivity> activities,
    required Map<int, String> recordNames,
    required Map<String, ColumnPlacement> previous,
  }) => Isolate.run(
    () => fillRecord(
      bytes,
      activities: activities,
      recordNames: recordNames,
      previous: previous,
    ),
  );
}

(XlsxWorkbook, ClassRecordLayout) _open(Uint8List bytes) {
  try {
    final workbook = XlsxWorkbook.decode(bytes);
    return (workbook, ClassRecordLayout.detect(workbook));
  } on WorkbookFormatException {
    throw const RecordProblemException(RecordProblem.notAWorkbook);
  } on NotAClassRecordException {
    throw const RecordProblemException(RecordProblem.notAClassRecord);
  }
}

/// Synchronous version of [ClassRecordEngine.inspect].
RecordSummary inspectRecord(Uint8List bytes) {
  final (_, layout) = _open(bytes);
  final names = layout.learnerNames;
  if (names.isEmpty) {
    throw const RecordProblemException(RecordProblem.noLearners);
  }
  return RecordSummary(
    learnerNames: names,
    periodSheets: [for (final p in layout.periods) p.sheetName],
  );
}

/// Synchronous version of [ClassRecordEngine.fill].
FilledRecord fillRecord(
  Uint8List bytes, {
  required List<RecordActivity> activities,
  required Map<int, String> recordNames,
  required Map<String, ColumnPlacement> previous,
}) {
  final (workbook, layout) = _open(bytes);
  final report = fillClassRecord(
    workbook: workbook,
    layout: layout,
    activities: activities,
    recordNames: recordNames,
    previous: previous,
  );
  return FilledRecord(workbook.encode(), report);
}
