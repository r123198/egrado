import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:egrado/class_record/cell_ref.dart';
import 'package:meta/meta.dart';
import 'package:xml/xml.dart';

/// The file is not an Excel workbook we can read.
class WorkbookFormatException implements Exception {
  const WorkbookFormatException(this.message);

  final String message;

  @override
  String toString() => 'WorkbookFormatException: $message';
}

/// What one cell holds: its formula (if any) and its value as text.
@immutable
class SheetCell {
  const SheetCell({this.text, this.formula, this.sharedIndex});

  /// The value as shown: a number like `18`, or text. For a formula this is
  /// the last value Excel saved, which may be empty.
  final String? text;

  /// Formula text without the leading `=`.
  final String? formula;

  /// For a shared formula, its group number (`si`).
  final int? sharedIndex;

  num? get number => text == null ? null : num.tryParse(text!);

  bool get isBlank => (text == null || text!.isEmpty) && formula == null;
}

/// Read access to one worksheet.
class Sheet {
  Sheet._(this.name, this._cells, this._sharedMasters);

  final String name;
  final Map<CellRef, SheetCell> _cells;

  /// Shared-formula group → (cell holding the formula text, formula).
  final Map<int, (CellRef, String)> _sharedMasters;

  SheetCell? cell(CellRef ref) => _cells[ref];

  Iterable<MapEntry<CellRef, SheetCell>> get cells => _cells.entries;

  int get maxRow =>
      _cells.keys.fold(0, (max, ref) => ref.row > max ? ref.row : max);

  /// The formula of [ref], with shared formulas expanded for that cell.
  String? formulaAt(CellRef ref) {
    final c = _cells[ref];
    if (c == null) return null;
    final f = c.formula;
    if (f != null && f.isNotEmpty) return f;
    final master = c.sharedIndex == null ? null : _sharedMasters[c.sharedIndex];
    if (master == null) return f;
    final (origin, text) = master;
    return shiftFormula(text, ref.row - origin.row, ref.column - origin.column);
  }
}

/// Moves every relative cell reference in [formula] by the given offsets,
/// the way Excel fills a shared formula down or across.
String shiftFormula(String formula, int rows, int columns) {
  return formula.replaceAllMapped(
    RegExp(
      r'''("[^"]*"|'[^']*')|(?<![A-Za-z_\d.])(\$?)([A-Z]{1,3})(\$?)(\d+)(?![\d(A-Za-z_!])''',
    ),
    (m) {
      // String literals and quoted sheet names stay as they are.
      if (m.group(1) != null) return m.group(0)!;
      final colAbs = m.group(2)!;
      final rowAbs = m.group(4)!;
      final col = colAbs.isEmpty
          ? columnLetter(columnIndex(m.group(3)!) + columns)
          : m.group(3)!;
      final row = rowAbs.isEmpty
          ? int.parse(m.group(5)!) + rows
          : int.parse(m.group(5)!);
      return '$colAbs$col$rowAbs$row';
    },
  );
}

/// An .xlsx file opened for reading, plus numeric edits to write back.
///
/// Editing works on the raw XML text: only the edited `<c>` elements change,
/// so every style, formula, validation rule and extension in the teacher's
/// file is kept exactly. On save the workbook is marked for a full
/// recalculation so the template's own formulas update every grade.
class XlsxWorkbook {
  XlsxWorkbook._(this._archive, this._sheetPaths, this._sharedStrings);

  /// Opens the workbook. Throws [WorkbookFormatException].
  factory XlsxWorkbook.decode(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Exception {
      throw const WorkbookFormatException('Not an .xlsx file');
    } on ArgumentError {
      // The file comes from the teacher's phone and may be anything; a
      // truncated zip makes the decoder index out of range.
      throw const WorkbookFormatException('Not an .xlsx file');
    }
    final workbookXml = _text(archive, 'xl/workbook.xml');
    final relsXml = _text(archive, 'xl/_rels/workbook.xml.rels');
    if (workbookXml == null || relsXml == null) {
      throw const WorkbookFormatException('Not an Excel workbook');
    }
    final targets = <String, String>{};
    for (final rel in _parse(relsXml).findAllElements('Relationship')) {
      final id = rel.getAttribute('Id');
      final target = rel.getAttribute('Target');
      if (id != null && target != null) targets[id] = _resolve(target);
    }
    final sheetPaths = <String, String>{};
    for (final s in _parse(workbookXml).findAllElements('sheet')) {
      final name = s.getAttribute('name');
      final rid = s.attributes
          .where((a) => a.name.local == 'id')
          .map((a) => a.value)
          .firstOrNull;
      final path = rid == null ? null : targets[rid];
      if (name != null && path != null) sheetPaths[name] = path;
    }
    final sharedXml = _text(archive, 'xl/sharedStrings.xml');
    final shared = sharedXml == null
        ? const <String>[]
        : [
            for (final si in _parse(sharedXml).findAllElements('si'))
              si.findAllElements('t').map((t) => t.innerText).join(),
          ];
    return XlsxWorkbook._(archive, sheetPaths, shared);
  }

  final Archive _archive;
  final Map<String, String> _sheetPaths;
  final List<String> _sharedStrings;
  final _sheets = <String, Sheet>{};

  /// Queued edits per sheet: a number or a text value per cell.
  final _edits = <String, Map<CellRef, Object>>{};

  /// Sheet names in workbook order.
  List<String> get sheetNames => List.unmodifiable(_sheetPaths.keys);

  /// The parsed sheet, or null when there is no sheet called [name].
  Sheet? sheet(String name) {
    final cached = _sheets[name];
    if (cached != null) return cached;
    final path = _sheetPaths[name];
    final xml = path == null ? null : _text(_archive, path);
    if (xml == null) return null;
    return _sheets[name] = _parseSheet(name, xml);
  }

  /// Queues [value] to be written into [ref] on [sheetName].
  void setNumber(String sheetName, CellRef ref, num value) =>
      _queue(sheetName, ref, value);

  /// Queues text to be written into [ref] on [sheetName].
  void setText(String sheetName, CellRef ref, String value) =>
      _queue(sheetName, ref, value);

  void _queue(String sheetName, CellRef ref, Object value) {
    if (!_sheetPaths.containsKey(sheetName)) {
      throw ArgumentError.value(sheetName, 'sheetName', 'No such sheet');
    }
    (_edits[sheetName] ??= {})[ref] = value;
  }

  bool get hasEdits => _edits.values.any((e) => e.isNotEmpty);

  /// The workbook bytes with every queued edit applied.
  Uint8List encode() {
    final changed = <String, String>{};
    for (final MapEntry(key: sheetName, value: edits) in _edits.entries) {
      final path = _sheetPaths[sheetName]!;
      var xml = changed[path] ?? _text(_archive, path)!;
      for (final MapEntry(key: ref, value: value) in edits.entries) {
        xml = _writeCell(xml, ref, value);
      }
      changed[path] = xml;
    }
    final hadCalcChain = _archive.findFile('xl/calcChain.xml') != null;
    changed['xl/workbook.xml'] = _forceRecalc(
      _text(_archive, 'xl/workbook.xml')!,
    );
    if (hadCalcChain) {
      // A stale calculation chain makes Excel report the file as damaged.
      changed['[Content_Types].xml'] = _text(
        _archive,
        '[Content_Types].xml',
      )!.replaceAll(RegExp(r'<Override[^>]*calcChain\.xml"[^>]*/>'), '');
      changed['xl/_rels/workbook.xml.rels'] = _text(
        _archive,
        'xl/_rels/workbook.xml.rels',
      )!.replaceAll(RegExp(r'<Relationship[^>]*calcChain\.xml"[^>]*/>'), '');
    }
    final out = Archive();
    for (final file in _archive) {
      if (!file.isFile) continue;
      if (file.name == 'xl/calcChain.xml') continue;
      final text = changed[file.name];
      out.addFile(
        ArchiveFile.bytes(
          file.name,
          text == null ? file.content : utf8.encode(text),
        ),
      );
    }
    return ZipEncoder().encodeBytes(out);
  }

  Sheet _parseSheet(String name, String xml) {
    final cells = <CellRef, SheetCell>{};
    final masters = <int, (CellRef, String)>{};
    for (final c in _parse(xml).findAllElements('c')) {
      final ref = CellRef.tryParse(c.getAttribute('r') ?? '');
      if (ref == null) continue;
      final f = c.getElement('f');
      final type = c.getAttribute('t');
      final v = c.getElement('v')?.innerText;
      final text = switch (type) {
        's' => _sharedString(v),
        'inlineStr' => c.getElement('is')?.innerText,
        _ => v,
      };
      final si = int.tryParse(f?.getAttribute('si') ?? '');
      final formula = f?.innerText;
      if (si != null && formula != null && formula.isNotEmpty) {
        masters[si] = (ref, formula);
      }
      cells[ref] = SheetCell(text: text, formula: formula, sharedIndex: si);
    }
    return Sheet._(name, cells, masters);
  }

  String? _sharedString(String? index) {
    final i = int.tryParse(index ?? '');
    return i == null || i < 0 || i >= _sharedStrings.length
        ? null
        : _sharedStrings[i];
  }

  static XmlDocument _parse(String xml) {
    try {
      return XmlDocument.parse(xml);
    } on XmlException {
      throw const WorkbookFormatException('Damaged workbook XML');
    }
  }

  static String? _text(Archive archive, String path) {
    final f = archive.findFile(path);
    return f == null ? null : utf8.decode(f.content, allowMalformed: true);
  }

  /// Relationship targets are relative to `xl/` unless they start with `/`.
  static String _resolve(String target) =>
      target.startsWith('/') ? target.substring(1) : 'xl/$target';
}

/// Sets `fullCalcOnLoad="1"` on `<calcPr>`, adding the element if needed.
String _forceRecalc(String workbookXml) {
  final calcPr = RegExp(r'<calcPr\b[^>]*?/?>').firstMatch(workbookXml);
  if (calcPr != null) {
    final tag = calcPr.group(0)!;
    if (tag.contains('fullCalcOnLoad=')) {
      return workbookXml.replaceFirst(
        tag,
        tag.replaceFirst(
          RegExp(r'fullCalcOnLoad="[^"]*"'),
          'fullCalcOnLoad="1"',
        ),
      );
    }
    return workbookXml.replaceFirst(
      tag,
      tag.replaceFirst('<calcPr', '<calcPr fullCalcOnLoad="1"'),
    );
  }
  // calcPr must follow sheets / externalReferences / definedNames.
  for (final anchor in [
    '</definedNames>',
    '</externalReferences>',
    '</sheets>',
  ]) {
    final at = workbookXml.lastIndexOf(anchor);
    if (at >= 0) {
      final end = at + anchor.length;
      return '${workbookXml.substring(0, end)}<calcPr fullCalcOnLoad="1"/>'
          '${workbookXml.substring(end)}';
    }
  }
  return workbookXml;
}

/// Replaces (or inserts) cell [ref] in a worksheet's XML with a number or
/// text, keeping the cell's style.
String _writeCell(String xml, CellRef ref, Object value) {
  final cellPattern = RegExp(
    '<c\\s[^>]*?\\br="$ref"[^>]*?(?:/>|>.*?</c>)',
    dotAll: true,
  );
  final existing = cellPattern.firstMatch(xml);
  if (existing != null) {
    final open = RegExp(r'<c\s[^>]*?(?=/?>)').firstMatch(existing.group(0)!)!;
    final style = RegExp(r'\ss="(\d+)"').firstMatch(open.group(0)!)?.group(1);
    final replacement = _cellXml(ref, style, value);
    return xml.replaceRange(existing.start, existing.end, replacement);
  }
  return _insertCell(xml, ref, _cellXml(ref, null, value));
}

String _cellXml(CellRef ref, String? style, Object value) {
  final s = style == null ? '' : ' s="$style"';
  if (value is num) {
    final number = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return '<c r="$ref"$s><v>$number</v></c>';
  }
  final text = const HtmlEscape(HtmlEscapeMode.element).convert('$value');
  return '<c r="$ref"$s t="inlineStr"><is><t xml:space="preserve">$text</t></is></c>';
}

/// Adds a new cell in column order inside its row, creating the row if
/// the sheet has none for it.
String _insertCell(String xml, CellRef ref, String cellXml) {
  final rowPattern = RegExp(
    '<row\\s[^>]*?\\br="${ref.row}"[^>]*?(?:/>|>.*?</row>)',
    dotAll: true,
  );
  final row = rowPattern.firstMatch(xml);
  if (row != null) {
    final rowXml = row.group(0)!;
    if (rowXml.endsWith('/>')) {
      final opened = '${rowXml.substring(0, rowXml.length - 2)}>$cellXml</row>';
      return xml.replaceRange(row.start, row.end, opened);
    }
    var insertAt = rowXml.lastIndexOf('</row>');
    for (final c in RegExp(r'<c\s[^>]*?\br="([A-Z]+)\d+"').allMatches(rowXml)) {
      if (columnIndex(c.group(1)!) > ref.column) {
        insertAt = c.start;
        break;
      }
    }
    final newRow =
        rowXml.substring(0, insertAt) + cellXml + rowXml.substring(insertAt);
    return xml.replaceRange(row.start, row.end, newRow);
  }
  final newRow = '<row r="${ref.row}">$cellXml</row>';
  for (final r in RegExp(r'<row\s[^>]*?\br="(\d+)"').allMatches(xml)) {
    if (int.parse(r.group(1)!) > ref.row) {
      return xml.replaceRange(r.start, r.start, newRow);
    }
  }
  final end = xml.indexOf('</sheetData>');
  if (end >= 0) return xml.replaceRange(end, end, newRow);
  return xml.replaceFirst(
    RegExp(r'<sheetData\s*/>'),
    '<sheetData>$newRow</sheetData>',
  );
}
