import 'dart:io';

import 'package:egrado/omr/omr_reader.dart';
import 'package:egrado/omr/omr_reading.dart';
import 'package:flutter_test/flutter_test.dart';

/// Photos of sheets printed from the real PDF generator, shaded with uneven
/// pencil scribbles, shot at an angle with a shadow across one side.
///
/// Both have question 11 left blank and question 21 shaded twice; every
/// other question N is answered with choice (N-1) % 4.
void main() {
  final cases = {
    'phone_photo_named_sheet.jpg': 23, // number pre-printed by the app
    'phone_photo_blank_sheet.jpg': 17, // number shaded by the student
  };

  cases.forEach((file, studentNumber) {
    test('reads $file', () {
      final scan = readAnswerSheet(
        File('test/fixtures/$file').readAsBytesSync(),
        questionCount: 50,
        choiceCount: 4,
      );
      final reading = switch (scan) {
        SheetScanSuccess(:final reading) => reading,
        SheetScanFailure(:final problem) => fail(problem.title),
      };

      expect(reading.studentNumber, studentNumber);
      for (var q = 0; q < 50; q++) {
        final answer = reading.answers[q];
        switch (q) {
          case 10:
            expect(answer.status, MarkStatus.blank, reason: 'Q${q + 1}');
          case 20:
            expect(answer.status, MarkStatus.multiple, reason: 'Q${q + 1}');
          default:
            expect(answer.choice, q % 4, reason: 'Q${q + 1}');
            expect(answer.status, MarkStatus.clear, reason: 'Q${q + 1}');
        }
      }
    });
  });
}
