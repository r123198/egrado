import 'package:meta/meta.dart';

/// A spreadsheet cell address such as `AB18`.
@immutable
class CellRef implements Comparable<CellRef> {
  const CellRef(this.column, this.row);

  /// Parses `AB18` or `$AB$18`. Returns null for anything else.
  static CellRef? tryParse(String text) {
    final m = RegExp(r'^\$?([A-Za-z]{1,3})\$?(\d+)$').firstMatch(text.trim());
    if (m == null) return null;
    final row = int.parse(m.group(2)!);
    if (row < 1) return null;
    return CellRef(columnIndex(m.group(1)!), row);
  }

  /// 1-based column number (A = 1).
  final int column;

  /// 1-based row number.
  final int row;

  String get columnLetters => columnLetter(column);

  @override
  String toString() => '$columnLetters$row';

  @override
  int compareTo(CellRef other) =>
      row != other.row ? row - other.row : column - other.column;

  @override
  bool operator ==(Object other) =>
      other is CellRef && other.column == column && other.row == row;

  @override
  int get hashCode => Object.hash(column, row);
}

/// `A` → 1, `Z` → 26, `AA` → 27.
int columnIndex(String letters) {
  var n = 0;
  for (final unit in letters.toUpperCase().codeUnits) {
    n = n * 26 + (unit - 64);
  }
  return n;
}

/// 1 → `A`, 27 → `AA`.
String columnLetter(int index) {
  var n = index;
  final out = StringBuffer();
  final letters = <String>[];
  while (n > 0) {
    final rem = (n - 1) % 26;
    letters.insert(0, String.fromCharCode(65 + rem));
    n = (n - 1) ~/ 26;
  }
  out.writeAll(letters);
  return out.toString();
}
