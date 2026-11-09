/// Geometry of the printable eGrado answer sheet, in millimetres on an A4
/// page (origin top-left).
///
/// The PDF generator and the photo reader both use this file, so a printed
/// sheet and the reader always agree on where every bubble is.
library;

/// A point on the page in millimetres.
class PagePoint {
  const PagePoint(this.x, this.y);

  final double x;
  final double y;
}

/// Hard limits of the sheet design.
const int kMaxQuestions = 60;
const int kMinChoices = 2;
const int kMaxChoices = 5;
const int kQuestionsPerColumn = 20;

/// Student numbers are two bubbled digits, so 1–99.
const int kMaxStudentNumber = 99;
const int kStudentNumberDigits = 2;

const List<String> kChoiceLetters = ['A', 'B', 'C', 'D', 'E'];

class SheetLayout {
  const SheetLayout._();

  static const double pageWidth = 210;
  static const double pageHeight = 297;

  /// Corner registration squares.
  static const double markerSize = 10;
  static const List<PagePoint> markerCenters = [
    PagePoint(15, 15), // top-left
    PagePoint(195, 15), // top-right
    PagePoint(195, 282), // bottom-right
    PagePoint(15, 282), // bottom-left
  ];

  /// Small square printed only beside the top-left marker, so the reader
  /// can tell which way up the sheet was photographed.
  static const PagePoint orientationMark = PagePoint(30, 15);
  static const double orientationMarkSize = 6;

  static const double bubbleRadius = 2.6;

  // Student number block: one row per digit place, columns are digits 0–9.
  static const double idFirstX = 74;
  static const double idPitchX = 9;
  static const double idFirstY = 74;
  static const double idPitchY = 9;

  // Question grid: 3 columns × 20 rows.
  static const double questionFirstY = 112;
  static const double questionPitchY = 8;
  static const double questionColumnX = 24;
  static const double questionColumnPitch = 60;
  static const double choiceOffsetX = 12;
  static const double choicePitchX = 8;

  /// Centre of the bubble for [digit] (0–9) in digit [place]
  /// (0 = tens, 1 = ones).
  static PagePoint idBubble(int place, int digit) =>
      PagePoint(idFirstX + digit * idPitchX, idFirstY + place * idPitchY);

  /// Left edge of the column that holds [question] (0-based); used for the
  /// printed question number.
  static PagePoint questionLabel(int question) {
    final column = question ~/ kQuestionsPerColumn;
    final row = question % kQuestionsPerColumn;
    return PagePoint(
      questionColumnX + column * questionColumnPitch,
      questionFirstY + row * questionPitchY,
    );
  }

  /// Centre of the bubble for [choice] (0-based) of [question] (0-based).
  static PagePoint questionBubble(int question, int choice) {
    final label = questionLabel(question);
    return PagePoint(label.x + choiceOffsetX + choice * choicePitchX, label.y);
  }
}
