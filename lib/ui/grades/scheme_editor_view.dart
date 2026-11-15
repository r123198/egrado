import 'package:egrado/grading/grading_scheme.dart';
import 'package:egrado/ui/grades/scheme_editor_view_model.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Change a grading scheme's categories and weights. Pops the edited
/// [GradingScheme] on Save, or null when the teacher backs out.
class SchemeEditorPage extends StatelessWidget {
  const SchemeEditorPage(this.scheme, {super.key});

  final GradingScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SchemeEditorViewModel(scheme),
      child: const _SchemeEditorView(),
    );
  }
}

class _SchemeEditorView extends StatelessWidget {
  const _SchemeEditorView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SchemeEditorViewModel>();
    final scheme = viewModel.scheme;
    final text = Theme.of(context).textTheme;
    final problem = viewModel.problem;
    return Scaffold(
      appBar: AppBar(title: const Text('Categories and weights')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
        children: [
          Text(
            'Match your syllabus. Weights are shares: 70 and 30, or 2 and 1 '
            'for two-thirds and one-third.',
            style: text.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: Gap.m),
          for (final c in scheme.categories) ...[
            _CategoryCard(category: c, siblings: scheme.categories),
            const SizedBox(height: Gap.s),
          ],
          OutlinedButton.icon(
            onPressed: viewModel.canAdd ? viewModel.add : null,
            icon: const Icon(Icons.add),
            label: const Text('Add a category'),
          ),
          if (scheme.periodCount > 1) ...[
            const SectionTitle('Building on the term before'),
            const _CarryOver(),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.m),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (problem != null) ...[
                Text(
                  problem,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.wrong,
                  ),
                ),
                const SizedBox(height: Gap.s),
              ],
              FilledButton(
                onPressed: problem == null
                    ? () => Navigator.pop(context, scheme)
                    : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One top-level category and, inside it, its sub-categories.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.siblings});

  final GradeCategory category;
  final List<GradeCategory> siblings;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<SchemeEditorViewModel>();
    return SurfaceCard(
      padding: const EdgeInsets.all(Gap.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CategoryFields(category: category, siblings: siblings),
          for (final child in category.children)
            Padding(
              padding: const EdgeInsets.only(left: Gap.m, top: Gap.s),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.line, width: 3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: Gap.s),
                  child: _CategoryFields(
                    category: child,
                    siblings: category.children,
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: viewModel.canAdd
                  ? () => viewModel.add(parentId: category.id)
                  : null,
              icon: const Icon(Icons.subdirectory_arrow_right),
              label: Text('Add a part of ${category.label}'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Name, weight and (for a category that takes tests) how scores combine.
class _CategoryFields extends StatelessWidget {
  const _CategoryFields({required this.category, required this.siblings});

  final GradeCategory category;
  final List<GradeCategory> siblings;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<SchemeEditorViewModel>();
    final id = category.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('name-$id'),
                initialValue: category.label,
                maxLength: SchemeEditorViewModel.maxLabelLength,
                textCapitalization: TextCapitalization.words,
                onChanged: (v) => viewModel.rename(id, v),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  counterText: '',
                ),
              ),
            ),
            IconButton(
              tooltip: 'Remove ${category.label}',
              onPressed: () => viewModel.remove(id),
              icon: const Icon(Icons.delete_outline),
              constraints: const BoxConstraints(
                minWidth: kTouchHeight,
                minHeight: kTouchHeight,
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.s),
        _WeightField(
          fieldKey: ValueKey('weight-$id'),
          weight: category.weight,
          share: viewModel.shareOf(category, siblings),
          onChanged: (v) => viewModel.setWeight(id, v),
        ),
        if (category.isLeaf) ...[
          const SizedBox(height: Gap.s),
          DropdownButtonFormField<CombineRule>(
            key: ValueKey('combine-$id'),
            initialValue: category.combine,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Scores combine by'),
            items: [
              for (final rule in CombineRule.values)
                DropdownMenuItem(value: rule, child: Text(rule.label)),
            ],
            onChanged: (rule) {
              if (rule != null) viewModel.setCombine(id, rule);
            },
          ),
        ],
      ],
    );
  }
}

/// A weight box with the share it works out to beside it.
class _WeightField extends StatelessWidget {
  const _WeightField({
    required this.fieldKey,
    required this.weight,
    required this.share,
    required this.onChanged,
    this.label = 'Weight',
  });

  final Key fieldKey;
  final double weight;
  final String share;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: TextFormField(
            key: fieldKey,
            initialValue: formatWeight(weight),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.,]')),
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: onChanged,
            decoration: InputDecoration(labelText: label),
          ),
        ),
        const SizedBox(width: Gap.s),
        Expanded(
          child: Text(
            '= $share',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _CarryOver extends StatelessWidget {
  const _CarryOver();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SchemeEditorViewModel>();
    final scheme = viewModel.scheme;
    final second = scheme.periodLabel(2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: scheme.carriesPrevious,
          onChanged: viewModel.setCarriesPrevious,
          title: Text('From $second on, count the grade before'),
          subtitle: Text(
            scheme.carriesPrevious
                ? "A term's grade mixes the previous grade with its own score."
                : 'Each term is graded on its own.',
          ),
        ),
        if (scheme.carriesPrevious) ...[
          const SizedBox(height: Gap.s),
          _WeightField(
            fieldKey: const ValueKey('weight-previous'),
            label: 'Grade before',
            weight: scheme.previousWeight,
            share: viewModel.previousShare,
            onChanged: viewModel.setPreviousWeight,
          ),
          const SizedBox(height: Gap.s),
          _WeightField(
            fieldKey: const ValueKey('weight-current'),
            label: "This term's score",
            weight: scheme.currentWeight,
            share: viewModel.currentShare,
            onChanged: viewModel.setCurrentWeight,
          ),
        ],
      ],
    );
  }
}

/// A weight without a pointless ".0": 70, 2, 33.5.
String formatWeight(double weight) => weight == weight.roundToDouble()
    ? weight.toInt().toString()
    : weight.toString();
