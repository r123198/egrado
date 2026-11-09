/// What the reader saw in one row of bubbles (one question, or one digit of
/// the student number).
enum MarkStatus {
  /// Exactly one bubble clearly filled.
  clear,

  /// Nothing filled.
  blank,

  /// More than one bubble filled — the reader cannot pick.
  multiple,

  /// A light or partly erased mark; the reader made its best guess.
  unsure,
}

class MarkReading {
  const MarkReading(this.choice, this.status);

  const MarkReading.blank() : choice = null, status = MarkStatus.blank;

  /// Index of the chosen bubble, or null when blank or multiple.
  final int? choice;
  final MarkStatus status;

  /// True when a teacher should glance at this row before saving.
  bool get needsReview =>
      status == MarkStatus.multiple || status == MarkStatus.unsure;
}

/// Everything read from one answer sheet photo.
class OmrReading {
  const OmrReading({required this.studentDigits, required this.answers});

  /// One reading per digit place, most significant first.
  final List<MarkReading> studentDigits;
  final List<MarkReading> answers;

  /// The bubbled student number, or null when any digit is unclear.
  int? get studentNumber {
    var number = 0;
    for (final digit in studentDigits) {
      final value = digit.choice;
      if (value == null || digit.status != MarkStatus.clear) return null;
      number = number * 10 + value;
    }
    return number == 0 ? null : number;
  }
}

/// Why a photo could not be read, phrased for the teacher.
enum ScanProblem {
  unreadableImage(
    'The photo could not be opened.',
    'Please take the photo again.',
  ),
  cornersNotFound(
    'The four black corner squares were not found.',
    'Lay the sheet flat in good light and keep all four corners in the photo.',
  );

  const ScanProblem(this.title, this.advice);

  final String title;
  final String advice;
}

sealed class SheetScan {
  const SheetScan();
}

final class SheetScanSuccess extends SheetScan {
  const SheetScanSuccess(this.reading);

  final OmrReading reading;
}

final class SheetScanFailure extends SheetScan {
  const SheetScanFailure(this.problem);

  final ScanProblem problem;
}
