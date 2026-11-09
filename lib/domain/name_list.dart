import 'package:meta/meta.dart';

/// One line of text found in a photo, with its position in pixels.
@immutable
class TextLineBox {
  const TextLineBox(
    this.text, {
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get height => bottom - top;
  double get centerY => (top + bottom) / 2;
}

/// Turns the text lines read from a photo of a class list into student
/// names, in reading order.
///
/// Lines at the same height are one row ("Dela Cruz" | "Juan" becomes
/// "Dela Cruz Juan"). When a row holds several "Surname, First" names far
/// apart, it is a list printed in columns (e.g. boys | girls): each column
/// is read top to bottom, left column first. Row numbers, scores, headings
/// and stray marks are dropped.
List<String> namesFromTextLines(List<TextLineBox> lines) {
  final rows = _groupIntoRows(lines);
  final cells = <_Cell>[];
  for (final (rowIndex, row) in rows.indexed) {
    cells.addAll(_cellsOf(row, rowIndex));
  }
  _placeLoneCellsInColumns(cells);
  cells.sort((a, b) {
    final byColumn = a.column.compareTo(b.column);
    return byColumn != 0 ? byColumn : a.row.compareTo(b.row);
  });
  return [for (final cell in cells) ?cleanName(cell.text)];
}

/// A tidy name from one line of a class list, or null if the line is not
/// a name (a heading, a number, a stray mark).
String? cleanName(String raw) {
  var text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  // Leading row number or bullet: "1.", "12)", "No. 3 -", "•".
  text = text.replaceFirst(
    RegExp(r'^(?:no\.?\s*)?\d{1,3}\s*[.):\-]*\s*', caseSensitive: false),
    '',
  );
  text = text.replaceFirst(RegExp(r'^[•·*\-–—]+\s*'), '');
  // Trailing score or number: "95", "87.5%", "M", "F" columns stay out.
  text = text.replaceFirst(RegExp(r'(?:\s+\d+(?:\.\d+)?%?)+$'), '');
  // Keep letters (any language), spaces and name punctuation only.
  text = text
      .replaceAll(RegExp(r"[^\p{L}\s,.'\-]", unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  text = text.replaceAll(RegExp(r'^[,.\-]+|[,\-]+$'), '').trim();

  final letters = RegExp(r'\p{L}', unicode: true).allMatches(text).length;
  if (letters < 2) return null;
  if (_isHeading(text)) return null;
  return text;
}

bool _isHeading(String text) => _headings.contains(
  text
      .toLowerCase()
      .replaceAll(RegExp('[^a-z ]'), '')
      .replaceAll(RegExp(' +'), ' ')
      .trim(),
);

/// Column titles and labels teachers' lists commonly start with.
const _headings = {
  'name',
  'names',
  'no',
  'no name',
  'name of student',
  'name of students',
  'name of learner',
  'name of learners',
  'names of students',
  'names of learners',
  'student',
  'students',
  'student name',
  'student names',
  'students name',
  'students names',
  'learner',
  'learners',
  'learners name',
  'learners names',
  'learner name',
  'last name',
  'first name',
  'middle name',
  'surname',
  'last name first name',
  'surname first name',
  'last name first name middle name',
  'boys',
  'girls',
  'male',
  'female',
  'class list',
  'class record',
  'score',
  'scores',
  'grade',
  'remarks',
  'sex',
  'gender',
};

class _Cell {
  _Cell(this.text, this.left, this.height, this.row, this.column);

  final String text;
  final double left;
  final double height;
  final int row;
  int column;
}

/// Lines whose middles are within half a line height of each other.
List<List<TextLineBox>> _groupIntoRows(List<TextLineBox> lines) {
  final sorted = [...lines.where((l) => l.text.trim().isNotEmpty)]
    ..sort((a, b) => a.centerY.compareTo(b.centerY));
  final rows = <List<TextLineBox>>[];
  for (final line in sorted) {
    final row = rows.isEmpty ? null : rows.last;
    if (row != null && _sameRow(row, line)) {
      row.add(line);
    } else {
      rows.add([line]);
    }
  }
  for (final row in rows) {
    row.sort((a, b) => a.left.compareTo(b.left));
  }
  return rows;
}

bool _sameRow(List<TextLineBox> row, TextLineBox line) {
  final rowCenter =
      row.map((l) => l.centerY).reduce((a, b) => a + b) / row.length;
  final rowHeight =
      row.map((l) => l.height).reduce((a, b) => a + b) / row.length;
  final tolerance = (line.height < rowHeight ? line.height : rowHeight) * 0.5;
  return (line.centerY - rowCenter).abs() <= tolerance;
}

/// One name per row, unless the row is clearly several "Surname, First"
/// names spread across columns.
List<_Cell> _cellsOf(List<TextLineBox> row, int rowIndex) {
  final height = row.map((l) => l.height).reduce((a, b) => a > b ? a : b);
  final groups = <List<TextLineBox>>[
    [row.first],
  ];
  for (final line in row.skip(1)) {
    final gap = line.left - groups.last.last.right;
    if (gap > height * 2.5) {
      groups.add([line]);
    } else {
      groups.last.add(line);
    }
  }
  String join(List<TextLineBox> g) => g.map((l) => l.text.trim()).join(' ');
  final isColumns =
      groups.length > 1 &&
      groups.every((g) => join(g).contains(',') && cleanName(join(g)) != null);
  if (!isColumns) {
    // A heading row ("BOYS    GIRLS") must not become a name.
    final parts = groups.where((g) => !_isHeading(join(g))).toList();
    if (parts.isEmpty) return const [];
    return [
      _Cell(
        parts.map(join).join(' '),
        parts.first.first.left,
        height,
        rowIndex,
        0,
      ),
    ];
  }
  return [
    for (final (i, g) in groups.indexed)
      _Cell(join(g), g.first.left, height, rowIndex, i),
  ];
}

/// In a list printed in columns, a row with only one name (the shorter
/// column ran out) still belongs to the column it lines up with.
void _placeLoneCellsInColumns(List<_Cell> cells) {
  final columnStarts = <int, List<double>>{};
  for (final c in cells.where((c) => c.column > 0)) {
    columnStarts.putIfAbsent(c.column, () => []).add(c.left);
  }
  if (columnStarts.isEmpty) return;
  final starts = {
    for (final MapEntry(:key, :value) in columnStarts.entries)
      key: value.reduce((a, b) => a < b ? a : b),
  };
  final rowSizes = <int, int>{};
  for (final c in cells) {
    rowSizes.update(c.row, (n) => n + 1, ifAbsent: () => 1);
  }
  for (final c in cells.where((c) => rowSizes[c.row] == 1)) {
    for (final MapEntry(key: column, value: start) in starts.entries) {
      if (c.left >= start - c.height && column > c.column) c.column = column;
    }
  }
}
