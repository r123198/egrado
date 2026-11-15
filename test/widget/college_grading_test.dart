import 'package:egrado/data/database/app_database.dart';
import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/data/repositories/result_repository.dart';
import 'package:egrado/data/repositories/workspace_repository.dart';
import 'package:egrado/domain/teaching_level.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/grading/grading_scheme.dart';
import 'package:egrado/grading/scheme_presets.dart';
import 'package:egrado/ui/exam_form/exam_form_view.dart';
import 'package:egrado/ui/grades/grades_view.dart';
import 'package:egrado/ui/grades/scheme_editor_view.dart';
import 'package:egrado/ui/home/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fixtures.dart';
import '../support/seed.dart';

const _collegeLabel = 'College · Prelim, Midterm, Finals';

Future<void> _useCollege(AppDatabase db) => DriftClassRepository(db).setGrading(
  'c1',
  policyId: do015Sy2026.id,
  subjectGroupId: null,
  customScheme: collegeScheme,
);

/// A class on college grading with one perfect paper in every category.
Future<void> _seedCollegePrelim(AppDatabase db) async {
  await seedSchool(
    db,
    results: [
      testResult(1, [0, 1, 2, 3, 0]),
    ],
  );
  await _useCollege(db);
  final exams = DriftExamRepository(db);
  await exams.updateExam(
    testExam().copyWith(
      gradeTag: () => const GradeTag(period: 1, categoryId: 'quizzes'),
    ),
  );
  for (final category in ['assignments', 'term_exam']) {
    final tag = GradeTag(period: 1, categoryId: category);
    final id = await exams.createExam(
      classId: 'c1',
      title: category,
      questionCount: 5,
      choiceCount: 4,
      gradeTag: tag,
    );
    await exams.updateExam(testExam(id: id).copyWith(gradeTag: () => tag));
    // The exam paper has one wrong answer: 4/5.
    await DriftResultRepository(db).saveResult(
      testResult(1, [0, 1, 2, 3, category == 'term_exam' ? 1 : 0], exam: id),
    );
  }
}

void main() {
  testAppWidgets('a college teacher is offered college rules only', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const GradesPage('c1'),
      seed: (db) async {
        await seedSchool(db);
        await DriftWorkspaceRepository(db).setLevel(TeachingLevel.college);
      },
    );
    await tester.tap(find.text('Choose the grading rules'));
    await tester.pumpAndSettle();
    // No DepEd order or subject to wade through.
    expect(find.text('Subject'), findsNothing);
    expect(find.textContaining('DO 015'), findsNothing);
    expect(find.text(_collegeLabel), findsOneWidget);
    expect(find.text('Quizzes & Activities'), findsOneWidget);
    expect(find.text('66.7%'), findsOneWidget);
    expect(find.text('Change categories and weights'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text(_collegeLabel), findsOneWidget);
    expect(find.text('CS 66.7% · Exam 33.3%'), findsOneWidget);
    expect(find.text('Midterm'), findsOneWidget);
    // The E-Class Record is DepEd's; it isn't offered here.
    expect(find.text('Fill my E-Class Record'), findsNothing);
  });

  testAppWidgets('a DepEd teacher is offered DepEd rules only', (tester) async {
    await pumpPage(tester, const GradesPage('c1'), seed: seedSchool);
    await tester.tap(find.text('Choose the subject'));
    await tester.pumpAndSettle();
    expect(find.text(_collegeLabel), findsNothing);
    await tester.tap(find.byKey(const ValueKey('grading-rules')));
    await tester.pumpAndSettle();
    expect(find.text(_collegeLabel), findsNothing);
    expect(find.text('DO 8 s. 2015 · four quarters'), findsOneWidget);
  });

  testAppWidgets('the first class asks DepEd or college, once', (tester) async {
    final db = await pumpPage(tester, const ClassesPage());
    await tester.tap(find.text('Add a class'));
    await tester.pumpAndSettle();
    expect(find.text('Where do you teach?'), findsOneWidget);
    await tester.tap(find.text('College'));
    await tester.pumpAndSettle();
    expect(find.textContaining('NCM 107'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'NCM 107 – BSN 2G');
    await tester.tap(find.text('Add class'));
    await tester.pumpAndSettle();

    final level = await tester.runAsync(
      () => DriftWorkspaceRepository(db).watchLevel().first,
    );
    expect(level, TeachingLevel.college);
    final classes = await tester.runAsync(
      () => DriftClassRepository(db).watchOverviews().first,
    );
    final created = await tester.runAsync(
      () => DriftClassRepository(db).watchClass(classes!.single.id).first,
    );
    // Graded as college from the start: nothing to set up.
    expect(created?.customScheme?.id, collegeScheme.id);

    // Back on the list, a second class is not asked again.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a class'));
    await tester.pumpAndSettle();
    expect(find.text('Where do you teach?'), findsNothing);
    expect(find.text('New class'), findsOneWidget);
  });

  testAppWidgets('backing out of the question adds nothing', (tester) async {
    final db = await pumpPage(tester, const ClassesPage());
    await tester.tap(find.text('Add a class'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5)); // outside the dialog
    await tester.pumpAndSettle();
    expect(find.text('New class'), findsNothing);
    final level = await tester.runAsync(
      () => DriftWorkspaceRepository(db).watchLevel().first,
    );
    expect(level, isNull);
  });

  testAppWidgets('teachers with classes already are not asked', (tester) async {
    await pumpPage(tester, const ClassesPage(), seed: seedSchool);
    await tester.tap(find.text('Add a class'));
    await tester.pumpAndSettle();
    expect(find.text('Where do you teach?'), findsNothing);
    expect(find.textContaining('Grade 7 – Rizal'), findsWidgets);
  });

  testAppWidgets('shows the college mark first, then the grade', (
    tester,
  ) async {
    await pumpPage(tester, const GradesPage('c1'), seed: _seedCollegePrelim);
    // Class standing 100, exam 4/5 = 80 → ⅔·100 + ⅓·80 = 93.33 → 1.50.
    await tester.scrollUntilVisible(
      find.text('1.50'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('93'), findsOneWidget);
    expect(find.text('CS 100% · Exam 80%'), findsOneWidget);
  });

  testAppWidgets('Midterm waits for its own scores', (tester) async {
    await pumpPage(tester, const GradesPage('c1'), seed: _seedCollegePrelim);
    await tester.tap(find.text('Midterm'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No Class Standing or Exam yet in Midterm'),
      findsOneWidget,
    );
  });

  testAppWidgets('a new test counts under a college category', (tester) async {
    await pumpPage(
      tester,
      const ExamFormPage(classId: 'c1'),
      seed: (db) async {
        await seedSchool(db);
        await _useCollege(db);
      },
      size: const Size(400, 1400),
    );
    expect(find.text('Quizzes & Activities'), findsOneWidget);
    expect(find.text('Written Work'), findsNothing);
    expect(
      find.text('Scores go to Quizzes & Activities in Prelim.'),
      findsOneWidget,
    );
  });

  testWidgets('the editor changes a weight and hands back the scheme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    GradingScheme? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push(
                MaterialPageRoute<GradingScheme>(
                  builder: (_) => SchemeEditorPage(collegeScheme),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('weight-class_standing')),
      '3',
    );
    await tester.pumpAndSettle();
    expect(find.text('= 75%'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('name-term_exam')), '');
    await tester.pumpAndSettle();
    expect(find.text('Every category needs a name.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('name-term_exam')),
      'Major Exam',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result?.categories.first.weight, 3);
    expect(result?.leaf('term_exam')?.label, 'Major Exam');
  });

  // One screen per test: each needs its own database.
  const small = Size(360, 740);

  testAppWidgets('the DepEd-or-college question fits a small phone', (
    tester,
  ) async {
    await pumpPage(tester, const ClassesPage(), size: small, textScale: 1.6);
    await tester.ensureVisible(find.text('Add a class'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a class'));
    await tester.pumpAndSettle();
    expect(find.text('Where do you teach?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testAppWidgets('the subject dropdown fits a small phone', (tester) async {
    await pumpPage(
      tester,
      const GradesPage('c1'),
      seed: seedSchool,
      size: small,
      textScale: 1.6,
    );
    await tester.tap(find.text('Choose the subject'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('subject-do015_2026')),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('subject-do015_2026')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('MAPEH, EPP/TLE').last);
    await tester.pumpAndSettle();
    expect(find.text('WW 20% · PT 60% · Exam 20%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testAppWidgets('the Counts-as dropdown fits a small phone', (tester) async {
    await pumpPage(
      tester,
      const ExamFormPage(classId: 'c1'),
      seed: seedSchool,
      size: small,
      textScale: 1.6,
    );
    final countsAs = find.byWidgetPredicate(
      (w) => switch (w.key) {
        ValueKey<String>(:final value) => value.startsWith('counts-as-'),
        _ => false,
      },
    );
    await tester.scrollUntilVisible(
      countsAs,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(countsAs);
    await tester.pumpAndSettle();
    expect(find.text('Summative Test 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the editor fits a small phone at large text', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child ?? const SizedBox.shrink(),
        ),
        home: SchemeEditorPage(collegeScheme),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
