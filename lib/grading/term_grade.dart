import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/grading/transmutation.dart';
import 'package:meta/meta.dart';

/// One scored activity in a grading period: a scanned test, or a task the
/// teacher scored by hand.
@immutable
class GradedActivity {
  GradedActivity({
    required this.component,
    required this.highestScore,
    required Map<int, int> scores,
    this.examPart,
  }) : scores = Map.unmodifiable(scores);

  final GradeComponent component;

  /// Only for [GradeComponent.exam].
  final ExamPart? examPart;

  /// The Highest Possible Score (HPS).
  final int highestScore;

  /// Raw score per student number. A student without an entry gets 0, the
  /// same as a blank cell in the E-Class Record.
  final Map<int, int> scores;
}

/// Percentage Score (PS) and Weighted Score (WS) of one component.
@immutable
class ComponentScore {
  const ComponentScore({required this.percentage, required this.weighted});

  final double percentage;
  final double weighted;
}

/// One student's grade for one grading period.
@immutable
class TermGrade {
  TermGrade({
    required this.studentNumber,
    required Map<GradeComponent, ComponentScore> components,
    required List<GradeComponent> missingComponents,
    required this.missedActivities,
    this.initialGrade,
    this.grade,
  }) : components = Map.unmodifiable(components),
       missingComponents = List.unmodifiable(missingComponents);

  final int studentNumber;
  final Map<GradeComponent, ComponentScore> components;

  /// Components that count (weight above 0) but have no activity yet. While
  /// any are missing there is no grade.
  final List<GradeComponent> missingComponents;

  /// Activities this student has no score for (counted as 0).
  final int missedActivities;

  /// Sum of weighted scores; null while components are missing.
  final double? initialGrade;

  /// Transmuted (or zero-based) grade; null while components are missing.
  final int? grade;

  bool get isComplete => grade != null;
}

/// Works out every student's grade for one grading period.
///
/// PS = raw ÷ HPS × 100 per component, WS = PS × weight, IG = ΣWS, then the
/// policy's transmutation. Exams are combined per DO 015 s. 2026 para 45:
/// each exam part gets its own PS, then the parts are weighted (30/30/40).
List<TermGrade> computeTermGrades({
  required GradingPolicy policy,
  required ComponentWeights weights,
  required Iterable<int> studentNumbers,
  required List<GradedActivity> activities,
}) {
  final required = [
    for (final c in GradeComponent.values)
      if (weights.of(c) > 0) c,
  ];
  final missing = [
    for (final c in required)
      if (!activities.any((a) => a.component == c && a.highestScore > 0)) c,
  ];
  return [
    for (final number in studentNumbers)
      _gradeFor(number, policy, weights, activities, missing),
  ];
}

TermGrade _gradeFor(
  int number,
  GradingPolicy policy,
  ComponentWeights weights,
  List<GradedActivity> activities,
  List<GradeComponent> missing,
) {
  final components = <GradeComponent, ComponentScore>{};
  for (final c in GradeComponent.values) {
    final ofComponent = [
      for (final a in activities)
        if (a.component == c && a.highestScore > 0) a,
    ];
    if (ofComponent.isEmpty) continue;
    final ps = c == GradeComponent.exam
        ? _examPercentage(number, policy, ofComponent)
        : _pooledPercentage(number, ofComponent);
    components[c] = ComponentScore(
      percentage: ps,
      weighted: _round2(ps * weights.of(c) / 100),
    );
  }
  final missed = activities
      .where((a) => a.highestScore > 0 && !a.scores.containsKey(number))
      .length;
  if (missing.isNotEmpty) {
    return TermGrade(
      studentNumber: number,
      components: components,
      missingComponents: missing,
      missedActivities: missed,
    );
  }
  final ig = components.values.fold<double>(0, (sum, c) => sum + c.weighted);
  return TermGrade(
    studentNumber: number,
    components: components,
    missingComponents: const [],
    missedActivities: missed,
    initialGrade: ig,
    grade: transmute(ig, policy.transmutation),
  );
}

/// Rounds to 2 decimals, as the official E-Class Records do at every step
/// (PS, then WS): `ROUND(raw/HPS*100, 2)`, `ROUND(PS*weight, 2)`.
double _round2(double value) => toHundredths(value) / 100;

/// Σ raw ÷ Σ HPS × 100, rounded to 2 decimals.
double _pooledPercentage(int number, List<GradedActivity> activities) {
  var raw = 0;
  var highest = 0;
  for (final a in activities) {
    raw += (a.scores[number] ?? 0).clamp(0, a.highestScore);
    highest += a.highestScore;
  }
  return highest == 0 ? 0 : _round2(raw * 100 / highest);
}

/// Each exam part's PS, weighted by the policy (ST1 30, ST2 30, TE 40).
/// Parts not given yet are left out and the rest re-weighted, so a term
/// with only ST1 so far still shows a sensible running exam score.
double _examPercentage(
  int number,
  GradingPolicy policy,
  List<GradedActivity> exams,
) {
  final byPart = <ExamPart, List<GradedActivity>>{};
  for (final e in exams) {
    final part = e.examPart;
    if (part == null || !policy.examParts.containsKey(part)) continue;
    (byPart[part] ??= []).add(e);
  }
  if (byPart.isEmpty) return _pooledPercentage(number, exams);
  var total = 0.0;
  var weightSum = 0;
  for (final MapEntry(key: part, value: list) in byPart.entries) {
    final w = policy.examParts[part] ?? 0;
    total += _round2(_pooledPercentage(number, list) * w / 100);
    weightSum += w;
  }
  if (weightSum == 0) return 0;
  return weightSum == 100 ? _round2(total) : _round2(total * 100 / weightSum);
}

/// Final grade: the average of the period grades, rounded to a whole
/// number (DO 015 s. 2026 para 52). Null until every period has a grade.
int? finalGrade(List<int?> periodGrades) {
  if (periodGrades.isEmpty || periodGrades.any((g) => g == null)) return null;
  final sum = periodGrades.fold<int>(0, (s, g) => s + (g ?? 0));
  return roundGrade(sum / periodGrades.length);
}

/// The report-card descriptor: DO 015 s. 2026 Table 11, or DO 8 s. 2015
/// Table 10 for schools still on it.
String descriptor(int grade, GradingPolicy policy) =>
    policy.transmutation == Transmutation.do8s2015
    ? switch (grade) {
        >= 90 => 'Outstanding',
        >= 85 => 'Very Satisfactory',
        >= 80 => 'Satisfactory',
        >= 75 => 'Fairly Satisfactory',
        _ => 'Did Not Meet Expectations',
      }
    : switch (grade) {
        >= 90 => 'Advancing',
        >= 80 => 'Benchmarking',
        >= 75 => 'Connecting',
        >= 65 => 'Developing',
        _ => 'Emerging',
      };
