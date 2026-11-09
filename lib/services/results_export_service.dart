import 'dart:io';
import 'dart:ui';

import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/exam_result.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/export/results_csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// The spreadsheet could not be created.
class ExportFailedException implements Exception {
  const ExportFailedException();
}

abstract interface class ResultsExportService {
  /// Saves the scores as a spreadsheet and opens the share menu.
  /// [origin] is where the share popover points on iPad.
  /// Throws [ExportFailedException].
  Future<void> export({
    required SchoolClass schoolClass,
    required Exam exam,
    required List<ExamResult> results,
    Rect? origin,
  });
}

class CsvShareExportService implements ResultsExportService {
  const CsvShareExportService();

  @override
  Future<void> export({
    required SchoolClass schoolClass,
    required Exam exam,
    required List<ExamResult> results,
    Rect? origin,
  }) async {
    final csv = buildResultsCsv(
      schoolClass: schoolClass,
      exam: exam,
      results: results,
    );
    try {
      final dir = await getTemporaryDirectory();
      final name = '${schoolClass.name} - ${exam.title}'
          .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '')
          .trim();
      final file = File('${dir.path}/${name.isEmpty ? 'scores' : name}.csv');
      await file.writeAsString(csv, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: '${exam.title} scores – ${schoolClass.name}',
          sharePositionOrigin: origin,
        ),
      );
    } on FileSystemException {
      throw const ExportFailedException();
    }
  }
}
