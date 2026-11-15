import 'dart:convert';

import 'package:egrado/domain/exam.dart';
import 'package:egrado/domain/grade_book.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/grading/grading_scheme.dart';
import 'package:egrado/grading/scheme_presets.dart';
import 'package:egrado/grading/term_grade.dart';
import 'package:egrado/ui/grades/scheme_editor_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

GradedActivity _activity(String category, int score, int outOf) =>
    GradedActivity(
      categoryId: category,
      highestScore: outOf,
      scores: {1: score},
    );

/// Prelim of the first student in a real college class record: seven
/// quizzes and activities plus attitude, three assignments, one exam.
List<GradedActivity> _prelim({required int attitude}) => [
  _activity('quizzes', attitude, 100),
  _activity('quizzes', 20, 25),
  _activity('quizzes', 22, 25),
  _activity('quizzes', 17, 30),
  _activity('quizzes', 35, 50),
  _activity('quizzes', 75, 100),
  _activity('quizzes', 45, 50),
  _activity('quizzes', 20, 20),
  _activity('assignments', 95, 100),
  _activity('assignments', 95, 100),
  _activity('assignments', 95, 100),
  _activity('term_exam', 68, 100),
];

TermGrade _college(int period, Map<int, List<GradedActivity>> activities) =>
    computePeriodGrades(
      scheme: collegeScheme,
      period: period,
      studentNumbers: [1],
      activitiesByPeriod: activities,
    ).single;

void main() {
  group('college scheme', () {
    test('matches the class record cell for cell', () {
      // The workbook's own Prelim grade for this student is 74.3722…
      // (its attitude column counts as 1 out of 100).
      final g = _college(1, {1: _prelim(attitude: 1)});
      expect(g.initialGrade, closeTo(74.37222222, 1e-6));
      expect(
        g.components['class_standing']!.percentage,
        closeTo(77.5583, 1e-4),
      );
      expect(g.components['term_exam']!.percentage, 68);
      expect(g.grade, 74);
      expect(collegeScheme.scale.mark(74), '5.00');
      expect(collegeScheme.scale.passes(74), isFalse);
    });

    test('averages each activity, whatever its length', () {
      // Pooled, 17/30 and 20/20 would be 74%; averaged they are 78.33%.
      final g = _college(1, {
        1: [_activity('quizzes', 17, 30), _activity('quizzes', 20, 20)],
      });
      expect(
        g.components['class_standing']!.percentage,
        closeTo(78.3333, 1e-4),
      );
    });

    test('⅔ class standing + ⅓ exam, then the 1.00–5.00 scale', () {
      final g = _college(1, {1: _prelim(attitude: 100)});
      expect(g.initialGrade, closeTo(80.14722222, 1e-6));
      expect(g.grade, 80);
      expect(collegeScheme.scale.mark(80), '2.75');
      expect(collegeScheme.scale.passes(80), isTrue);
    });

    test('Midterm is ⅓ the Prelim grade + ⅔ its own score', () {
      final g = _college(2, {
        1: _prelim(attitude: 1),
        2: [
          _activity('quizzes', 90, 100),
          _activity('assignments', 100, 100),
          _activity('term_exam', 91, 100),
        ],
      });
      expect(g.periodScore, closeTo(92.33333333, 1e-6));
      expect(g.initialGrade, closeTo(86.3462963, 1e-6));
      expect(collegeScheme.scale.mark(g.grade!), '2.25');
    });

    test('no Midterm grade while Prelim is incomplete', () {
      final g = _college(2, {
        1: [_activity('quizzes', 20, 25)],
        2: [
          _activity('quizzes', 90, 100),
          _activity('assignments', 100, 100),
          _activity('term_exam', 91, 100),
        ],
      });
      expect(g.needsPreviousPeriod, isTrue);
      expect(g.missingComponents, isEmpty);
      expect(g.periodScore, isNotNull);
      expect(g.grade, isNull);
    });

    test('says which categories still have nothing', () {
      final g = _college(1, {
        1: [_activity('quizzes', 20, 25)],
      });
      expect(g.missingComponents.map((c) => c.label), ['Assignments', 'Exam']);
      // A running score is still shown for what is in.
      expect(g.components['class_standing']!.percentage, 80);
      expect(g.grade, isNull);
    });

    test('every mark on the scale is reachable', () {
      final marks = {
        for (var g = 60; g <= 100; g++) collegeScheme.scale.mark(g),
      };
      expect(marks, hasLength(10));
      expect(collegeScheme.scale.mark(99), '1.00');
      expect(collegeScheme.scale.mark(98), '1.25');
      expect(collegeScheme.scale.mark(75), '3.00');
    });
  });

  group('saving a scheme', () {
    test('survives a round trip through JSON', () {
      final json = jsonDecode(jsonEncode(collegeScheme.toJson()));
      final back = GradingScheme.fromJson(json)!;
      expect(back.id, collegeScheme.id);
      expect(back.periodNames, collegeScheme.periodNames);
      expect(back.previousWeight, 1);
      expect(back.currentWeight, 2);
      expect(back.scale.marksFirst, isTrue);
      expect(back.leaf('quizzes')?.combine, CombineRule.averageOfPercents);
      // Same grades either way.
      final a = _college(1, {1: _prelim(attitude: 100)});
      final b = computePeriodGrades(
        scheme: back,
        period: 1,
        studentNumbers: [1],
        activitiesByPeriod: {1: _prelim(attitude: 100)},
      ).single;
      expect(b.initialGrade, a.initialGrade);
    });

    test('rejects anything that is not a usable scheme', () {
      final good = collegeScheme.toJson();
      expect(GradingScheme.fromJson(null), isNull);
      expect(GradingScheme.fromJson('scheme'), isNull);
      expect(
        GradingScheme.fromJson({...good, 'categories': <Object>[]}),
        isNull,
      );
      expect(
        GradingScheme.fromJson({...good, 'periodNames': <String>[]}),
        isNull,
      );
      expect(GradingScheme.fromJson({...good, 'currentWeight': 0}), isNull);
      expect(GradingScheme.fromJson({...good, 'scale': null}), isNull);
      expect(
        GradingScheme.fromJson({
          ...good,
          'categories': [
            {'id': 'a', 'label': 'A', 'weight': -1},
          ],
        }),
        isNull,
      );
    });

    test('a saved scheme never claims to be DepEd', () {
      final scheme = depEdScheme(
        do015Sy2026,
        const ComponentWeights(20, 50, 30),
      );
      expect(scheme.isDepEd, isTrue);
      expect(GradingScheme.fromJson(scheme.toJson())?.isDepEd, isFalse);
    });
  });

  group('DepEd as a scheme', () {
    test('category ids are the names tests were saved under', () {
      expect(DepEdCategory.writtenWork, GradeComponent.writtenWork.name);
      expect(
        DepEdCategory.performanceTask,
        GradeComponent.performanceTask.name,
      );
      expect(DepEdCategory.exam, GradeComponent.exam.name);
      expect(DepEdCategory.examIds, {
        DepEdCategory.exam,
        for (final part in ExamPart.values) part.name,
      });
      expect(depEdSlot(DepEdCategory.termExam), (
        GradeComponent.exam,
        ExamPart.termExam,
      ));
      expect(depEdSlot(DepEdCategory.writtenWork), (
        GradeComponent.writtenWork,
        null,
      ));
      expect(depEdSlot('quizzes'), isNull);
    });

    test('names its periods and weights', () {
      final scheme = depEdScheme(do8s2015, const ComponentWeights(40, 40, 20));
      expect(scheme.periodNames.last, 'Quarter 4');
      expect(scheme.periodShortNames, ['Q1', 'Q2', 'Q3', 'Q4']);
      expect(scheme.weightSummary, 'WW 40% · PT 40% · Exam 20%');
      expect(scheme.leaves.map((l) => l.id), [
        DepEdCategory.writtenWork,
        DepEdCategory.performanceTask,
        DepEdCategory.quarterlyAssessment,
      ]);
    });
  });

  group('effectiveTag', () {
    final do015 = depEdScheme(do015Sy2026, const ComponentWeights(20, 50, 30));
    final do8 = depEdScheme(do8s2015, const ComponentWeights(40, 40, 20));
    GradeTag tag(String id) => GradeTag(period: 1, categoryId: id);

    test('DepEd exams carry over between DepEd orders', () {
      expect(
        effectiveTag(tag(DepEdCategory.quarterlyAssessment), do015)?.categoryId,
        DepEdCategory.termExam,
      );
      expect(
        effectiveTag(tag(DepEdCategory.summativeTest1), do8)?.categoryId,
        DepEdCategory.quarterlyAssessment,
      );
      expect(
        effectiveTag(tag(DepEdCategory.exam), do015)?.categoryId,
        DepEdCategory.termExam,
      );
    });

    test('a category the scheme lacks does not count', () {
      expect(
        effectiveTag(tag(DepEdCategory.writtenWork), collegeScheme),
        isNull,
      );
      expect(effectiveTag(tag(DepEdCategory.termExam), collegeScheme), isNull);
      expect(effectiveTag(tag('quizzes'), do015), isNull);
      expect(
        effectiveTag(tag('quizzes'), collegeScheme)?.categoryId,
        'quizzes',
      );
    });
  });

  group('SchemeEditorViewModel', () {
    test('changes weights and shows the shares', () {
      final vm = SchemeEditorViewModel(collegeScheme)
        ..setWeight('class_standing', '60')
        ..setWeight('term_exam', '40');
      final [standing, exam] = vm.scheme.categories;
      expect(vm.shareOf(standing, vm.scheme.categories), '60%');
      expect(vm.shareOf(exam, vm.scheme.categories), '40%');
      expect(vm.shareOf(standing.children.first, standing.children), '70%');
      expect(vm.problem, isNull);
    });

    test('adds, renames and removes categories without reusing ids', () {
      final vm = SchemeEditorViewModel(collegeScheme)
        ..add()
        ..add(parentId: 'class_standing');
      final ids = vm.scheme.leaves.map((l) => l.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(vm.scheme.categories.first.children, hasLength(3));

      final added = vm.scheme.categories.last.id;
      vm.rename(added, 'Recitation');
      expect(vm.scheme.leaf(added)?.label, 'Recitation');
      vm.remove(added);
      expect(vm.scheme.leaf(added), isNull);
      vm.remove('quizzes');
      expect(vm.scheme.leaf('quizzes'), isNull);
      // The scheme it started from is untouched.
      expect(collegeScheme.leaf('quizzes'), isNotNull);
    });

    test('explains what is wrong instead of saving it', () {
      final vm = SchemeEditorViewModel(collegeScheme)
        ..setWeight('class_standing', 'abc')
        ..setWeight('term_exam', '');
      expect(vm.problem, contains('weight above 0'));
      vm
        ..setWeight('term_exam', '1')
        ..rename('term_exam', '  ');
      expect(vm.problem, contains('needs a name'));
    });

    test('turning carry-over off and on keeps the ratio', () {
      final vm = SchemeEditorViewModel(collegeScheme);
      expect(vm.previousShare, '33.3%');
      vm.setCarriesPrevious(false);
      expect(vm.scheme.carriesPrevious, isFalse);
      vm.setCarriesPrevious(true);
      expect(vm.scheme.previousWeight, 1);
      vm.setCurrentWeight('1');
      expect(vm.currentShare, '50%');
    });

    test('weights are kept in range and accept a comma', () {
      expect(SchemeEditorViewModel.parseWeight('33,5'), 33.5);
      expect(SchemeEditorViewModel.parseWeight('-4'), 0);
      expect(SchemeEditorViewModel.parseWeight('999999'), 1000);
    });
  });
}
