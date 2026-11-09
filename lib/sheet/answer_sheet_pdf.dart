import 'dart:typed_data';

import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/omr/sheet_layout.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const _ink = PdfColor.fromInt(0xFF111111);
const _guide = PdfColor.fromInt(0xFF555555);

/// Builds printable answer sheets for [exam].
///
/// Each entry of [students] becomes one page. A [Student] gets a page with
/// their name printed and their number already shaded, so they can't bubble
/// the wrong number; a `null` entry gives a blank sheet.
Future<Uint8List> buildAnswerSheetPdf({
  required Exam exam,
  required String className,
  required List<Student?> students,
  required pw.Font regular,
  required pw.Font bold,
}) {
  final doc = pw.Document(
    title: '${exam.title} – answer sheets',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  for (final student in students) {
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => _SheetPage(exam, className, student).build(),
      ),
    );
  }
  return doc.save();
}

double _pt(double mm) => mm * PdfPageFormat.mm;

class _SheetPage {
  const _SheetPage(this.exam, this.className, this.student);

  final Exam exam;
  final String className;
  final Student? student;

  pw.Widget build() {
    return pw.Stack(
      children: [
        pw.CustomPaint(
          size: PdfPoint(
            _pt(SheetLayout.pageWidth),
            _pt(SheetLayout.pageHeight),
          ),
          painter: _paintShapes,
        ),
        ..._header(),
        ..._studentNumberLabels(),
        ..._questionLabels(),
      ],
    );
  }

  pw.Widget _text(
    double xMm,
    double yMm,
    String text, {
    double size = 10,
    bool bold = false,
    PdfColor color = _ink,
  }) {
    return pw.Positioned(
      left: _pt(xMm),
      top: _pt(yMm),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: size,
          color: color,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  List<pw.Widget> _header() => [
    _text(42, 11.5, exam.title, size: 16, bold: true),
    _text(42, 19, '$className  ·  ${exam.questionCount} questions'),
    _text(
      22,
      32,
      student == null ? 'Name: ' : 'Name:  ${student!.name}',
      size: 13,
      bold: student != null,
    ),
    _text(130, 32, 'Date: ', size: 13),
    _text(
      22,
      44,
      'Shade ONE circle fully with a dark pencil or pen. '
      'Erase cleanly to change an answer.',
      size: 10,
      color: _guide,
    ),
    _text(
      22,
      49,
      'Do not write near the black corner squares.',
      size: 10,
      color: _guide,
    ),
  ];

  List<pw.Widget> _studentNumberLabels() {
    final firstRowY = SheetLayout.idBubble(0, 0).y;
    return [
      _text(22, firstRowY - 13, 'STUDENT NUMBER', size: 11, bold: true),
      _text(
        22,
        firstRowY - 2,
        student == null ? 'Write it in the\nboxes, then shade.' : '',
        size: 9,
        color: _guide,
      ),
      for (var d = 0; d < 10; d++)
        _text(
          SheetLayout.idBubble(0, d).x - 1.2,
          firstRowY - 8.5,
          '$d',
          size: 10,
          bold: true,
        ),
      if (student != null)
        for (var place = 0; place < kStudentNumberDigits; place++)
          _text(
            SheetLayout.idFirstX - 13.5,
            SheetLayout.idBubble(place, 0).y - 2.6,
            '${place == 0 ? student!.number ~/ 10 : student!.number % 10}',
            size: 12,
            bold: true,
          ),
    ];
  }

  List<pw.Widget> _questionLabels() {
    final columns = (exam.questionCount / kQuestionsPerColumn).ceil();
    return [
      for (var col = 0; col < columns; col++)
        for (var c = 0; c < exam.choiceCount; c++)
          _text(
            SheetLayout.questionBubble(col * kQuestionsPerColumn, c).x - 1.3,
            SheetLayout.questionFirstY - 9,
            kChoiceLetters[c],
            size: 10,
            bold: true,
          ),
      for (var q = 0; q < exam.questionCount; q++)
        pw.Positioned(
          left: _pt(SheetLayout.questionLabel(q).x - 4),
          top: _pt(SheetLayout.questionLabel(q).y - 2.2),
          child: pw.SizedBox(
            width: _pt(10),
            child: pw.Text(
              '${q + 1}.',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
    ];
  }

  /// Shapes are drawn in PDF space, whose origin is the bottom-left corner.
  void _paintShapes(PdfGraphics canvas, PdfPoint size) {
    double y(double mm) => size.y - _pt(mm);

    canvas.setFillColor(_ink);
    void square(PagePoint c, double side) => canvas.drawRect(
      _pt(c.x - side / 2),
      y(c.y + side / 2),
      _pt(side),
      _pt(side),
    );
    for (final c in SheetLayout.markerCenters) {
      square(c, SheetLayout.markerSize);
    }
    square(SheetLayout.orientationMark, SheetLayout.orientationMarkSize);
    canvas.fillPath();

    final r = _pt(SheetLayout.bubbleRadius);
    void circle(PagePoint c) => canvas.drawEllipse(_pt(c.x), y(c.y), r, r);

    // Write-in boxes for the student number.
    canvas
      ..setStrokeColor(_guide)
      ..setLineWidth(0.6);
    for (var place = 0; place < kStudentNumberDigits; place++) {
      final c = SheetLayout.idBubble(place, 0);
      canvas.drawRect(
        _pt(SheetLayout.idFirstX - 16),
        y(c.y + 3.5),
        _pt(7),
        _pt(7),
      );
    }
    canvas.strokePath();

    canvas
      ..setStrokeColor(_ink)
      ..setLineWidth(0.8);
    for (var place = 0; place < kStudentNumberDigits; place++) {
      for (var d = 0; d < 10; d++) {
        circle(SheetLayout.idBubble(place, d));
      }
    }
    for (var q = 0; q < exam.questionCount; q++) {
      for (var c = 0; c < exam.choiceCount; c++) {
        circle(SheetLayout.questionBubble(q, c));
      }
    }
    canvas.strokePath();

    final number = student?.number;
    if (number != null) {
      canvas.setFillColor(_ink);
      circle(SheetLayout.idBubble(0, number ~/ 10));
      circle(SheetLayout.idBubble(1, number % 10));
      canvas.fillPath();
    }
  }
}
