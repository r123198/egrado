import 'package:egrado/grading/grading_scheme.dart';
import 'package:egrado/grading/transmutation.dart';
import 'package:meta/meta.dart';

/// One scored activity in a grading period: a scanned test, or a task the
/// teacher scored by hand.
@immutable
class GradedActivity {
  GradedActivity({
    required this.categoryId,
    required this.highestScore,
    required Map<int, int> scores,
  }) : scores = Map.unmodifiable(scores);

  /// The scheme leaf this counts under.
  final String categoryId;

  /// The Highest Possible Score (HPS).
  final int highestScore;

  /// Raw score per student number. A student without an entry gets 0, the
  /// same as a blank cell in a class record.
  final Map<int, int> scores;
}

/// Percentage Score (PS) and Weighted Score (WS) of one top-level category.
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
    required Map<String, ComponentScore> components,
    required List<GradeCategory> missingComponents,
    required this.missedActivities,
    this.needsPreviousPeriod = false,
    this.periodScore,
    this.initialGrade,
    this.grade,
  }) : components = Map.unmodifiable(components),
       missingComponents = List.unmodifiable(missingComponents);

  final int studentNumber;

  /// Top-level category id → its score so far. A category with nothing
  /// scored yet has no entry.
  final Map<String, ComponentScore> components;

  /// Categories that count (weight above 0) but have no activity yet.
  /// While any are missing there is no grade.
  final List<GradeCategory> missingComponents;

  /// True when this period builds on the previous one and that one has no
  /// grade yet.
  final bool needsPreviousPeriod;

  /// Activities this student has no score for (counted as 0).
  final int missedActivities;

  /// This period on its own, before the previous period is carried in;
  /// null while categories are missing.
  final double? periodScore;

  /// The 0–100 grade before the scale: [periodScore], blended with the
  /// previous period when the scheme carries it. Null until complete.
  final double? initialGrade;

  /// The reported whole-number grade; null until complete.
  final int? grade;

  bool get isComplete => grade != null;
}

/// Works out every student's grade for [period] (1-based).
///
/// Each leaf category turns its activities into a percentage (pooled, or
/// the average of each activity's percentage). Groups weight their
/// children; the top level's weighted scores add up to the period score.
/// A scheme that carries the previous period blends it in from period 2
/// on, then the scale gives the reported grade.
List<TermGrade> computePeriodGrades({
  required GradingScheme scheme,
  required int period,
  required Iterable<int> studentNumbers,
  required Map<int, List<GradedActivity>> activitiesByPeriod,
}) {
  final numbers = studentNumbers.toList();
  var previous = <int, double?>{};
  var grades = <TermGrade>[];
  // A carried grade needs every earlier period worked out first.
  for (var p = scheme.carriesPrevious ? 1 : period; p <= period; p++) {
    final run = _PeriodRun(
      scheme,
      activitiesByPeriod[p] ?? const [],
      carries: scheme.carriesPrevious && p > 1,
    );
    grades = [for (final n in numbers) run.gradeFor(n, previous[n])];
    previous = {for (final g in grades) g.studentNumber: g.initialGrade};
  }
  return grades;
}

/// One period's activities sorted under the scheme's leaves, and the
/// grade maths over them.
class _PeriodRun {
  _PeriodRun(
    this.scheme,
    List<GradedActivity> activities, {
    required this.carries,
  }) {
    final leafIds = {for (final l in scheme.leaves) l.id};
    for (final a in activities) {
      if (a.highestScore > 0 && leafIds.contains(a.categoryId)) {
        (_byLeaf[a.categoryId] ??= []).add(a);
      }
    }
    _missing = _missingIn(scheme.categories, reweights: false);
  }

  final GradingScheme scheme;

  /// Whether the previous period's grade is blended in.
  final bool carries;
  final _byLeaf = <String, List<GradedActivity>>{};
  late final List<GradeCategory> _missing;

  TermGrade gradeFor(int number, double? previousGrade) {
    final total = _totalWeight(scheme.categories);
    final components = <String, ComponentScore>{};
    for (final c in scheme.categories) {
      final ps = _percentage(c, number);
      if (ps == null) continue;
      components[c.id] = ComponentScore(
        percentage: ps,
        weighted: total == 0 ? 0 : _round(ps * c.weight / total),
      );
    }
    final missed = _byLeaf.values
        .expand((list) => list)
        .where((a) => !a.scores.containsKey(number))
        .length;
    final score = _missing.isEmpty
        ? components.values.fold<double>(0, (sum, c) => sum + c.weighted)
        : null;
    final needsPrevious = carries && previousGrade == null;
    final ig = score == null || needsPrevious
        ? null
        : _blend(previousGrade, score);
    return TermGrade(
      studentNumber: number,
      components: components,
      missingComponents: _missing,
      missedActivities: missed,
      needsPreviousPeriod: needsPrevious,
      periodScore: score,
      initialGrade: ig,
      grade: ig == null ? null : scheme.scale.grade(ig),
    );
  }

  double _blend(double? previousGrade, double score) {
    if (!carries || previousGrade == null) return score;
    final total = scheme.previousWeight + scheme.currentWeight;
    return _round(
      (previousGrade * scheme.previousWeight + score * scheme.currentWeight) /
          total,
    );
  }

  /// Weighted categories with nothing scored. Inside a group that
  /// re-weights, a missing child doesn't hold the grade back.
  List<GradeCategory> _missingIn(
    List<GradeCategory> siblings, {
    required bool reweights,
  }) {
    final missing = <GradeCategory>[];
    for (final c in siblings) {
      if (c.weight <= 0) continue;
      final hasScores = c.leaves.any((l) => _byLeaf.containsKey(l.id));
      if (!hasScores) {
        if (!reweights) missing.add(c);
      } else if (!c.isLeaf) {
        missing.addAll(_missingIn(c.children, reweights: c.reweightsMissing));
      }
    }
    return missing;
  }

  /// The category's percentage so far, or null with nothing scored.
  double? _percentage(GradeCategory c, int number) {
    if (!c.isLeaf) return _weighted(c.children, number);
    final activities = _byLeaf[c.id];
    if (activities == null) return null;
    return switch (c.combine) {
      CombineRule.pooled => _pooled(number, activities),
      CombineRule.averageOfPercents => _average(number, activities),
    };
  }

  /// Children's percentages by weight. Children with nothing scored are
  /// left out and the rest re-weighted, so there is always a running
  /// score (whether it is final is [_missing]'s call).
  double? _weighted(List<GradeCategory> children, int number) {
    final all = _totalWeight(children);
    var total = 0.0;
    var present = 0.0;
    for (final child in children) {
      final ps = _percentage(child, number);
      if (ps == null) continue;
      total += _round(ps * child.weight / all);
      present += child.weight;
    }
    if (present <= 0) return null;
    return present == all ? _round(total) : _round(total * all / present);
  }

  /// Σ raw ÷ Σ HPS × 100.
  double _pooled(int number, List<GradedActivity> activities) {
    var raw = 0;
    var highest = 0;
    for (final a in activities) {
      raw += _score(a, number);
      highest += a.highestScore;
    }
    return _round(raw * 100 / highest);
  }

  /// The average of each activity's raw ÷ HPS × 100.
  double _average(int number, List<GradedActivity> activities) {
    var sum = 0.0;
    for (final a in activities) {
      sum += _round(_score(a, number) * 100 / a.highestScore);
    }
    return _round(sum / activities.length);
  }

  int _score(GradedActivity a, int number) =>
      (a.scores[number] ?? 0).clamp(0, a.highestScore);

  /// To 2 decimals at every step when the scheme asks for it, as the
  /// official E-Class Records do: `ROUND(raw/HPS*100, 2)`,
  /// `ROUND(PS*weight, 2)`.
  double _round(double value) =>
      scheme.roundsSteps ? toHundredths(value) / 100 : value;

  static double _totalWeight(List<GradeCategory> categories) =>
      categories.fold<double>(0, (sum, c) => sum + c.weight);
}

/// Final grade: the average of the period grades, rounded to a whole
/// number (DO 015 s. 2026 para 52). Null until every period has a grade.
int? finalGrade(List<int?> periodGrades) {
  if (periodGrades.isEmpty || periodGrades.any((g) => g == null)) return null;
  final sum = periodGrades.fold<int>(0, (s, g) => s + (g ?? 0));
  return roundGrade(sum / periodGrades.length);
}
