import 'package:egrado/grading/grading_scheme.dart';
import 'package:flutter/foundation.dart';

/// Editing a class's own grading scheme: category names, weights, how
/// scores combine, and whether a term builds on the one before. Nothing
/// is saved here; the finished [scheme] goes back to the caller.
class SchemeEditorViewModel extends ChangeNotifier {
  SchemeEditorViewModel(GradingScheme scheme) : _scheme = scheme;

  static const maxWeight = 1000.0;
  static const maxLabelLength = 40;

  /// Categories can hold sub-categories, which can't hold more.
  static const maxCategories = 12;

  GradingScheme _scheme;
  double _lastPreviousWeight = 1;

  GradingScheme get scheme => _scheme;

  /// What stops this scheme from grading, for the teacher; null when fine.
  String? get problem => _scheme.problem;

  bool get canAdd => _allIds(_scheme.categories).length < maxCategories;

  /// [category]'s share of its siblings, e.g. "70%".
  String shareOf(GradeCategory category, List<GradeCategory> siblings) =>
      formatShare(
        category.weight,
        siblings.fold<double>(0, (sum, c) => sum + c.weight),
      );

  String get previousShare => formatShare(
    _scheme.previousWeight,
    _scheme.previousWeight + _scheme.currentWeight,
  );

  String get currentShare => formatShare(
    _scheme.currentWeight,
    _scheme.previousWeight + _scheme.currentWeight,
  );

  void rename(String id, String label) {
    final text = label.length > maxLabelLength
        ? label.substring(0, maxLabelLength)
        : label;
    _update(id, (c) => c.copyWith(label: text));
  }

  /// [text] as typed; anything that isn't a number counts as 0.
  void setWeight(String id, String text) =>
      _update(id, (c) => c.copyWith(weight: parseWeight(text)));

  void setCombine(String id, CombineRule rule) =>
      _update(id, (c) => c.copyWith(combine: rule));

  /// Adds a category at the top level, or under [parentId]. A category
  /// that had tests counted under it and gains a sub-category stops
  /// taking tests itself; the Grades screen then asks to re-tag them.
  void add({String? parentId}) {
    if (!canAdd) return;
    final added = GradeCategory(
      id: _newId(),
      label: 'New category',
      weight: 10,
      combine: CombineRule.averageOfPercents,
    );
    if (parentId == null) {
      _set(_scheme.copyWith(categories: [..._scheme.categories, added]));
    } else {
      _update(parentId, (c) => c.copyWith(children: [...c.children, added]));
    }
  }

  void remove(String id) =>
      _set(_scheme.copyWith(categories: _without(_scheme.categories, id)));

  void setCarriesPrevious(bool value) {
    if (value == _scheme.carriesPrevious) return;
    if (!value) _lastPreviousWeight = _scheme.previousWeight;
    _set(_scheme.copyWith(previousWeight: value ? _lastPreviousWeight : 0));
  }

  void setPreviousWeight(String text) =>
      _set(_scheme.copyWith(previousWeight: parseWeight(text)));

  void setCurrentWeight(String text) =>
      _set(_scheme.copyWith(currentWeight: parseWeight(text)));

  /// A typed weight, kept between 0 and [maxWeight].
  static double parseWeight(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    if (value == null || !value.isFinite) return 0;
    return value.clamp(0, maxWeight).toDouble();
  }

  void _update(String id, GradeCategory Function(GradeCategory) change) => _set(
    _scheme.copyWith(categories: _replaced(_scheme.categories, id, change)),
  );

  void _set(GradingScheme scheme) {
    _scheme = scheme;
    notifyListeners();
  }

  static List<GradeCategory> _replaced(
    List<GradeCategory> list,
    String id,
    GradeCategory Function(GradeCategory) change,
  ) => [
    for (final c in list)
      if (c.id == id)
        change(c)
      else if (c.isLeaf)
        c
      else
        c.copyWith(children: _replaced(c.children, id, change)),
  ];

  static List<GradeCategory> _without(List<GradeCategory> list, String id) => [
    for (final c in list)
      if (c.id != id)
        c.isLeaf ? c : c.copyWith(children: _without(c.children, id)),
  ];

  static Set<String> _allIds(List<GradeCategory> list) => {
    for (final c in list) ...{c.id, ..._allIds(c.children)},
  };

  String _newId() {
    final taken = _allIds(_scheme.categories);
    var n = taken.length + 1;
    while (taken.contains('cat_$n')) {
      n++;
    }
    return 'cat_$n';
  }
}
