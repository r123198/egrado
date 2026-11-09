import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/grading/term_grade.dart';
import 'package:egrado/grading/transmutation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('adjusted 2026 transmutation (DO 015 Annex D Table 4)', () {
    // Both edges of a sample of rows, straight from the printed table.
    const rows = <(double, double, int)>[
      (99.50, 100.00, 100),
      (98.32, 99.49, 99),
      (87.70, 88.87, 90),
      (85.34, 86.51, 88),
      (75.90, 77.07, 80),
      (70.00, 71.17, 75),
      (65.34, 69.99, 74),
      (56.01, 60.66, 72),
      (51.34, 56.00, 71),
      (4.68, 9.34, 61),
      (0.00, 4.67, 60),
    ];
    for (final (low, high, grade) in rows) {
      test('$low–$high → $grade', () {
        expect(transmute(low, Transmutation.adjusted2026), grade);
        expect(transmute(high, Transmutation.adjusted2026), grade);
      });
    }

    test('every row from 60 to 100 is reachable and in order', () {
      var last = 59;
      for (var h = 0; h <= 10000; h++) {
        final g = transmute(h / 100, Transmutation.adjusted2026);
        expect(g - last, inInclusiveRange(0, 1), reason: 'at ${h / 100}');
        last = g;
      }
      expect(last, 100);
    });

    test('rounds the IG to 2 decimals before looking it up', () {
      expect(transmute(69.995, Transmutation.adjusted2026), 75);
      expect(transmute(69.994, Transmutation.adjusted2026), 74);
    });
  });

  group('DO 8 s. 2015 transmutation (Appendix B)', () {
    test('matches the printed rows', () {
      expect(transmute(100, Transmutation.do8s2015), 100);
      expect(transmute(99.99, Transmutation.do8s2015), 99);
      expect(transmute(98.40, Transmutation.do8s2015), 99);
      expect(transmute(98.39, Transmutation.do8s2015), 98);
      expect(transmute(61.59, Transmutation.do8s2015), 75);
      expect(transmute(60.00, Transmutation.do8s2015), 75);
      expect(transmute(59.99, Transmutation.do8s2015), 74);
      expect(transmute(56.00, Transmutation.do8s2015), 74);
      expect(transmute(3.99, Transmutation.do8s2015), 60);
    });
  });

  group('zero-based (SY 2027-2028)', () {
    test('rounds the IG, never below 60', () {
      expect(transmute(83.6, Transmutation.zeroBased), 84);
      expect(transmute(74.5, Transmutation.zeroBased), 75);
      expect(transmute(74.49, Transmutation.zeroBased), 74);
      expect(transmute(12, Transmutation.zeroBased), 60);
    });
  });

  group('computeTermGrades', () {
    const core = ComponentWeights(20, 50, 30);

    test('reproduces the DO 015 Annex D Table 5 worked example', () {
      // WW 74/85, PT 43/50, ST1 15/20, ST2 18/20, TE 35/40 → IG 85.8 → 88.
      final grades = computeTermGrades(
        policy: do015Sy2026,
        weights: core,
        studentNumbers: [1],
        activities: [
          GradedActivity(
            component: GradeComponent.writtenWork,
            highestScore: 85,
            scores: {1: 74},
          ),
          GradedActivity(
            component: GradeComponent.performanceTask,
            highestScore: 50,
            scores: {1: 43},
          ),
          GradedActivity(
            component: GradeComponent.exam,
            examPart: ExamPart.summativeTest1,
            highestScore: 20,
            scores: {1: 15},
          ),
          GradedActivity(
            component: GradeComponent.exam,
            examPart: ExamPart.summativeTest2,
            highestScore: 20,
            scores: {1: 18},
          ),
          GradedActivity(
            component: GradeComponent.exam,
            examPart: ExamPart.termExam,
            highestScore: 40,
            scores: {1: 35},
          ),
        ],
      );
      final g = grades.single;
      expect(
        g.components[GradeComponent.exam]!.percentage,
        closeTo(84.5, 1e-9),
      );
      expect(g.initialGrade, closeTo(85.76, 0.01));
      expect(g.grade, 88);
      expect(g.isComplete, isTrue);
    });

    test('pools raw scores within a component (Σraw ÷ ΣHPS)', () {
      final g = computeTermGrades(
        policy: do015Sy2026,
        weights: core,
        studentNumbers: [1],
        activities: [
          GradedActivity(
            component: GradeComponent.writtenWork,
            highestScore: 10,
            scores: {1: 10},
          ),
          GradedActivity(
            component: GradeComponent.writtenWork,
            highestScore: 30,
            scores: {1: 10},
          ),
        ],
      ).single;
      expect(g.components[GradeComponent.writtenWork]!.percentage, 50);
    });

    test('no grade while a weighted component has nothing yet', () {
      final g = computeTermGrades(
        policy: do015Sy2026,
        weights: core,
        studentNumbers: [1],
        activities: [
          GradedActivity(
            component: GradeComponent.writtenWork,
            highestScore: 10,
            scores: {1: 8},
          ),
        ],
      ).single;
      expect(g.grade, isNull);
      expect(g.missingComponents, [
        GradeComponent.performanceTask,
        GradeComponent.exam,
      ]);
    });

    test('a component weighted 0 is not required', () {
      final g = computeTermGrades(
        policy: do015Sy2026,
        weights: const ComponentWeights(40, 60, 0),
        studentNumbers: [1],
        activities: [
          GradedActivity(
            component: GradeComponent.writtenWork,
            highestScore: 10,
            scores: {1: 10},
          ),
          GradedActivity(
            component: GradeComponent.performanceTask,
            highestScore: 10,
            scores: {1: 10},
          ),
        ],
      ).single;
      expect(g.grade, 100);
    });

    test('a student with no score gets 0 and is flagged', () {
      final grades = computeTermGrades(
        policy: do015Sy2026,
        weights: const ComponentWeights(100, 0, 0),
        studentNumbers: [1, 2],
        activities: [
          GradedActivity(
            component: GradeComponent.writtenWork,
            highestScore: 10,
            scores: {1: 10},
          ),
        ],
      );
      expect(grades[1].initialGrade, 0);
      expect(grades[1].grade, 60);
      expect(grades[1].missedActivities, 1);
      expect(grades[0].missedActivities, 0);
    });

    test('exam parts given so far are re-weighted among themselves', () {
      final g = computeTermGrades(
        policy: do015Sy2026,
        weights: const ComponentWeights(0, 0, 100),
        studentNumbers: [1],
        activities: [
          GradedActivity(
            component: GradeComponent.exam,
            examPart: ExamPart.summativeTest1,
            highestScore: 10,
            scores: {1: 5},
          ),
          GradedActivity(
            component: GradeComponent.exam,
            examPart: ExamPart.termExam,
            highestScore: 10,
            scores: {1: 10},
          ),
        ],
      ).single;
      // (50×30 + 100×40) ÷ 70 = 78.571…, rounded to 2 decimals.
      expect(g.initialGrade, closeTo(78.57, 1e-9));
    });

    test('DO 8 pools every exam as one Quarterly Assessment', () {
      final g = computeTermGrades(
        policy: do8s2015,
        weights: const ComponentWeights(0, 0, 100),
        studentNumbers: [1],
        activities: [
          GradedActivity(
            component: GradeComponent.exam,
            examPart: ExamPart.quarterlyAssessment,
            highestScore: 40,
            scores: {1: 30},
          ),
        ],
      ).single;
      expect(g.initialGrade, 75);
      expect(g.grade, transmute(75, Transmutation.do8s2015));
    });

    test('rounds PS and WS to 2 decimals like the class record', () {
      // WW 43/60 → 71.67 → 14.33; PT 42/100 → 21.00; TE 17/45 → 37.78
      // → 11.33. IG 46.66 → 69. Rounding only at the end gives 46.67 → 70.
      final g = computeTermGrades(
        policy: do015Sy2026,
        weights: core,
        studentNumbers: [1],
        activities: [
          GradedActivity(
            component: GradeComponent.writtenWork,
            highestScore: 60,
            scores: {1: 43},
          ),
          GradedActivity(
            component: GradeComponent.performanceTask,
            highestScore: 100,
            scores: {1: 42},
          ),
          GradedActivity(
            component: GradeComponent.exam,
            examPart: ExamPart.termExam,
            highestScore: 45,
            scores: {1: 17},
          ),
        ],
      ).single;
      expect(g.initialGrade, closeTo(46.66, 1e-9));
      expect(g.grade, 69);
    });

    test('scores above the HPS are capped', () {
      final g = computeTermGrades(
        policy: do015Sy2026,
        weights: const ComponentWeights(100, 0, 0),
        studentNumbers: [1],
        activities: [
          GradedActivity(
            component: GradeComponent.writtenWork,
            highestScore: 10,
            scores: {1: 12},
          ),
        ],
      ).single;
      expect(g.initialGrade, 100);
    });
  });

  group('final grade and descriptors', () {
    test('averages the period grades and rounds', () {
      expect(finalGrade([88, 89, 89]), 89);
      expect(finalGrade([75, 76]), 76);
      expect(finalGrade([88, null, 90]), isNull);
    });

    test('uses the right descriptor set per policy', () {
      expect(descriptor(88, do015Sy2026), 'Benchmarking');
      expect(descriptor(74, do015Sy2026), 'Developing');
      expect(descriptor(88, do8s2015), 'Very Satisfactory');
    });
  });

  group('policies', () {
    test('every subject group weight adds up to 100', () {
      for (final p in kGradingPolicies) {
        for (final s in p.subjects) {
          expect(s.weights.isValid, isTrue, reason: '${p.id}/${s.id}');
        }
      }
    });

    test('exam parts add up to 100', () {
      for (final p in kGradingPolicies) {
        expect(p.examParts.values.fold<int>(0, (a, b) => a + b), 100);
      }
    });

    test('unknown policy ids fall back to the current DepEd policy', () {
      expect(policyById('nope'), do015Sy2026);
      expect(policyById(null), do015Sy2026);
    });
  });
}
