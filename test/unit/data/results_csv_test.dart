import 'package:egrado/export/results_csv.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

void main() {
  List<String> lines(String csv) => csv.substring(1).split('\r\n');

  test('one row per student with score, percent and answers', () {
    final csv = buildResultsCsv(
      schoolClass: testClass,
      exam: testExam(),
      results: [
        testResult(1, [0, 1, 2, 3, 0]),
        testResult(3, [0, null, 2, 0, 0]),
      ],
    );
    expect(csv.startsWith('﻿'), isTrue, reason: 'Excel needs the BOM');
    final rows = lines(csv);
    expect(rows[0], 'No.,Name,Score,Out of,Percent,Q1,Q2,Q3,Q4,Q5');
    expect(rows[1], ',ANSWER KEY,,,,A,B,C,D,A');
    expect(rows[2], '1,"Dela Cruz, Juan",5,5,100%,A,B,C,D,A');
    expect(rows[3], '2,"Santos, María",,5,', reason: 'not checked yet');
    expect(rows[4], '3,"Reyes, Ana",3,5,60%,A,,C,A,A');
  });

  test('includes scanned numbers missing from the class list', () {
    final csv = buildResultsCsv(
      schoolClass: testClass,
      exam: testExam(),
      results: [
        testResult(42, [0, 1, 2, 3, 0]),
      ],
    );
    expect(lines(csv).last, startsWith('42,(not in class list),5,5,100%'));
  });

  test('neutralises names that Excel would run as formulas', () {
    final csv = buildResultsCsv(
      schoolClass: SchoolClass(
        id: 'c1',
        name: 'x',
        students: const [Student(number: 1, name: '=HYPERLINK("x")')],
      ),
      exam: testExam(),
      results: const [],
    );
    expect(lines(csv)[2], startsWith('1,"\'=HYPERLINK(""x"")"'));
  });
}
