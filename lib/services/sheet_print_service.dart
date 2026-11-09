import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/sheet/answer_sheet_pdf.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Printing is not available on this device.
class PrintUnavailableException implements Exception {
  const PrintUnavailableException();
}

abstract interface class SheetPrintService {
  /// Opens the system print dialog (which can also save a PDF).
  /// [named] prints one sheet per student with name and number filled in;
  /// otherwise blank sheets. Throws [PrintUnavailableException].
  Future<void> printSheets(
    Exam exam,
    SchoolClass schoolClass, {
    required bool named,
  });
}

class PdfSheetPrintService implements SheetPrintService {
  const PdfSheetPrintService();

  /// Blank sheets printed when the class list is still empty.
  static const int _defaultBlankSheets = 40;

  @override
  Future<void> printSheets(
    Exam exam,
    SchoolClass schoolClass, {
    required bool named,
  }) async {
    final sheets = named
        ? schoolClass.students
        : List<Student?>.filled(
            schoolClass.students.isEmpty
                ? _defaultBlankSheets
                : schoolClass.students.length,
            null,
          );
    try {
      final regular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/AtkinsonHyperlegible-Regular.ttf'),
      );
      final bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/AtkinsonHyperlegible-Bold.ttf'),
      );
      await Printing.layoutPdf(
        name: '${exam.title} – answer sheets',
        onLayout: (_) => buildAnswerSheetPdf(
          exam: exam,
          className: schoolClass.name,
          students: sheets,
          regular: regular,
          bold: bold,
        ),
      );
    } on PlatformException {
      throw const PrintUnavailableException();
    }
  }
}
