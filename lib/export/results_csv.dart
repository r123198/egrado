import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/exam_result.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/omr/sheet_layout.dart';

/// Byte-order mark so Excel opens names with ñ, é, etc. correctly.
const _utf8Bom = '﻿';

/// Builds a spreadsheet of an exam's results that opens directly in Excel
/// or Google Sheets. Every student in the class gets a row; students
/// without a scanned paper have an empty score.
String buildResultsCsv({
  required SchoolClass schoolClass,
  required Exam exam,
  required List<ExamResult> results,
}) {
  final total = gradableQuestions(exam);
  final byNumber = {for (final r in results) r.studentNumber: r};
  final numbers = {
    ...schoolClass.students.map((s) => s.number),
    ...byNumber.keys,
  }.toList()..sort();

  String letter(int? choice) => choice == null ? '' : kChoiceLetters[choice];

  final rows = <List<String>>[
    [
      'No.',
      'Name',
      'Score',
      'Out of',
      'Percent',
      for (var q = 1; q <= exam.questionCount; q++) 'Q$q',
    ],
    ['', 'ANSWER KEY', '', '', '', for (final c in exam.answerKey) letter(c)],
    for (final number in numbers)
      _studentRow(
        number: number,
        name:
            schoolClass.studentByNumber(number)?.name ?? '(not in class list)',
        exam: exam,
        result: byNumber[number],
        total: total,
        letter: letter,
      ),
  ];
  return _utf8Bom + rows.map((r) => r.map(_escape).join(',')).join('\r\n');
}

List<String> _studentRow({
  required int number,
  required String name,
  required Exam exam,
  required ExamResult? result,
  required int total,
  required String Function(int?) letter,
}) {
  if (result == null) return ['$number', name, '', '$total', ''];
  final score = scoreAnswers(exam, result.answers);
  final percent = total == 0 ? 0 : (score * 100 / total).round();
  return [
    '$number',
    name,
    '$score',
    '$total',
    '$percent%',
    for (var q = 0; q < exam.questionCount; q++)
      letter(q < result.answers.length ? result.answers[q] : null),
  ];
}

String _escape(String field) {
  // Leading = + - @ would run as a formula in Excel.
  final safe = RegExp(r'^[=+\-@]').hasMatch(field) ? "'$field" : field;
  if (!safe.contains(RegExp(r'[",\r\n]'))) return safe;
  return '"${safe.replaceAll('"', '""')}"';
}
