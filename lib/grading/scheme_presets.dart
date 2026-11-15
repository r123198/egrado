import 'package:egrado/grading/grading_scheme.dart';

/// The 1.00–5.00 scale most Philippine colleges use, three points a step.
const _collegeBands = [
  GradeBand(99, '1.00'),
  GradeBand(96, '1.25'),
  GradeBand(93, '1.50'),
  GradeBand(90, '1.75'),
  GradeBand(87, '2.00'),
  GradeBand(84, '2.25'),
  GradeBand(81, '2.50'),
  GradeBand(78, '2.75'),
  GradeBand(75, '3.00'),
  GradeBand(0, '5.00'),
];

/// College grading: Prelim, Midterm and Finals. A term's own score is
/// ⅔ class standing (70% quizzes and activities, 30% assignments) and
/// ⅓ exam; from Midterm on, the grade is ⅓ the previous term's grade and
/// ⅔ this term's score. Every quiz counts the same whatever its length.
///
/// A starting point: the teacher changes the categories and weights to
/// match the syllabus, and the edited copy is saved with the class.
final collegeScheme = GradingScheme(
  id: 'college_pmf',
  label: 'College · Prelim, Midterm, Finals',
  periodNames: const ['Prelim', 'Midterm', 'Finals'],
  periodShortNames: const ['Prelim', 'Midterm', 'Finals'],
  categories: [
    GradeCategory(
      id: 'class_standing',
      label: 'Class Standing',
      code: 'CS',
      weight: 2,
      children: [
        GradeCategory(
          id: 'quizzes',
          label: 'Quizzes & Activities',
          weight: 70,
          combine: CombineRule.averageOfPercents,
        ),
        GradeCategory(
          id: 'assignments',
          label: 'Assignments',
          weight: 30,
          combine: CombineRule.averageOfPercents,
        ),
      ],
    ),
    GradeCategory(
      id: 'term_exam',
      label: 'Exam',
      weight: 1,
      combine: CombineRule.averageOfPercents,
    ),
  ],
  scale: const GradeScale(
    bands: _collegeBands,
    passingGrade: 75,
    marksFirst: true,
  ),
  previousWeight: 1,
  currentWeight: 2,
);

/// Schemes a teacher can start from besides DepEd's own orders.
final kCustomSchemePresets = [collegeScheme];
