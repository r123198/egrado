import 'dart:typed_data';
import 'dart:ui';

import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/exam_result.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/omr/omr_reading.dart';
import 'package:egrado/services/name_list_reader.dart';
import 'package:egrado/services/photo_service.dart';
import 'package:egrado/services/results_export_service.dart';
import 'package:egrado/services/sheet_print_service.dart';
import 'package:egrado/services/sheet_reader.dart';

class FakePhotoService implements PhotoService {
  Uint8List? nextPhoto = Uint8List.fromList([1, 2, 3]);
  PhotoUnavailableException? error;
  int calls = 0;

  @override
  Future<Uint8List?> take(PhotoSource source) async {
    calls++;
    final e = error;
    if (e != null) throw e;
    return nextPhoto;
  }
}

class FakeNameListReader implements NameListReader {
  List<String> names = const ['Abad, Ben', 'Cruz, Leo'];
  NameReadException? error;

  @override
  Future<List<String>> readNames(Uint8List photo) async {
    final e = error;
    if (e != null) throw e;
    return names;
  }
}

class FakeSheetReader implements SheetReader {
  FakeSheetReader(this.result);

  SheetScan result;

  @override
  Future<SheetScan> read(Uint8List photo, Exam exam) async => result;
}

class FakePrintService implements SheetPrintService {
  bool? lastNamed;
  bool unavailable = false;

  @override
  Future<void> printSheets(
    Exam exam,
    SchoolClass schoolClass, {
    required bool named,
  }) async {
    if (unavailable) throw const PrintUnavailableException();
    lastNamed = named;
  }
}

class FakeExportService implements ResultsExportService {
  List<ExamResult>? exported;

  @override
  Future<void> export({
    required SchoolClass schoolClass,
    required Exam exam,
    required List<ExamResult> results,
    Rect? origin,
  }) async => exported = results;
}

OmrReading reading({
  required List<MarkReading> digits,
  required List<MarkReading> answers,
}) => OmrReading(studentDigits: digits, answers: answers);
