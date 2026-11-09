import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/data/repositories/result_repository.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/exam_result.dart';
import 'package:egrado/domain/overviews.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/omr/omr_reading.dart';
import 'package:egrado/ui/answer_key/answer_key_view.dart';
import 'package:egrado/ui/class_detail/class_view.dart';
import 'package:egrado/ui/exam/exam_view.dart';
import 'package:egrado/ui/home/home_view.dart';
import 'package:egrado/ui/scan/result_review_view.dart';
import 'package:egrado/ui/students/add_students_view.dart';
import 'package:egrado/ui/students/students_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fakes.dart';
import '../support/fixtures.dart';
import '../support/seed.dart';

const _clear = MarkStatus.clear;

/// Reads from the database outside the widget test's fake clock.
Future<T> _query<T>(WidgetTester tester, Future<T> Function() read) async =>
    (await tester.runAsync(read)) as T;

Future<void> _seedWithOnePaper(AppDatabase db) => seedSchool(
  db,
  results: [
    testResult(1, [0, 1, 2, 3, 0]),
  ],
);

void main() {
  testAppWidgets('teacher adds a first class from the empty home screen', (
    tester,
  ) async {
    final db = await pumpPage(tester, const ClassesPage());
    expect(find.text('No classes yet'), findsOneWidget);

    await tester.tap(find.text('Add a class'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Grade 8 – Mabini');
    await tester.tap(find.text('Add class'));
    await tester.pumpAndSettle();

    final List<ClassOverview> classes = await _query(
      tester,
      () => DriftClassRepository(db).watchOverviews().first,
    );
    expect(classes.single.name, 'Grade 8 – Mabini');
    expect(find.byType(ClassPage), findsOneWidget);
    expect(find.text('Add your class list first'), findsOneWidget);
  });

  testAppWidgets('pasting a name list numbers the students in order', (
    tester,
  ) async {
    final db = await pumpPage(
      tester,
      const AddStudentsPage('c1'),
      seed: seedSchool,
    );
    await tester.enterText(
      find.byType(TextField),
      'Lopez, Ben\n\n  Cruz, Lea  \n',
    );
    await tester.pumpAndSettle();
    expect(find.text('Add 2 students'), findsOneWidget);

    await tester.tap(find.text('Add 2 students'));
    await tester.pumpAndSettle();
    final SchoolClass? c = await _query(
      tester,
      () => DriftClassRepository(db).watchClass('c1').first,
    );
    expect(c!.students.map((s) => '${s.number} ${s.name}').skip(3), [
      '4 Lopez, Ben',
      '5 Cruz, Lea',
    ]);
  });

  testAppWidgets('names read from a photo fill the box for checking', (
    tester,
  ) async {
    await pumpPage(tester, const AddStudentsPage('c1'), seed: seedSchool);
    await tester.tap(find.text('Read names from a photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a saved photo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Found 2 names'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Abad, Ben\nCruz, Leo');
    expect(find.text('Add 2 students'), findsOneWidget);
  });

  testAppWidgets('class list shows students and is editable', (tester) async {
    await pumpPage(tester, const StudentsPage('c1'), seed: seedSchool);
    expect(find.text('Santos, María'), findsOneWidget);
    expect(find.text('Reyes, Ana'), findsOneWidget);
  });

  testAppWidgets('a clear scan is saved under the right student with one tap', (
    tester,
  ) async {
    final db = await pumpPage(
      tester,
      ResultReviewPage.scanned(
        'e1',
        reading(
          digits: const [MarkReading(0, _clear), MarkReading(2, _clear)],
          answers: const [
            MarkReading(0, _clear),
            MarkReading(1, _clear),
            MarkReading(3, _clear),
            MarkReading(3, _clear),
            MarkReading.blank(),
          ],
        ),
      ),
      seed: seedSchool,
    );
    expect(find.text('Santos, María'), findsOneWidget);
    expect(find.text('out of 5\n60%'), findsOneWidget);

    await tester.tap(find.text('Save score'));
    await tester.pumpAndSettle();
    final ExamResult? saved = await _query(
      tester,
      () => DriftResultRepository(db).getResult('e1', 2),
    );
    expect(saved!.answers, [0, 1, 3, 3, null]);
  });

  testAppWidgets(
    'unclear number: save waits until the teacher picks a student',
    (tester) async {
      final db = await pumpPage(
        tester,
        ResultReviewPage.scanned(
          'e1',
          reading(
            digits: const [
              MarkReading(null, MarkStatus.multiple),
              MarkReading(3, _clear),
            ],
            answers: [for (var i = 0; i < 5; i++) const MarkReading(0, _clear)],
          ),
        ),
        seed: seedSchool,
      );
      expect(
        find.text('The student number could not be read.'),
        findsOneWidget,
      );
      final save = find.widgetWithText(
        FilledButton,
        'Choose the student first',
      );
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      await tester.tap(find.text('Choose the student'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reyes, Ana'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save score'));
      await tester.pumpAndSettle();

      final ExamResult? saved = await _query(
        tester,
        () => DriftResultRepository(db).getResult('e1', 3),
      );
      expect(saved, isNotNull);
    },
  );

  testAppWidgets(
    'a flagged answer is fixed by tapping, and the score updates',
    (tester) async {
      await pumpPage(
        tester,
        ResultReviewPage.scanned(
          'e1',
          reading(
            digits: const [MarkReading(0, _clear), MarkReading(3, _clear)],
            answers: const [
              MarkReading(0, _clear),
              MarkReading(1, _clear),
              MarkReading(null, MarkStatus.multiple),
              MarkReading(3, _clear),
              MarkReading(0, _clear),
            ],
          ),
        ),
        seed: seedSchool,
      );
      expect(
        find.textContaining('1 answer needs a quick look'),
        findsOneWidget,
      );
      expect(find.text('out of 5\n80%'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(RegExp('^Question 3, answer')));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('Question 3 choice C')));
      await tester.pumpAndSettle();

      expect(find.textContaining('needs a quick look'), findsNothing);
      expect(find.text('out of 5\n100%'), findsOneWidget);
    },
  );

  testAppWidgets('rescanning a checked student warns before replacing', (
    tester,
  ) async {
    await pumpPage(
      tester,
      ResultReviewPage.scanned(
        'e1',
        reading(
          digits: const [MarkReading(0, _clear), MarkReading(1, _clear)],
          answers: [for (var i = 0; i < 5; i++) const MarkReading(0, _clear)],
        ),
      ),
      seed: _seedWithOnePaper,
    );
    expect(find.textContaining('Saving replaces that score'), findsOneWidget);
  });

  testAppWidgets('a saved score still opens after the test is shortened', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const ResultReviewPage.saved('e1', 1),
      seed: (db) async {
        await _seedWithOnePaper(db);
        final repo = DriftExamRepository(db);
        final Exam exam = (await repo.watchExam('e1').first)!;
        await repo.updateExam(exam.copyWith(questionCount: 3));
      },
    );
    expect(tester.takeException(), isNull);
    expect(find.text('out of 3\n100%'), findsOneWidget);
  });

  testAppWidgets('test page lists every student, checked or not', (
    tester,
  ) async {
    await pumpPage(tester, const ExamPage('e1'), seed: _seedWithOnePaper);
    expect(find.text('Reyes, Ana'), findsOneWidget);
    expect(find.text('Dela Cruz, Juan'), findsOneWidget);
    expect(find.text('Not checked'), findsNWidgets(2));
  });

  testAppWidgets('until the key is complete, Scan leads to the key', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const ExamPage('e1'),
      seed: (db) => seedSchool(db, key: [0, null, 2, 3, 0]),
    );
    expect(find.textContaining('tap Key below'), findsOneWidget);
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    expect(find.text('Save answer key'), findsOneWidget);
  });

  testAppWidgets('with a key set, Scan opens the camera session', (
    tester,
  ) async {
    await pumpPage(tester, const ExamPage('e1'), seed: seedSchool);
    expect(find.textContaining('Tap Scan below'), findsOneWidget);
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    // The camera source sheet opens straight away.
    expect(find.text('Take a photo'), findsOneWidget);
  });

  testAppWidgets('answer key is set by tapping letters', (tester) async {
    final db = await pumpPage(
      tester,
      const AnswerKeyPage('e1'),
      seed: (db) => seedSchool(db, key: const []),
    );
    expect(find.text('0 of 5 answers set'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Question 1 choice D'));
    await tester.tap(find.bySemanticsLabel('Question 2 choice B'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 5 answers set'), findsOneWidget);

    await tester.tap(find.text('Save answer key'));
    await tester.pumpAndSettle();
    final Exam? exam = await _query(
      tester,
      () => DriftExamRepository(db).watchExam('e1').first,
    );
    expect(exam!.answerKey, [3, 1, null, null, null]);
  });

  group('large text on a small phone', () {
    final pages = <String, Widget>{
      'home': const ClassesPage(),
      'class': const ClassPage('c1'),
      'students': const StudentsPage('c1'),
      'add students': const AddStudentsPage('c1'),
      'test': const ExamPage('e1'),
      'answer key': const AnswerKeyPage('e1'),
      'saved score': const ResultReviewPage.saved('e1', 1),
    };
    pages.forEach((name, page) {
      testAppWidgets('$name page has no overflow at 1.6× text, 360 px wide', (
        tester,
      ) async {
        await pumpPage(
          tester,
          page,
          seed: _seedWithOnePaper,
          size: const Size(360, 740),
          textScale: 1.6,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });
  });
}
