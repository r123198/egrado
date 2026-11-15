import 'package:egrado/domain/teaching_level.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/grading/grading_scheme.dart';
import 'package:egrado/grading/scheme_presets.dart';
import 'package:egrado/ui/grades/scheme_editor_view.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// What the teacher chose on the grading rules sheet.
sealed class GradingChoice {
  const GradingChoice();
}

/// A DepEd order and the subject that sets its weights.
final class DepEdChoice extends GradingChoice {
  const DepEdChoice(this.policy, this.subject);

  final GradingPolicy policy;
  final SubjectGroup subject;
}

/// The teacher's own scheme: a preset such as college grading, as is or
/// with its categories and weights changed.
final class CustomChoice extends GradingChoice {
  const CustomChoice(this.scheme);

  final GradingScheme scheme;
}

/// Pops a [GradingChoice] once the teacher saves, or null on cancel.
class GradingSetupSheet extends StatefulWidget {
  const GradingSetupSheet({
    super.key,
    required this.level,
    required this.policy,
    this.subject,
    this.customScheme,
  });

  /// DepEd and college rules aren't mixed: the sheet offers one kind.
  final TeachingLevel level;
  final GradingPolicy policy;
  final SubjectGroup? subject;

  /// The class's own scheme when it isn't on DepEd's rules.
  final GradingScheme? customScheme;

  @override
  State<GradingSetupSheet> createState() => _GradingSetupSheetState();
}

class _GradingSetupSheetState extends State<GradingSetupSheet> {
  late GradingPolicy _policy = widget.policy;
  late SubjectGroup? _subject = widget.subject;
  late GradingScheme? _custom = widget.level == TeachingLevel.college
      ? widget.customScheme ?? kCustomSchemePresets.first
      : null;

  void _choosePolicy(GradingPolicy p) => setState(() {
    _policy = p;
    // Subject ids differ between DO 015 and DO 8; keep only a valid one.
    _subject = switch (_subject) {
      final s? => p.subject(s.id),
      null => null,
    };
  });

  /// Keeps the class's edited copy when it came from the same preset.
  void _choosePreset(GradingScheme preset) => setState(() {
    final saved = widget.customScheme;
    _custom = saved?.id == preset.id ? saved : preset;
  });

  Future<void> _edit(GradingScheme scheme) async {
    final edited = await Navigator.of(context).push<GradingScheme>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SchemeEditorPage(scheme),
      ),
    );
    if (edited != null && mounted) setState(() => _custom = edited);
  }

  GradingChoice? get _choice {
    final custom = _custom;
    if (custom != null) return CustomChoice(custom);
    final subject = _subject;
    return subject == null ? null : DepEdChoice(_policy, subject);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final custom = _custom;
    final choice = _choice;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (context, scroll) => SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.m),
                children: [
                  Text('Grading rules', style: text.titleLarge),
                  const SizedBox(height: Gap.s),
                  if (custom != null) ...[
                    _Picker<GradingScheme>(
                      fieldKey: const ValueKey('grading-rules'),
                      label: 'Rules',
                      // By id: the class's copy may have edited weights.
                      value: kCustomSchemePresets.firstWhere(
                        (p) => p.id == custom.id,
                        orElse: () => kCustomSchemePresets.first,
                      ),
                      options: kCustomSchemePresets,
                      title: (p) => p.label,
                      onChanged: _choosePreset,
                    ),
                    const SizedBox(height: Gap.l),
                    Text('Categories and weights', style: text.titleLarge),
                    const SizedBox(height: Gap.s),
                    _SchemeOutline(custom),
                    const SizedBox(height: Gap.s),
                    OutlinedButton.icon(
                      onPressed: () => _edit(custom),
                      icon: const Icon(Icons.tune),
                      label: const Text('Change categories and weights'),
                    ),
                  ] else ...[
                    _Picker<GradingPolicy>(
                      fieldKey: const ValueKey('grading-rules'),
                      label: 'DepEd order',
                      value: _policy,
                      options: kGradingPolicies,
                      title: (p) => p.label,
                      onChanged: _choosePolicy,
                    ),
                    const SizedBox(height: Gap.l),
                    Text('Subject', style: text.titleLarge),
                    Text(
                      'This sets the Written Work / Performance Task / '
                      'Exam weights.',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: Gap.s),
                    _Picker<SubjectGroup>(
                      // A new order has other subjects: start the field over.
                      fieldKey: ValueKey('subject-${_policy.id}'),
                      label: 'Subject',
                      value: _subject,
                      options: _policy.subjects,
                      title: (s) => s.label,
                      detail: _weights,
                      onChanged: (s) => setState(() => _subject = s),
                    ),
                    if (_subject case final subject?) ...[
                      const SizedBox(height: Gap.s),
                      Text(
                        _weights(subject),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.m),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: choice == null
                      ? null
                      : () => Navigator.pop(context, choice),
                  child: const Text('Save'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A scheme's categories with their shares, sub-categories indented, and
/// how a term builds on the one before.
class _SchemeOutline extends StatelessWidget {
  const _SchemeOutline(this.scheme);

  final GradingScheme scheme;

  List<Widget> _rows(List<GradeCategory> siblings, int depth) {
    final total = siblings.fold<double>(0, (sum, c) => sum + c.weight);
    return [
      for (final c in siblings) ...[
        Padding(
          padding: EdgeInsets.only(left: depth * Gap.m, bottom: Gap.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  c.label,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: depth == 0 ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              Text(
                formatShare(c.weight, total),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ..._rows(c.children, depth + 1),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final carried = scheme.previousWeight + scheme.currentWeight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._rows(scheme.categories, 0),
        if (scheme.carriesPrevious && scheme.periodCount > 1)
          Text(
            'From ${scheme.periodLabel(2)} on: '
            '${formatShare(scheme.previousWeight, carried)} the grade '
            'before + ${formatShare(scheme.currentWeight, carried)} this '
            "term's score.",
            style: const TextStyle(fontSize: 17, color: AppColors.inkMuted),
          ),
      ],
    );
  }
}

String _weights(SubjectGroup s) =>
    'WW ${s.weights.writtenWork}% · PT ${s.weights.performanceTask}% · '
    'Exam ${s.weights.exam}%';

/// A dropdown whose long options wrap in the menu and shorten to one
/// line once chosen.
class _Picker<T extends Object> extends StatelessWidget {
  const _Picker({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.options,
    required this.title,
    required this.onChanged,
    this.detail,
  });

  final Key fieldKey;
  final String label;
  final T? value;
  final List<T> options;
  final String Function(T) title;
  final String Function(T)? detail;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: fieldKey,
      initialValue: value,
      isExpanded: true,
      itemHeight: null,
      decoration: InputDecoration(labelText: label),
      hint: const Text('Choose'),
      selectedItemBuilder: (context) => [
        for (final o in options)
          Text(title(o), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
      items: [
        for (final o in options)
          DropdownMenuItem(
            value: o,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Gap.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title(o)),
                  if (detail case final detail?)
                    Text(
                      detail(o),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
      onChanged: (o) {
        if (o != null) onChanged(o);
      },
    );
  }
}
