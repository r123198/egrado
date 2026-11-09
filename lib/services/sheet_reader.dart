import 'package:egrado/domain/exam.dart';
import 'package:egrado/omr/omr_reader.dart';
import 'package:egrado/omr/omr_reading.dart';
import 'package:flutter/foundation.dart';

abstract interface class SheetReader {
  Future<SheetScan> read(Uint8List photo, Exam exam);
}

/// Reads sheets on a background isolate so the screen never freezes.
class BackgroundSheetReader implements SheetReader {
  const BackgroundSheetReader();

  /// A photo the image decoder rejects becomes a friendly "could not be
  /// opened" result instead of an error.
  @override
  Future<SheetScan> read(Uint8List photo, Exam exam) async {
    try {
      return await compute(_readJob, (
        bytes: photo,
        questions: exam.questionCount,
        choices: exam.choiceCount,
      ));
    } on Exception {
      return const SheetScanFailure(ScanProblem.unreadableImage);
    }
  }
}

SheetScan _readJob(({Uint8List bytes, int questions, int choices}) job) =>
    readAnswerSheet(
      job.bytes,
      questionCount: job.questions,
      choiceCount: job.choices,
    );
