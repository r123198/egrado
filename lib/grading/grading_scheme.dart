import 'package:egrado/grading/transmutation.dart';
import 'package:meta/meta.dart';

/// How the scores inside one category become its percentage.
enum CombineRule {
  /// Σ raw ÷ Σ highest possible × 100 (DepEd: a 50-item test outweighs a
  /// 10-item quiz).
  pooled('Total score ÷ total items'),

  /// The average of each activity's own percentage (every quiz counts the
  /// same, whatever its length).
  averageOfPercents('Average of each activity');

  const CombineRule(this.label);

  final String label;
}

/// One part of a grade: a leaf that tests are counted under ("Quizzes"),
/// or a group of smaller parts ("Class standing" = Quizzes + Assignments).
@immutable
class GradeCategory {
  GradeCategory({
    required this.id,
    required this.label,
    required this.weight,
    this.code,
    this.combine = CombineRule.pooled,
    this.reweightsMissing = false,
    List<GradeCategory> children = const [],
  }) : children = List.unmodifiable(children);

  /// Saved with every test counted here. Never change an existing one.
  final String id;
  final String label;

  /// Short name for tight spaces ("WW"); the label when null.
  final String? code;

  /// Share among its siblings: 70 and 30, or 2 and 1 for ⅔ and ⅓. Only the
  /// ratio matters.
  final double weight;

  /// How a leaf's activities combine. Unused on a group.
  final CombineRule combine;

  /// For a group: when a child has no scores yet, spread its weight over
  /// the others instead of holding the grade back (DepEd's ST1/ST2/TE).
  final bool reweightsMissing;

  /// Empty for a leaf.
  final List<GradeCategory> children;

  bool get isLeaf => children.isEmpty;
  String get shortLabel => code ?? label;

  /// This category's leaves (itself when it is one), in order.
  Iterable<GradeCategory> get leaves =>
      isLeaf ? [this] : children.expand((c) => c.leaves);

  GradeCategory copyWith({
    String? label,
    double? weight,
    CombineRule? combine,
    List<GradeCategory>? children,
  }) => GradeCategory(
    id: id,
    label: label ?? this.label,
    weight: weight ?? this.weight,
    code: label == null ? code : null,
    combine: combine ?? this.combine,
    reweightsMissing: reweightsMissing,
    children: children ?? this.children,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'weight': weight,
    if (code != null) 'code': code,
    'combine': combine.name,
    if (reweightsMissing) 'reweightsMissing': true,
    if (children.isNotEmpty) 'children': [for (final c in children) c.toJson()],
  };

  static GradeCategory? _fromJson(Object? json, int depth) {
    if (json is! Map || depth > _maxDepth) return null;
    final id = json['id'];
    final label = json['label'];
    final weight = json['weight'];
    if (id is! String || id.isEmpty || label is! String) return null;
    if (weight is! num || !weight.isFinite || weight < 0) return null;
    final children = <GradeCategory>[];
    final rawChildren = json['children'];
    if (rawChildren is List) {
      for (final raw in rawChildren) {
        final child = _fromJson(raw, depth + 1);
        if (child == null) return null;
        children.add(child);
      }
    }
    final code = json['code'];
    return GradeCategory(
      id: id,
      label: label,
      weight: weight.toDouble(),
      code: code is String ? code : null,
      combine:
          CombineRule.values.asNameMap()[json['combine']] ?? CombineRule.pooled,
      reweightsMissing: json['reweightsMissing'] == true,
      children: children,
    );
  }

  static const _maxDepth = 4;
}

/// The lowest grade that earns [mark]: 84 → "2.25", 90 → "Advancing".
@immutable
class GradeBand {
  const GradeBand(this.minGrade, this.mark);

  final int minGrade;
  final String mark;
}

/// How a percentage becomes what goes on the report.
@immutable
class GradeScale {
  const GradeScale({
    required this.bands,
    required this.passingGrade,
    this.transmutation,
    this.marksFirst = false,
  });

  /// Highest first. A grade gets the first band it reaches.
  final List<GradeBand> bands;
  final int passingGrade;

  /// A DepEd table; null means the percentage is just rounded.
  final Transmutation? transmutation;

  /// True when the mark is the grade teachers report (2.25) and the
  /// number behind it (84) is the detail. False for DepEd (88, Benchmarking).
  final bool marksFirst;

  /// The whole-number grade for a 0–100 [percentage].
  int grade(double percentage) => switch (transmutation) {
    final t? => transmute(percentage, t),
    null => roundGrade(toHundredths(percentage.clamp(0, 100).toDouble()) / 100),
  };

  /// The band [grade] falls in, or '' when the scale has none for it.
  String mark(int grade) {
    for (final b in bands) {
      if (grade >= b.minGrade) return b.mark;
    }
    return '';
  }

  bool passes(int grade) => grade >= passingGrade;

  Map<String, Object?> toJson() => {
    'passingGrade': passingGrade,
    if (transmutation case final t?) 'transmutation': t.name,
    if (marksFirst) 'marksFirst': true,
    'bands': [
      for (final b in bands) {'min': b.minGrade, 'mark': b.mark},
    ],
  };

  static GradeScale? _fromJson(Object? json) {
    if (json is! Map) return null;
    final passing = json['passingGrade'];
    final rawBands = json['bands'];
    if (passing is! int || rawBands is! List) return null;
    final bands = <GradeBand>[];
    for (final raw in rawBands) {
      if (raw is! Map) return null;
      final min = raw['min'];
      final mark = raw['mark'];
      if (min is! int || mark is! String) return null;
      bands.add(GradeBand(min, mark));
    }
    bands.sort((a, b) => b.minGrade.compareTo(a.minGrade));
    return GradeScale(
      bands: List.unmodifiable(bands),
      passingGrade: passing,
      transmutation: Transmutation.values.asNameMap()[json['transmutation']],
      marksFirst: json['marksFirst'] == true,
    );
  }
}

/// A complete set of grading rules, as data: the grading periods, the
/// categories and their weights, how periods build on each other, and the
/// scale. DepEd's orders and a college's Prelim/Midterm/Finals are both
/// just one of these.
@immutable
class GradingScheme {
  GradingScheme({
    required this.id,
    required this.label,
    required List<String> periodNames,
    required List<String> periodShortNames,
    required List<GradeCategory> categories,
    required this.scale,
    this.previousWeight = 0,
    this.currentWeight = 1,
    this.roundsSteps = false,
    this.isDepEd = false,
  }) : assert(periodNames.isNotEmpty),
       assert(periodNames.length == periodShortNames.length),
       periodNames = List.unmodifiable(periodNames),
       periodShortNames = List.unmodifiable(periodShortNames),
       categories = List.unmodifiable(categories);

  /// The preset this came from. Never change an existing one.
  final String id;
  final String label;

  /// "Term 1", "Term 2", … or "Prelim", "Midterm", "Finals".
  final List<String> periodNames;

  /// For the period switcher: "T1", "T2", … or the names themselves.
  final List<String> periodShortNames;

  /// The top-level parts of a period's grade.
  final List<GradeCategory> categories;
  final GradeScale scale;

  /// From the second period on, the grade is the previous period's grade
  /// and this period's own score in this ratio (1 : 2 for ⅓ + ⅔).
  /// [previousWeight] 0 means every period stands alone.
  final double previousWeight;
  final double currentWeight;

  /// Round to 2 decimals at every step, the way DepEd's E-Class Records
  /// do. Off, numbers stay exact until the final grade.
  final bool roundsSteps;

  /// True for DepEd's own rules, which the E-Class Record filler knows.
  final bool isDepEd;

  int get periodCount => periodNames.length;
  bool get carriesPrevious => previousWeight > 0;

  /// Every category tests can be counted under, in order.
  List<GradeCategory> get leaves => [for (final c in categories) ...c.leaves];

  /// The leaf with [id], or null when tests can't be counted under it.
  GradeCategory? leaf(String? id) {
    for (final l in leaves) {
      if (l.id == id) return l;
    }
    return null;
  }

  String periodLabel(int period) =>
      periodNames[(period - 1).clamp(0, periodCount - 1)];

  String periodShortLabel(int period) =>
      periodShortNames[(period - 1).clamp(0, periodCount - 1)];

  /// "WW 20% · PT 50% · Exam 30%".
  String get weightSummary {
    final total = categories.fold<double>(0, (s, c) => s + c.weight);
    return [
      for (final c in categories)
        '${c.shortLabel} ${formatShare(c.weight, total)}',
    ].join(' · ');
  }

  GradingScheme copyWith({
    List<GradeCategory>? categories,
    double? previousWeight,
    double? currentWeight,
  }) => GradingScheme(
    id: id,
    label: label,
    periodNames: periodNames,
    periodShortNames: periodShortNames,
    categories: categories ?? this.categories,
    scale: scale,
    previousWeight: previousWeight ?? this.previousWeight,
    currentWeight: currentWeight ?? this.currentWeight,
    roundsSteps: roundsSteps,
    isDepEd: isDepEd,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'periodNames': periodNames,
    'periodShortNames': periodShortNames,
    'categories': [for (final c in categories) c.toJson()],
    'scale': scale.toJson(),
    'previousWeight': previousWeight,
    'currentWeight': currentWeight,
    if (roundsSteps) 'roundsSteps': true,
  };

  /// Reads a saved scheme. Returns null for anything that isn't a usable
  /// one (damaged data, or written by a newer app), so the caller can
  /// fall back instead of crashing.
  static GradingScheme? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final label = json['label'];
    final names = _strings(json['periodNames']);
    final shortNames = _strings(json['periodShortNames']);
    final scale = GradeScale._fromJson(json['scale']);
    final rawCategories = json['categories'];
    final previous = json['previousWeight'];
    final current = json['currentWeight'];
    if (id is! String || label is! String || scale == null) return null;
    if (names == null || names.isEmpty || names.length > _maxPeriods) {
      return null;
    }
    if (rawCategories is! List || rawCategories.isEmpty) return null;
    if (previous is! num || current is! num) return null;
    if (!previous.isFinite || !current.isFinite) return null;
    if (previous < 0 || current <= 0) return null;
    final categories = <GradeCategory>[];
    for (final raw in rawCategories) {
      final c = GradeCategory._fromJson(raw, 1);
      if (c == null) return null;
      categories.add(c);
    }
    final scheme = GradingScheme(
      id: id,
      label: label,
      periodNames: names,
      periodShortNames: shortNames?.length == names.length
          ? shortNames!
          : names,
      categories: categories,
      scale: scale,
      previousWeight: previous.toDouble(),
      currentWeight: current.toDouble(),
      roundsSteps: json['roundsSteps'] == true,
    );
    return scheme.problem == null ? scheme : null;
  }

  /// Why this scheme can't grade, in words for the teacher; null when fine.
  String? get problem {
    final ids = <String>{};
    String? check(List<GradeCategory> siblings) {
      if (siblings.fold<double>(0, (s, c) => s + c.weight) <= 0) {
        return 'Give at least one category a weight above 0.';
      }
      for (final c in siblings) {
        if (c.label.trim().isEmpty) return 'Every category needs a name.';
        if (!ids.add(c.id)) return 'Two categories are the same.';
        if (!c.isLeaf) {
          final inner = check(c.children);
          if (inner != null) return inner;
        }
      }
      return null;
    }

    if (categories.isEmpty) return 'Add at least one category.';
    if (currentWeight <= 0) return "This term's share must be above 0.";
    return check(categories);
  }

  static const _maxPeriods = 6;

  static List<String>? _strings(Object? json) {
    if (json is! List || json.any((e) => e is! String)) return null;
    return json.cast<String>();
  }
}

/// [weight] as a share of [total]: "70%", "66.7%".
String formatShare(double weight, double total) {
  if (total <= 0) return '0%';
  final share = weight * 100 / total;
  final whole = share.roundToDouble();
  return (share - whole).abs() < 0.05
      ? '${whole.toInt()}%'
      : '${share.toStringAsFixed(1)}%';
}
