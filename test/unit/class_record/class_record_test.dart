import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:egrado/class_record/cell_ref.dart';
import 'package:egrado/class_record/class_record_fill.dart';
import 'package:egrado/class_record/class_record_layout.dart';
import 'package:egrado/class_record/name_match.dart';
import 'package:egrado/class_record/xlsx_workbook.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:flutter_test/flutter_test.dart';

/// A real DepEd template and where its INPUT DATA learner names go.
class Template {
  const Template(this.file, this.inputSheet, this.maleName, this.femaleName);

  final String file;
  final String inputSheet;
  final String maleName;
  final String femaleName;

  Uint8List bytes() => File('test/fixtures/ecr/$file').readAsBytesSync();
}

const g2to10 = Template('g2-10_three_term.xlsx', 'INPUT DATA', 'K11', 'N11');
const sshs = Template('sshs_three_term.xlsx', 'INPUT DATA', 'O11', 'S11');
const do8Math = Template('do8_g7-10_math.xlsx', 'INPUT DATA', 'B12', 'B63');
const do8Shs = Template('do8_shs_2016.xlsx', 'INPUT DATA', 'B13', 'B64');

/// The template with two boys and one girl typed into INPUT DATA, as a
/// teacher would before using the app.
XlsxWorkbook withLearners(Template t) {
  final wb = XlsxWorkbook.decode(t.bytes());
  final male = CellRef.tryParse(t.maleName)!;
  final female = CellRef.tryParse(t.femaleName)!;
  wb.setText(t.inputSheet, male, 'DELA CRUZ, JUAN A.');
  wb.setText(t.inputSheet, CellRef(male.column, male.row + 1), 'SANTOS, PEDRO');
  wb.setText(t.inputSheet, female, 'REYES, MARIA CLARA B.');
  return XlsxWorkbook.decode(wb.encode());
}

RecordActivity quiz({
  String id = 'q1',
  int period = 1,
  GradeComponent component = GradeComponent.writtenWork,
  ExamPart? part,
  int hps = 20,
  Map<int, int> scores = const {1: 18, 2: 15, 3: 20},
}) => RecordActivity(
  id: id,
  title: id,
  period: period,
  component: component,
  examPart: part,
  highestScore: hps,
  scores: scores,
);

const names = {
  1: 'DELA CRUZ, JUAN A.',
  2: 'SANTOS, PEDRO',
  3: 'REYES, MARIA CLARA B.',
};

num? valueAt(XlsxWorkbook wb, String sheet, String ref) =>
    wb.sheet(sheet)!.cell(CellRef.tryParse(ref)!)?.number;

void main() {
  group('layout detection on the real DepEd templates', () {
    test('Grades 2-10 three-term: 5 WW, 3 PT, ST1/ST2/TE per term', () {
      final layout = ClassRecordLayout.detect(withLearners(g2to10));
      expect(layout.periods.map((p) => p.sheetName), [
        'TERM 1',
        'TERM 2',
        'TERM 3',
      ]);
      final t1 = layout.period(1)!;
      expect(t1.highestScoreRow, 15);
      expect(
        t1.columnsFor(GradeComponent.writtenWork).map((c) => c.column),
        [6, 7, 8, 9, 10], // F..J
      );
      expect(t1.columnsFor(GradeComponent.exam).map((c) => c.label), [
        'ST1',
        'ST2',
        'TE',
      ]);
      // Names come through formulas whose saved value is empty.
      expect(t1.learners.map((l) => (l.row, l.name)), [
        (18, 'DELA CRUZ, JUAN A.'),
        (19, 'SANTOS, PEDRO'),
        (69, 'REYES, MARIA CLARA B.'),
      ]);
    });

    test('Strengthened SHS three-term: 10 WW, 10 PT, ST1/ST2/TE', () {
      final t1 = ClassRecordLayout.detect(withLearners(sshs)).period(1)!;
      expect(t1.sheetName, 'Term 1');
      expect(t1.highestScoreRow, 14);
      expect(t1.columnsFor(GradeComponent.writtenWork).first.column, 4); // D
      expect(t1.columnsFor(GradeComponent.performanceTask), hasLength(10));
      expect(t1.columnsFor(GradeComponent.exam).map((c) => c.column), [
        30, 31, 32, // AD..AF
      ]);
      expect(t1.learners.map((l) => l.row), [17, 18, 68]);
    });

    test('DO 8 Grade 7-10: four quarters with one QA column', () {
      final layout = ClassRecordLayout.detect(withLearners(do8Math));
      expect(layout.periods.map((p) => p.period), [1, 2, 3, 4]);
      final q1 = layout.period(1)!;
      expect(q1.sheetName, 'MATH_Q1');
      expect(q1.highestScoreRow, 10);
      final exams = q1.columnsFor(GradeComponent.exam);
      expect(exams.single.examPart, ExamPart.quarterlyAssessment);
      expect(exams.single.column, 32); // AF
      expect(q1.learners.map((l) => l.row), [12, 13, 63]);
    });

    test('DO 8 SHS 2016 semester file is detected too', () {
      final layout = ClassRecordLayout.detect(withLearners(do8Shs));
      expect(layout.periods.map((p) => p.sheetName), ['1ST', '2ND']);
      expect(layout.period(1)!.highestScoreRow, 11);
      expect(layout.learnerNames, hasLength(3));
    });

    test('a workbook without grading sheets is rejected', () {
      final archive = Archive()
        ..addFile(
          ArchiveFile.string(
            'xl/workbook.xml',
            '<workbook><sheets><sheet name="A" r:id="rId1" '
                'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>'
                '</sheets></workbook>',
          ),
        )
        ..addFile(
          ArchiveFile.string(
            'xl/_rels/workbook.xml.rels',
            '<Relationships><Relationship Id="rId1" '
                'Target="worksheets/sheet1.xml"/></Relationships>',
          ),
        )
        ..addFile(
          ArchiveFile.string(
            'xl/worksheets/sheet1.xml',
            '<worksheet><sheetData><row r="1"><c r="A1"><v>1</v></c></row>'
                '</sheetData></worksheet>',
          ),
        );
      final wb = XlsxWorkbook.decode(ZipEncoder().encodeBytes(archive));
      expect(
        () => ClassRecordLayout.detect(wb),
        throwsA(isA<NotAClassRecordException>()),
      );
    });

    test('a file that is not a workbook is rejected', () {
      expect(
        () => XlsxWorkbook.decode(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(isA<WorkbookFormatException>()),
      );
    });
  });

  group('filling', () {
    test('writes HPS and scores into the first free WW column', () {
      final wb = withLearners(g2to10);
      final layout = ClassRecordLayout.detect(wb);
      final report = fillClassRecord(
        workbook: wb,
        layout: layout,
        activities: [quiz()],
        recordNames: names,
      );
      expect(report.writtenCount, 1);
      expect(report.outcomes.single.columnLabel, 'TERM 1 · WW 1');
      final saved = XlsxWorkbook.decode(wb.encode());
      expect(valueAt(saved, 'TERM 1', 'F15'), 20);
      expect(valueAt(saved, 'TERM 1', 'F18'), 18);
      expect(valueAt(saved, 'TERM 1', 'F19'), 15);
      expect(valueAt(saved, 'TERM 1', 'F69'), 20);
      // The computed columns keep their formulas.
      expect(
        saved.sheet('TERM 1')!.cell(CellRef.tryParse('K18')!)!.formula,
        isNotNull,
      );
    });

    test('skips columns a teacher already typed into', () {
      final wb = withLearners(g2to10);
      wb.setNumber('TERM 1', CellRef.tryParse('F15')!, 10); // WW 1 by hand
      final typed = XlsxWorkbook.decode(wb.encode());
      final report = fillClassRecord(
        workbook: typed,
        layout: ClassRecordLayout.detect(typed),
        activities: [quiz()],
        recordNames: names,
      );
      expect(report.outcomes.single.columnLabel, 'TERM 1 · WW 2');
      final saved = XlsxWorkbook.decode(typed.encode());
      expect(valueAt(saved, 'TERM 1', 'F15'), 10);
      expect(valueAt(saved, 'TERM 1', 'G15'), 20);
    });

    test('filling again reuses the same column (no duplicates)', () {
      final first = withLearners(g2to10);
      final r1 = fillClassRecord(
        workbook: first,
        layout: ClassRecordLayout.detect(first),
        activities: [quiz()],
        recordNames: names,
      );
      final again = XlsxWorkbook.decode(first.encode());
      final r2 = fillClassRecord(
        workbook: again,
        layout: ClassRecordLayout.detect(again),
        activities: [
          quiz(scores: {1: 19, 2: 15, 3: 20}),
          quiz(id: 'q2'),
        ],
        recordNames: names,
        previous: r1.placements,
      );
      expect(r2.outcomes.map((o) => o.columnLabel), [
        'TERM 1 · WW 1',
        'TERM 1 · WW 2',
      ]);
      final saved = XlsxWorkbook.decode(again.encode());
      expect(valueAt(saved, 'TERM 1', 'F18'), 19);
    });

    test('exams go to their own ST1 / ST2 / TE column', () {
      final wb = withLearners(sshs);
      final report = fillClassRecord(
        workbook: wb,
        layout: ClassRecordLayout.detect(wb),
        activities: [
          quiz(
            id: 'te',
            component: GradeComponent.exam,
            part: ExamPart.termExam,
            hps: 40,
          ),
          quiz(
            id: 'st1',
            component: GradeComponent.exam,
            part: ExamPart.summativeTest1,
          ),
        ],
        recordNames: names,
      );
      expect(report.outcomes.map((o) => o.columnLabel), [
        'Term 1 · TE',
        'Term 1 · ST1',
      ]);
      final saved = XlsxWorkbook.decode(wb.encode());
      expect(valueAt(saved, 'Term 1', 'AF14'), 40);
      expect(valueAt(saved, 'Term 1', 'AD17'), 18);
    });

    test('any exam goes to the single QA column of a DO 8 record', () {
      final wb = withLearners(do8Math);
      final report = fillClassRecord(
        workbook: wb,
        layout: ClassRecordLayout.detect(wb),
        activities: [
          quiz(
            id: 'qa',
            period: 2,
            component: GradeComponent.exam,
            part: ExamPart.termExam,
            hps: 50,
          ),
        ],
        recordNames: names,
      );
      expect(report.outcomes.single.columnLabel, 'MATH_Q2 · QA');
      final saved = XlsxWorkbook.decode(wb.encode());
      expect(valueAt(saved, 'MATH_Q2', 'AF10'), 50);
      expect(valueAt(saved, 'MATH_Q2', 'AF63'), 20);
    });

    test('reports tests that do not fit and students not in the record', () {
      final wb = withLearners(g2to10);
      final report = fillClassRecord(
        workbook: wb,
        layout: ClassRecordLayout.detect(wb),
        activities: [
          quiz(id: 'p4', period: 4),
          quiz(id: 'nokey', hps: 0),
          for (var i = 0; i < 6; i++) quiz(id: 'ww$i', scores: {1: 5, 9: 5}),
        ],
        recordNames: names,
      );
      final reasons = {
        for (final o in report.outcomes) o.activity.id: o.skipReason,
      };
      expect(reasons['p4'], SkipReason.noSuchPeriod);
      expect(reasons['nokey'], SkipReason.noHighestScore);
      expect(reasons['ww5'], SkipReason.noFreeColumn); // only 5 WW columns
      expect(report.studentsNotInRecord, {9});
    });

    test('scores above the HPS are capped', () {
      final wb = withLearners(g2to10);
      fillClassRecord(
        workbook: wb,
        layout: ClassRecordLayout.detect(wb),
        activities: [
          quiz(hps: 10, scores: {1: 12}),
        ],
        recordNames: names,
      );
      final saved = XlsxWorkbook.decode(wb.encode());
      expect(valueAt(saved, 'TERM 1', 'F18'), 10);
    });
  });

  group('review fixes', () {
    test('a column with typed scores but no HPS is not free', () {
      final wb = withLearners(g2to10);
      wb.setNumber('TERM 1', CellRef.tryParse('F18')!, 9); // score, no HPS
      final typed = XlsxWorkbook.decode(wb.encode());
      final report = fillClassRecord(
        workbook: typed,
        layout: ClassRecordLayout.detect(typed),
        activities: [quiz()],
        recordNames: names,
      );
      expect(report.outcomes.single.columnLabel, 'TERM 1 · WW 2');
      final saved = XlsxWorkbook.decode(typed.encode());
      expect(valueAt(saved, 'TERM 1', 'F18'), 9);
    });

    test('a remembered column is not reused in a different file', () {
      // Another file whose WW 1 holds the teacher's own typed quiz.
      final other = withLearners(g2to10);
      other.setNumber('TERM 1', CellRef.tryParse('F15')!, 10);
      other.setNumber('TERM 1', CellRef.tryParse('F18')!, 7);
      final typed = XlsxWorkbook.decode(other.encode());
      final report = fillClassRecord(
        workbook: typed,
        layout: ClassRecordLayout.detect(typed),
        activities: [quiz()],
        recordNames: names,
        previous: {'q1': const ColumnPlacement('TERM 1', 6, 20)},
      );
      expect(report.outcomes.single.columnLabel, 'TERM 1 · WW 2');
      expect(report.outcomes.single.leftBehind, isNull);
      final saved = XlsxWorkbook.decode(typed.encode());
      expect(valueAt(saved, 'TERM 1', 'F18'), 7);
    });

    test('a retagged exam moves to its new column and says where it was', () {
      final first = withLearners(sshs);
      final r1 = fillClassRecord(
        workbook: first,
        layout: ClassRecordLayout.detect(first),
        activities: [
          quiz(
            id: 'x',
            component: GradeComponent.exam,
            part: ExamPart.summativeTest1,
          ),
        ],
        recordNames: names,
      );
      final again = XlsxWorkbook.decode(first.encode());
      final r2 = fillClassRecord(
        workbook: again,
        layout: ClassRecordLayout.detect(again),
        activities: [
          quiz(
            id: 'x',
            component: GradeComponent.exam,
            part: ExamPart.termExam,
          ),
        ],
        recordNames: names,
        previous: r1.placements,
      );
      final o = r2.outcomes.single;
      expect(o.columnLabel, 'Term 1 · TE');
      expect(o.leftBehind?.label, 'Term 1, column AD');
    });

    test('learners with the same name are told apart', () {
      final wb = XlsxWorkbook.decode(g2to10.bytes());
      wb.setText('INPUT DATA', CellRef.tryParse('K11')!, 'SANTOS, MARIA');
      wb.setText('INPUT DATA', CellRef.tryParse('K12')!, 'SANTOS, MARIA');
      final layout = ClassRecordLayout.detect(XlsxWorkbook.decode(wb.encode()));
      expect(layout.learnerNames, ['SANTOS, MARIA', 'SANTOS, MARIA (2)']);
    });
  });

  group('saved file', () {
    test('asks Excel to recalculate and drops the stale calc chain', () {
      final wb = withLearners(do8Math);
      fillClassRecord(
        workbook: wb,
        layout: ClassRecordLayout.detect(wb),
        activities: [quiz()],
        recordNames: names,
      );
      final archive = ZipDecoder().decodeBytes(wb.encode());
      String text(String name) =>
          String.fromCharCodes(archive.findFile(name)!.content);
      expect(archive.findFile('xl/calcChain.xml'), isNull);
      expect(text('xl/workbook.xml'), contains('fullCalcOnLoad="1"'));
      expect(text('[Content_Types].xml'), isNot(contains('calcChain')));
      expect(text('xl/_rels/workbook.xml.rels'), isNot(contains('calcChain')));
    });

    test('leaves every untouched part of the file byte-for-byte', () {
      final original = ZipDecoder().decodeBytes(g2to10.bytes());
      final wb = XlsxWorkbook.decode(g2to10.bytes());
      wb.setNumber('TERM 1', CellRef.tryParse('F15')!, 20);
      final edited = ZipDecoder().decodeBytes(wb.encode());
      for (final f in original) {
        if (!f.isFile) continue;
        if (f.name == 'xl/worksheets/sheet2.xml' ||
            f.name == 'xl/workbook.xml') {
          continue;
        }
        expect(edited.findFile(f.name)!.content, f.content, reason: f.name);
      }
    });
  });

  group('shiftFormula', () {
    test('moves relative references only', () {
      expect(
        shiftFormula(r"'INPUT DATA'!K11&$A$1", 2, 0),
        r"'INPUT DATA'!K13&$A$1",
      );
      expect(shiftFormula('SUM(F18:J18)', 1, 0), 'SUM(F19:J19)');
    });

    test('leaves sheet names and text that look like cells alone', () {
      expect(shiftFormula("'Q1'!B2", 1, 0), "'Q1'!B3");
      expect(shiftFormula('MATH_Q1!B12', 1, 0), 'MATH_Q1!B13');
      expect(shiftFormula('IF(A1="B2",1,0)', 1, 0), 'IF(A2="B2",1,0)');
    });
  });

  group('name matching', () {
    test('matches reordered names with commas and initials', () {
      expect(
        matchNames({
          1: 'Juan Dela Cruz',
          2: 'Maria Clara Reyes',
          3: 'Pedro Santos',
        }, names.values.toList()),
        {
          1: 'DELA CRUZ, JUAN A.',
          2: 'REYES, MARIA CLARA B.',
          3: 'SANTOS, PEDRO',
        },
      );
    });

    test('ignores accents and ñ', () {
      expect(nameMatchScore('José Peña', 'PENA, JOSE'), greaterThan(0));
    });

    test('a contradicting middle initial is not a match', () {
      expect(nameMatchScore('Juan B. Dela Cruz', 'DELA CRUZ, JUAN A.'), 0);
    });

    test('one shared word is not enough', () {
      expect(nameMatchScore('Juan', 'DELA CRUZ, JUAN A.'), 0);
      expect(isExactNameMatch('Juan Cruz', 'DELA CRUZ, JUAN'), isFalse);
      expect(isExactNameMatch('Juan Dela Cruz', 'DELA CRUZ, JUAN A.'), isTrue);
      expect(nameMatchScore('Juan Santos', 'DELA CRUZ, JUAN'), 0);
    });

    test('leaves ambiguous names for the teacher', () {
      final m = matchNames(
        {1: 'Maria Santos'},
        ['SANTOS, MARIA CLARA', 'SANTOS, MARIA LUZ'],
      );
      expect(m, isEmpty);
    });

    test('an exact full name wins over a partial one', () {
      final m = matchNames(
        {1: 'Maria Clara Santos'},
        ['SANTOS, MARIA CLARA', 'SANTOS, MARIA'],
      );
      expect(m, {1: 'SANTOS, MARIA CLARA'});
    });
  });
}
