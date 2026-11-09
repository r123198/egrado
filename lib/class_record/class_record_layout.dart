import 'package:egrado/class_record/cell_ref.dart';
import 'package:egrado/class_record/xlsx_workbook.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:meta/meta.dart';

/// The file opened fine but doesn't look like a DepEd E-Class Record.
class NotAClassRecordException implements Exception {
  const NotAClassRecordException();
}

/// One raw-score column, e.g. WW 3 or ST1.
@immutable
class ScoreColumn {
  const ScoreColumn({
    required this.component,
    required this.slot,
    required this.column,
    this.examPart,
  });

  final GradeComponent component;

  /// 1-based position inside the component (WW 1, WW 2, …).
  final int slot;
  final ExamPart? examPart;

  /// 1-based spreadsheet column.
  final int column;

  /// Short label as a teacher would say it: "WW 3", "PT 1", "ST1", "TE".
  String get label => examPart?.code ?? '${component.code} $slot';
}

/// A learner row on a grading-period sheet.
@immutable
class LearnerRow {
  const LearnerRow({required this.row, required this.name});

  final int row;
  final String name;
}

/// One grading-period sheet (Term 1, MATH_Q2, …) and where things are.
@immutable
class PeriodSheet {
  PeriodSheet({
    required this.sheetName,
    required this.period,
    required this.highestScoreRow,
    required List<ScoreColumn> columns,
    required List<LearnerRow> learners,
  }) : columns = List.unmodifiable(columns),
       learners = List.unmodifiable(learners);

  final String sheetName;

  /// 1-based term or quarter.
  final int period;

  /// The "HIGHEST POSSIBLE SCORE" row.
  final int highestScoreRow;
  final List<ScoreColumn> columns;
  final List<LearnerRow> learners;

  List<ScoreColumn> columnsFor(GradeComponent component) =>
      columns.where((c) => c.component == component).toList();
}

/// Where every grading period, score column and learner is in a class
/// record, found by reading the sheets rather than assuming cell positions:
/// DepEd's templates (three-term Grades 2-10, Strengthened SHS, DO 8
/// quarterly) all place them differently.
@immutable
class ClassRecordLayout {
  ClassRecordLayout(List<PeriodSheet> periods)
    : periods = List.unmodifiable(periods);

  /// Throws [NotAClassRecordException] when no grading sheet is found.
  factory ClassRecordLayout.detect(XlsxWorkbook workbook) {
    final found = <PeriodSheet>[];
    for (final name in workbook.sheetNames) {
      final sheet = workbook.sheet(name);
      if (sheet == null) continue;
      final period = _detectPeriodSheet(workbook, sheet, found.length + 1);
      if (period != null) found.add(period);
    }
    if (found.isEmpty) throw const NotAClassRecordException();
    found.sort((a, b) => a.period.compareTo(b.period));
    return ClassRecordLayout(found);
  }

  final List<PeriodSheet> periods;

  PeriodSheet? period(int number) {
    for (final p in periods) {
      if (p.period == number) return p;
    }
    return null;
  }

  PeriodSheet? bySheet(String sheetName) {
    for (final p in periods) {
      if (p.sheetName == sheetName) return p;
    }
    return null;
  }

  /// Every learner name, from the first period sheet that has them.
  List<String> get learnerNames {
    for (final p in periods) {
      if (p.learners.isNotEmpty) {
        return [for (final l in p.learners) l.name];
      }
    }
    return const [];
  }
}

String _norm(String? s) =>
    (s ?? '').toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();

PeriodSheet? _detectPeriodSheet(
  XlsxWorkbook workbook,
  Sheet sheet,
  int fallbackPeriod,
) {
  final hpsRow = _findHighestScoreRow(sheet);
  if (hpsRow == null) return null;
  final columns = _scoreColumns(sheet, hpsRow);
  if (columns.isEmpty) return null;
  final firstScoreColumn = columns
      .map((c) => c.column)
      .reduce((a, b) => a < b ? a : b);
  return PeriodSheet(
    sheetName: sheet.name,
    period: _periodNumber(sheet) ?? fallbackPeriod,
    highestScoreRow: hpsRow,
    columns: columns,
    learners: _learners(workbook, sheet, hpsRow, firstScoreColumn),
  );
}

int? _findHighestScoreRow(Sheet sheet) {
  for (final MapEntry(key: ref, value: cell) in sheet.cells) {
    if (ref.column <= 6 && _norm(cell.text) == 'HIGHEST POSSIBLE SCORE') {
      return ref.row;
    }
  }
  return null;
}

GradeComponent? _componentOf(String header) {
  final h = _norm(header);
  if (h.contains('WRITTEN')) return GradeComponent.writtenWork;
  if (h.contains('PERFORMANCE')) return GradeComponent.performanceTask;
  if (h.contains('EXAMINATION') || h.contains('QUARTERLY ASSESSMENT')) {
    return GradeComponent.exam;
  }
  return null;
}

const _examLabels = {
  'ST1': ExamPart.summativeTest1,
  'ST2': ExamPart.summativeTest2,
  'TE': ExamPart.termExam,
};

/// Reads the label row just above "HIGHEST POSSIBLE SCORE": numbered
/// columns (1, 2, 3…) and ST1/ST2/TE are where raw scores go; Total, PS
/// and WS are formulas and are left alone.
List<ScoreColumn> _scoreColumns(Sheet sheet, int hpsRow) {
  final labelRow = hpsRow - 1;
  final headers = <(int, GradeComponent)>[];
  for (final MapEntry(key: ref, value: cell) in sheet.cells) {
    if (ref.row >= labelRow || ref.row < labelRow - 6) continue;
    final component = _componentOf(cell.text ?? '');
    if (component != null) headers.add((ref.column, component));
  }
  if (headers.isEmpty) return const [];
  headers.sort((a, b) => a.$1.compareTo(b.$1));

  GradeComponent? ownerOf(int column) {
    GradeComponent? owner;
    for (final (start, component) in headers) {
      if (start <= column) owner = component;
    }
    return owner;
  }

  final labels = [
    for (final e in sheet.cells)
      if (e.key.row == labelRow) e,
  ]..sort((a, b) => a.key.column.compareTo(b.key.column));
  final out = <ScoreColumn>[];
  for (final MapEntry(key: ref, value: cell) in labels) {
    final component = ownerOf(ref.column);
    if (component == null) continue;
    final text = _norm(cell.text).replaceAll(' ', '');
    final slot = num.tryParse(text);
    final hpsCell = sheet.cell(CellRef(ref.column, hpsRow));
    // A formula in the HPS row means a computed column, not an input.
    if (hpsCell?.formula != null) continue;
    if (component == GradeComponent.exam) {
      final part =
          _examLabels[text] ??
          (slot != null ? ExamPart.quarterlyAssessment : null);
      if (part == null) continue;
      out.add(
        ScoreColumn(
          component: component,
          slot: out.where((c) => c.component == component).length + 1,
          column: ref.column,
          examPart: part,
        ),
      );
    } else if (slot != null && slot == slot.roundToDouble() && slot > 0) {
      out.add(
        ScoreColumn(
          component: component,
          slot: slot.toInt(),
          column: ref.column,
        ),
      );
    }
  }
  return out;
}

/// "TERM 2", "Term 2", "MATH_Q3", "2ND" → the period number.
int? _periodNumber(Sheet sheet) {
  final name = _norm(sheet.name);
  final patterns = [
    RegExp(r'TERM\s*(\d)'),
    RegExp(r'(?:^|[^A-Z])Q(\d)\b'),
    RegExp(r'^(\d)(?:ST|ND|RD|TH)\b'),
  ];
  for (final p in patterns) {
    final m = p.firstMatch(name);
    if (m != null) return int.parse(m.group(1)!);
  }
  return null;
}

const _notNames = {'MALE', 'FEMALE', "LEARNERS' NAMES", 'LEARNERS NAMES'};

/// Learner rows below the HPS row. A name is the cell's saved value, or —
/// since templates show names through formulas like `='INPUT DATA'!K11`
/// that are often saved without a value — the cell that formula points at.
List<LearnerRow> _learners(
  XlsxWorkbook workbook,
  Sheet sheet,
  int hpsRow,
  int firstScoreColumn,
) {
  final out = <LearnerRow>[];
  final seen = <String, int>{};
  final lastRow = sheet.maxRow;
  for (var row = hpsRow + 1; row <= lastRow; row++) {
    // Every template numbers its learner rows (1, 2, 3…) left of the name;
    // that keeps footers like "Prepared by:" from passing as learners.
    var numbered = false;
    for (var col = 1; col < firstScoreColumn; col++) {
      final ref = CellRef(col, row);
      final cell = sheet.cell(ref);
      final n = cell?.formula == null ? cell?.number : null;
      if (n != null && n >= 1 && n <= 200) {
        numbered = true;
        continue;
      }
      if (!numbered) continue;
      final name = _nameAt(workbook, sheet, ref);
      if (name == null) continue;
      // Two learners with the same name get "(2)", "(3)"… so each row can
      // be told apart in the review list and when writing scores.
      final count = seen[name] = (seen[name] ?? 0) + 1;
      out.add(LearnerRow(row: row, name: count == 1 ? name : '$name ($count)'));
      break;
    }
  }
  return out;
}

String? _nameAt(XlsxWorkbook workbook, Sheet sheet, CellRef ref) {
  final cell = sheet.cell(ref);
  if (cell == null) return null;
  final saved = _asName(cell.text);
  if (saved != null) return saved;
  final formula = sheet.formulaAt(ref);
  if (formula == null) return null;
  final target = _firstSheetReference(formula);
  if (target == null) return null;
  final (sheetName, targetRef) = target;
  return _asName(workbook.sheet(sheetName)?.cell(targetRef)?.text);
}

/// A real name: has letters, isn't a number or a section label.
String? _asName(String? text) {
  final t = (text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (t.isEmpty || num.tryParse(t) != null) return null;
  if (!RegExp('[A-Za-zÀ-ÿÑñ]').hasMatch(t)) return null;
  if (_notNames.contains(t.toUpperCase())) return null;
  return t;
}

/// The first `'Sheet name'!A1` or `Sheet!A1` in a formula. References to
/// other workbooks (`[2]INPUT DATA`) are skipped: that file isn't here.
(String, CellRef)? _firstSheetReference(String formula) {
  final pattern = RegExp(
    r"(?:'((?:[^']|'')+)'|([A-Za-z_][\w.]*))!\$?([A-Z]{1,3})\$?(\d+)",
  );
  for (final m in pattern.allMatches(formula)) {
    final name = (m.group(1) ?? m.group(2)!).replaceAll("''", "'");
    if (name.startsWith('[')) continue;
    final ref = CellRef.tryParse('${m.group(3)}${m.group(4)}');
    if (ref != null) return (name, ref);
  }
  return null;
}
