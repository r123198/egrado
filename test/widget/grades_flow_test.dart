import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/ui/class_detail/class_view.dart';
import 'package:egrado/ui/exam_form/exam_form_view.dart';
import 'package:egrado/ui/grades/fill_record_view.dart';
import 'package:egrado/ui/grades/grades_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fixtures.dart';
import '../support/seed.dart';

Future<T> _query<T>(WidgetTester tester, Future<T> Function() read) async =>
    (await tester.runAsync(read)) as T;

void main() {
  testAppWidgets('the class screen leads to Grades', (tester) async {
    await pumpPage(tester, const ClassPage('c1'), seed: seedSchool);
    await tester.tap(find.text('Grades'));
    await tester.pumpAndSettle();
    expect(find.byType(GradesPage), findsOneWidget);
    expect(find.text('Choose the subject'), findsOneWidget);
  });

  testAppWidgets('teacher picks the subject, and the weights show', (
    tester,
  ) async {
    await pumpPage(tester, const GradesPage('c1'), seed: seedSchool);
    await tester.tap(find.text('Choose the subject'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('subject-do015_2026')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MAPEH, EPP/TLE').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('MAPEH, EPP/TLE'), findsOneWidget);
    expect(find.textContaining('WW 20% · PT 60% · Exam 20%'), findsOneWidget);
  });

  testAppWidgets('untagged tests are pointed out on the Grades screen', (
    tester,
  ) async {
    await pumpPage(tester, const GradesPage('c1'), seed: seedSchool);
    expect(
      find.textContaining("1 test doesn't count toward grades yet"),
      findsOneWidget,
    );
  });

  testAppWidgets('fill screen lists the tests it will write', (tester) async {
    await pumpPage(
      tester,
      const FillRecordPage('c1'),
      seed: (db) async {
        await seedSchool(
          db,
          results: [
            testResult(1, [0, 1, 2, 3, 0]),
          ],
        );
        await DriftExamRepository(db).updateExam(
          testExam().copyWith(
            gradeTag: () => const GradeTag(
              period: 1,
              categoryId: DepEdCategory.writtenWork,
            ),
          ),
        );
      },
    );
    expect(find.text('Choose my class record'), findsOneWidget);
    expect(find.text('Science Quiz'), findsOneWidget);
    expect(find.text('WW · Term 1'), findsOneWidget);
  });

  testAppWidgets('with nothing counted, the fill screen says what to do', (
    tester,
  ) async {
    await pumpPage(tester, const FillRecordPage('c1'), seed: seedSchool);
    expect(find.text('Nothing to fill yet'), findsOneWidget);
    expect(find.text('Choose my class record'), findsNothing);
  });

  testAppWidgets('a new test can be set to count as the Term Exam', (
    tester,
  ) async {
    final db = await pumpPage(
      tester,
      const ExamFormPage(classId: 'c1'),
      seed: seedSchool,
      // Tall enough that the chips aren't under the bottom button bar.
      size: const Size(400, 1400),
    );
    await tester.enterText(find.byType(TextFormField), 'Science TE');
    Future<void> pick(String fieldKeyStart, String option) async {
      final field = find.byWidgetPredicate(
        (w) => switch (w.key) {
          ValueKey<String>(:final value) => value.startsWith(fieldKeyStart),
          _ => false,
        },
      );
      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }

    await pick('counts-as-', 'Term Exam');
    await pick('counts-in-', 'Term 2');
    expect(
      find.text('Scores go to Term Exam in Term 2 of your class record.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Next: answer key'));
    await tester.pumpAndSettle();

    final all = await _query(
      tester,
      () => DriftExamRepository(db).watchOverviews('c1').first,
    );
    final created = all.firstWhere((o) => o.exam.title == 'Science TE');
    expect(
      created.exam.gradeTag,
      const GradeTag(period: 2, categoryId: DepEdCategory.termExam),
    );
  });

  testAppWidgets('grades screen fits a small phone at large text', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const GradesPage('c1'),
      seed: seedSchool,
      size: const Size(360, 740),
      textScale: 1.6,
    );
    expect(tester.takeException(), isNull);
    await pumpPage(
      tester,
      const FillRecordPage('c1'),
      seed: seedSchool,
      size: const Size(360, 740),
      textScale: 1.6,
    );
    expect(tester.takeException(), isNull);
    await pumpPage(
      tester,
      const ExamFormPage(classId: 'c1'),
      seed: seedSchool,
      size: const Size(360, 740),
      textScale: 1.6,
    );
    expect(tester.takeException(), isNull);
  });
}
