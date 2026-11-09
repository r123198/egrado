import 'dart:typed_data';

import 'package:egrado/omr/homography.dart';
import 'package:egrado/omr/omr_reader.dart';
import 'package:egrado/omr/omr_reading.dart';
import 'package:egrado/omr/sheet_layout.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_sheet_photo.dart';

OmrReading _read(Uint8List photo, {int questions = 30, int choices = 4}) {
  final scan = readAnswerSheet(
    photo,
    questionCount: questions,
    choiceCount: choices,
  );
  return switch (scan) {
    SheetScanSuccess(:final reading) => reading,
    SheetScanFailure(:final problem) => fail('Scan failed: ${problem.title}'),
  };
}

void main() {
  // Every question answered, cycling A, B, C, D…
  final answers = {
    for (var q = 0; q < 30; q++) q: [q % 4],
  };

  group('classifyRow', () {
    test('one solid bubble is a clear answer', () {
      final r = classifyRow([0.02, 0.9, 0.05, 0.0]);
      expect(r.choice, 1);
      expect(r.status, MarkStatus.clear);
    });

    test('all empty is blank', () {
      expect(classifyRow([0.0, 0.1, 0.05]).status, MarkStatus.blank);
    });

    test('two solid bubbles is multiple with no choice', () {
      final r = classifyRow([0.9, 0.0, 0.8]);
      expect(r.status, MarkStatus.multiple);
      expect(r.choice, isNull);
    });

    test('a light mark is a best guess flagged unsure', () {
      final r = classifyRow([0.0, 0.35, 0.0]);
      expect(r.choice, 1);
      expect(r.status, MarkStatus.unsure);
    });

    test('a solid mark next to a half-erased one is unsure', () {
      final r = classifyRow([0.95, 0.3, 0.0]);
      expect(r.choice, 0);
      expect(r.status, MarkStatus.unsure);
    });
  });

  test('homography maps the four reference points exactly', () {
    const to = [
      PagePoint(100, 80),
      PagePoint(1150, 120),
      PagePoint(1180, 1700),
      PagePoint(60, 1650),
    ];
    final h = Homography.fromPoints(SheetLayout.markerCenters, to)!;
    for (var i = 0; i < 4; i++) {
      final p = h.map(SheetLayout.markerCenters[i]);
      expect(p.x, closeTo(to[i].x, 1e-6));
      expect(p.y, closeTo(to[i].y, 1e-6));
    }
  });

  group('readAnswerSheet', () {
    test('reads student number and every answer from a straight photo', () {
      final reading = _read(
        fakeSheetPhoto(
          questionCount: 30,
          choiceCount: 4,
          studentNumber: 7,
          answers: answers,
        ),
      );
      expect(reading.studentNumber, 7);
      expect(
        [for (final a in reading.answers) a.choice],
        [for (var q = 0; q < 30; q++) q % 4],
      );
      expect(reading.answers.any((a) => a.needsReview), isFalse);
    });

    for (final angle in [90, 180, 270, 7, -6]) {
      test('reads a photo turned $angle°', () {
        final reading = _read(
          fakeSheetPhoto(
            questionCount: 30,
            choiceCount: 4,
            studentNumber: 42,
            answers: answers,
            rotateDegrees: angle,
          ),
        );
        expect(reading.studentNumber, 42);
        expect(
          [for (final a in reading.answers) a.choice],
          [for (var q = 0; q < 30; q++) q % 4],
        );
      });
    }

    test('reads all 60 questions with 5 choices', () {
      final full = {
        for (var q = 0; q < 60; q++) q: [(q * 3) % 5],
      };
      final reading = _read(
        fakeSheetPhoto(
          questionCount: 60,
          choiceCount: 5,
          studentNumber: 99,
          answers: full,
        ),
        questions: 60,
        choices: 5,
      );
      expect(reading.studentNumber, 99);
      expect(
        [for (final a in reading.answers) a.choice],
        [for (var q = 0; q < 60; q++) (q * 3) % 5],
      );
    });

    test('flags blank, double and half-erased answers for review', () {
      final reading = _read(
        fakeSheetPhoto(
          questionCount: 30,
          choiceCount: 4,
          studentNumber: 3,
          answers:
              {
                  ...answers,
                  4: [0, 2],
                }
                ..remove(5)
                ..remove(6),
          partialAnswers: {6: 1},
        ),
      );
      expect(reading.answers[4].status, MarkStatus.multiple);
      expect(reading.answers[5].status, MarkStatus.blank);
      expect(reading.answers[6].needsReview, isTrue);
      expect(reading.answers[6].choice, 1);
    });

    test('leaves the student number empty when it was not bubbled', () {
      final reading = _read(
        fakeSheetPhoto(questionCount: 30, choiceCount: 4, answers: answers),
      );
      expect(reading.studentNumber, isNull);
    });

    test('reports missing corners instead of guessing', () {
      final scan = readAnswerSheet(
        fakeSheetPhoto(
          questionCount: 30,
          choiceCount: 4,
          studentNumber: 5,
          answers: answers,
          drawMarkers: false,
        ),
        questionCount: 30,
        choiceCount: 4,
      );
      expect(
        scan,
        isA<SheetScanFailure>().having(
          (f) => f.problem,
          'problem',
          ScanProblem.cornersNotFound,
        ),
      );
    });

    test('reports a file that is not an image', () {
      final scan = readAnswerSheet(
        Uint8List.fromList([1, 2, 3]),
        questionCount: 10,
        choiceCount: 4,
      );
      expect(
        scan,
        isA<SheetScanFailure>().having(
          (f) => f.problem,
          'problem',
          ScanProblem.unreadableImage,
        ),
      );
    });
  });
}
