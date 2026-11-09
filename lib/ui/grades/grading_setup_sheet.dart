import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Pops `(policy, subject)` once the teacher saves, or null on cancel.
class GradingSetupSheet extends StatefulWidget {
  const GradingSetupSheet({super.key, required this.policy, this.subject});

  final GradingPolicy policy;
  final SubjectGroup? subject;

  @override
  State<GradingSetupSheet> createState() => _GradingSetupSheetState();
}

class _GradingSetupSheetState extends State<GradingSetupSheet> {
  late GradingPolicy _policy = widget.policy;
  late SubjectGroup? _subject = widget.subject;

  void _choosePolicy(GradingPolicy p) => setState(() {
    _policy = p;
    // Subject ids differ between DO 015 and DO 8; keep only a valid one.
    _subject = _subject == null ? null : p.subject(_subject!.id);
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                  for (final p in kGradingPolicies)
                    _Option(
                      title: p.label,
                      selected: p.id == _policy.id,
                      onTap: () => _choosePolicy(p),
                    ),
                  const SizedBox(height: Gap.l),
                  Text('Subject', style: text.titleLarge),
                  Text(
                    'This sets the Written Work / Performance Task / '
                    'Exam weights.',
                    style: text.bodyMedium?.copyWith(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: Gap.s),
                  for (final s in _policy.subjects)
                    _Option(
                      title: s.label,
                      detail:
                          'WW ${s.weights.writtenWork}% · '
                          'PT ${s.weights.performanceTask}% · '
                          'Exam ${s.weights.exam}%',
                      selected: s.id == _subject?.id,
                      onTap: () => setState(() => _subject = s),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.m),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _subject == null
                      ? null
                      : () => Navigator.pop(context, (_policy, _subject)),
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

class _Option extends StatelessWidget {
  const _Option({
    required this.title,
    required this.selected,
    required this.onTap,
    this.detail,
  });

  final String title;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.xs),
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.line,
            width: selected ? 2.5 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Semantics(
            selected: selected,
            button: true,
            child: Padding(
              padding: const EdgeInsets.all(Gap.s),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? AppColors.primary : AppColors.inkMuted,
                    size: 28,
                  ),
                  const SizedBox(width: Gap.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (detail case final d?)
                          Text(
                            d,
                            style: const TextStyle(
                              fontSize: 17,
                              color: AppColors.inkMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
