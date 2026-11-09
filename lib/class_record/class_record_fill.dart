import 'package:egrado/class_record/cell_ref.dart';
import 'package:egrado/class_record/class_record_layout.dart';
import 'package:egrado/class_record/xlsx_workbook.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:meta/meta.dart';

/// A scored test to put into the class record.
@immutable
class RecordActivity {
  RecordActivity({
    required this.id,
    required this.title,
    required this.period,
    required this.component,
    required this.highestScore,
    required Map<int, int> scores,
    this.examPart,
  }) : scores = Map.unmodifiable(scores);

  /// The test's id, used to remember which column it went into.
  final String id;
  final String title;
  final int period;
  final GradeComponent component;
  final ExamPart? examPart;
  final int highestScore;

  /// Raw score per student number.
  final Map<int, int> scores;
}

/// Where a test was written: sheet name, spreadsheet column, and the
/// Highest Possible Score put there (to recognise the column next time).
@immutable
class ColumnPlacement {
  const ColumnPlacement(this.sheetName, this.column, this.highestScore);

  final String sheetName;
  final int column;
  final int highestScore;

  /// "TERM 1, column F".
  String get label => '$sheetName, column ${columnLetter(column)}';

  @override
  bool operator ==(Object other) =>
      other is ColumnPlacement &&
      other.sheetName == sheetName &&
      other.column == column &&
      other.highestScore == highestScore;

  @override
  int get hashCode => Object.hash(sheetName, column, highestScore);
}

/// Why a test could not be written.
enum SkipReason {
  /// The record has no sheet for this term/quarter.
  noSuchPeriod,

  /// Every column of this kind already has a score typed in.
  noFreeColumn,

  /// The test has no answer key yet (HPS 0).
  noHighestScore,
}

/// What happened to one test.
@immutable
class ActivityOutcome {
  const ActivityOutcome.written({
    required this.activity,
    required this.placement,
    required this.columnLabel,
    required this.scoresWritten,
    this.leftBehind,
  }) : skipReason = null;

  const ActivityOutcome.skipped(
    this.activity,
    SkipReason this.skipReason, {
    this.leftBehind,
  }) : placement = null,
       columnLabel = null,
       scoresWritten = 0;

  final RecordActivity activity;
  final ColumnPlacement? placement;

  /// Where this test was written last time, when it now goes elsewhere
  /// (it was moved to another term or kind). The old scores are still
  /// there; the teacher should delete them.
  final ColumnPlacement? leftBehind;

  /// "TERM 1 · WW 3".
  final String? columnLabel;
  final int scoresWritten;
  final SkipReason? skipReason;

  bool get isWritten => placement != null;
}

/// The result of filling a class record.
@immutable
class FillReport {
  FillReport({
    required List<ActivityOutcome> outcomes,
    required Set<int> studentsNotInRecord,
  }) : outcomes = List.unmodifiable(outcomes),
       studentsNotInRecord = Set.unmodifiable(studentsNotInRecord);

  final List<ActivityOutcome> outcomes;

  /// Students who have scores but no row in the class record.
  final Set<int> studentsNotInRecord;

  int get writtenCount => outcomes.where((o) => o.isWritten).length;

  /// Placements to remember, so filling again updates the same columns.
  Map<String, ColumnPlacement> get placements => {
    for (final o in outcomes) o.activity.id: ?o.placement,
  };
}

/// Writes every activity's Highest Possible Score and raw scores into the
/// class record in [workbook].
///
/// A test goes back into the column it used last time ([previous]) when
/// that column is still the right kind and still holds what the app wrote
/// there. Otherwise it goes into the first column of its kind that is
/// completely empty (HPS and every learner), so scores a teacher typed by
/// hand are never overwritten. Exams go to their own ST1/ST2/TE column (or
/// the single QA column). Cells holding formulas are never touched.
FillReport fillClassRecord({
  required XlsxWorkbook workbook,
  required ClassRecordLayout layout,
  required List<RecordActivity> activities,
  required Map<int, String> recordNames,
  Map<String, ColumnPlacement> previous = const {},
}) {
  final taken = <(String, int)>{};
  final outcomes = <ActivityOutcome>[];
  final notInRecord = <int>{};
  for (final activity in activities) {
    final before = previous[activity.id];
    final beforeSheet = before == null
        ? null
        : layout.bySheet(before.sheetName);
    // Last time's column is only reused if it is still ours (see above).
    final reusable =
        before != null &&
        beforeSheet != null &&
        _stillOurs(workbook, beforeSheet, before);
    if (reusable) taken.add((before.sheetName, before.column));
    final skip = activity.highestScore <= 0
        ? SkipReason.noHighestScore
        : layout.period(activity.period) == null
        ? SkipReason.noSuchPeriod
        : null;
    if (skip != null) {
      outcomes.add(
        ActivityOutcome.skipped(
          activity,
          skip,
          leftBehind: reusable ? before : null,
        ),
      );
      continue;
    }
    final sheet = layout.period(activity.period)!;
    final pool = _pool(sheet, activity);
    final ScoreColumn? column;
    if (reusable &&
        before.sheetName == sheet.sheetName &&
        pool.any((c) => c.column == before.column)) {
      column = pool.firstWhere((c) => c.column == before.column);
    } else {
      column = pool
          .where((c) => !taken.contains((sheet.sheetName, c.column)))
          .where((c) => _isEmpty(workbook, sheet, c))
          .firstOrNull;
    }
    final moved =
        reusable &&
            (column == null ||
                column.column != before.column ||
                sheet.sheetName != before.sheetName)
        ? before
        : null;
    if (column == null) {
      outcomes.add(
        ActivityOutcome.skipped(
          activity,
          SkipReason.noFreeColumn,
          leftBehind: moved,
        ),
      );
      continue;
    }
    taken.add((sheet.sheetName, column.column));
    final written = _write(workbook, sheet, column, activity, recordNames);
    notInRecord.addAll(written.missing);
    outcomes.add(
      ActivityOutcome.written(
        activity: activity,
        placement: ColumnPlacement(
          sheet.sheetName,
          column.column,
          activity.highestScore,
        ),
        columnLabel: '${sheet.sheetName} · ${column.label}',
        scoresWritten: written.count,
        leftBehind: moved,
      ),
    );
  }
  return FillReport(outcomes: outcomes, studentsNotInRecord: notInRecord);
}

/// The columns [activity] may go into, in order of preference.
List<ScoreColumn> _pool(PeriodSheet sheet, RecordActivity activity) {
  final candidates = sheet.columnsFor(activity.component);
  if (activity.component != GradeComponent.exam) return candidates;
  final exact = candidates
      .where((c) => c.examPart == activity.examPart)
      .toList();
  if (exact.isNotEmpty) return exact;
  // A DO 8 record has one QA column: any exam goes there. A DO 015 record
  // has ST1/ST2/TE: an exam tagged QA counts as the Term Exam.
  final qa = candidates
      .where((c) => c.examPart == ExamPart.quarterlyAssessment)
      .toList();
  return qa.isNotEmpty
      ? qa
      : candidates.where((c) => c.examPart == ExamPart.termExam).toList();
}

/// True when the column's HPS and every learner's cell are blank.
bool _isEmpty(XlsxWorkbook workbook, PeriodSheet sheet, ScoreColumn c) {
  final grid = workbook.sheet(sheet.sheetName);
  bool blank(int row) => grid?.cell(CellRef(c.column, row))?.isBlank ?? true;
  return blank(sheet.highestScoreRow) &&
      sheet.learners.every((l) => blank(l.row));
}

/// True when [placement] still holds the HPS the app wrote there — so it
/// is the same class record, and the teacher hasn't reused the column.
bool _stillOurs(
  XlsxWorkbook workbook,
  PeriodSheet sheet,
  ColumnPlacement placement,
) {
  final hps = workbook
      .sheet(sheet.sheetName)
      ?.cell(CellRef(placement.column, sheet.highestScoreRow));
  return hps?.number == placement.highestScore;
}

({int count, Set<int> missing}) _write(
  XlsxWorkbook workbook,
  PeriodSheet sheet,
  ScoreColumn column,
  RecordActivity activity,
  Map<int, String> recordNames,
) {
  final grid = workbook.sheet(sheet.sheetName);
  bool writable(CellRef ref) => grid?.cell(ref)?.formula == null;

  final hpsRef = CellRef(column.column, sheet.highestScoreRow);
  if (writable(hpsRef)) {
    workbook.setNumber(sheet.sheetName, hpsRef, activity.highestScore);
  }
  final rowByName = {for (final l in sheet.learners) l.name: l.row};
  var count = 0;
  final missing = <int>{};
  for (final MapEntry(key: number, value: raw) in activity.scores.entries) {
    final name = recordNames[number];
    final row = name == null ? null : rowByName[name];
    if (row == null) {
      missing.add(number);
      continue;
    }
    final ref = CellRef(column.column, row);
    if (!writable(ref)) continue;
    workbook.setNumber(
      sheet.sheetName,
      ref,
      raw.clamp(0, activity.highestScore),
    );
    count++;
  }
  return (count: count, missing: missing);
}
