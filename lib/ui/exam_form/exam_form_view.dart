import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/omr/sheet_layout.dart';
import 'package:egrado/ui/answer_key/answer_key_view.dart';
import 'package:egrado/ui/core/messages.dart';
import 'package:egrado/ui/exam_form/exam_form_view_model.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Create a new test, or change an existing one's settings.
class ExamFormPage extends StatelessWidget {
  const ExamFormPage({super.key, required this.classId, this.exam});

  final String classId;
  final Exam? exam;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExamFormViewModel(
        classId: classId,
        exams: context.read<ExamRepository>(),
        classes: context.read<ClassRepository>(),
        existing: exam,
      ),
      child: const _ExamFormView(),
    );
  }
}

class _ExamFormView extends StatelessWidget {
  const _ExamFormView();

  Future<void> _save(BuildContext context) async {
    final viewModel = context.read<ExamFormViewModel>();
    final navigator = Navigator.of(context);
    switch (await viewModel.save()) {
      case FormSaveOutcome.invalid:
        return;
      case FormSaveOutcome.failed:
        if (context.mounted) showMessage(context, Messages.saveFailed);
      case FormSaveOutcome.saved:
        final id = viewModel.savedExamId;
        if (viewModel.isNew && id != null) {
          // Straight on to the answer key: the next thing the teacher needs.
          await navigator.pushReplacement(
            MaterialPageRoute<void>(builder: (_) => AnswerKeyPage(id)),
          );
        } else {
          navigator.pop();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExamFormViewModel>();
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.isNew ? 'New test' : 'Test settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
        children: [
          TextFormField(
            initialValue: viewModel.initialTitle,
            autofocus: viewModel.isNew,
            style: const TextStyle(fontSize: 22),
            textCapitalization: TextCapitalization.sentences,
            onChanged: viewModel.setTitle,
            decoration: InputDecoration(
              labelText: 'Name of the test',
              hintText: 'e.g. Science – 2nd Quarter Exam',
              errorText: viewModel.showTitleError
                  ? 'Please give the test a name'
                  : null,
              errorStyle: const TextStyle(fontSize: 17),
            ),
          ),
          const SectionTitle('How many questions?'),
          const _QuestionCountPicker(),
          const SectionTitle('Choices per question'),
          SegmentedButton<int>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              minimumSize: const Size.fromHeight(kTouchHeight),
              textStyle: text.labelLarge,
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: Colors.white,
              side: const BorderSide(color: AppColors.primary, width: 2),
            ),
            segments: [
              for (final n in ExamFormViewModel.choiceOptions)
                ButtonSegment(
                  value: n,
                  label: Text(
                    '${kChoiceLetters.first} – ${kChoiceLetters[n - 1]}',
                  ),
                ),
            ],
            selected: {viewModel.choices},
            onSelectionChanged: (s) => viewModel.setChoices(s.first),
          ),
          const SectionTitle('Counts toward'),
          const _GradeTagPicker(),
          if (viewModel.removesQuestions) ...[
            const SizedBox(height: Gap.m),
            const NoticeBanner(
              icon: Icons.info_outline,
              text: 'Removed questions will no longer count in the scores.',
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.m),
          child: FilledButton(
            onPressed: () => _save(context),
            child: Text(viewModel.isNew ? 'Next: answer key' : 'Save changes'),
          ),
        ),
      ),
    );
  }
}

/// Quick picks plus − 20 + for fine-tuning; easier than a slider for
/// unsteady hands.
class _QuestionCountPicker extends StatelessWidget {
  const _QuestionCountPicker();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExamFormViewModel>();
    final value = viewModel.questions;

    Widget stepButton(IconData icon, String label, int delta, bool enabled) {
      return Semantics(
        label: label,
        button: true,
        excludeSemantics: true,
        child: OutlinedButton(
          onPressed: enabled
              ? () => viewModel.setQuestions(value + delta)
              : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(kTouchHeight, kTouchHeight),
            padding: EdgeInsets.zero,
          ),
          child: Icon(icon, size: 32),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            stepButton(
              Icons.remove,
              'Fewer questions',
              -1,
              viewModel.canDecrease,
            ),
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            stepButton(Icons.add, 'More questions', 1, viewModel.canIncrease),
          ],
        ),
        const SizedBox(height: Gap.m),
        Wrap(
          spacing: Gap.s,
          runSpacing: Gap.s,
          children: [
            for (final n in ExamFormViewModel.quickCounts)
              ChoiceChip(
                label: Text('$n'),
                selected: value == n,
                showCheckmark: false,
                labelStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: value == n ? Colors.white : AppColors.ink,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.inkMuted, width: 1.5),
                padding: const EdgeInsets.all(Gap.s),
                onSelected: (_) => viewModel.setQuestions(n),
              ),
          ],
        ),
      ],
    );
  }
}

/// Which grading period and which category of the class's grading scheme
/// (WW, PT, ST1… or Quizzes, Exam) the test counts toward. This is what
/// lets the app work out grades and fill the E-Class Record by itself.
class _GradeTagPicker extends StatelessWidget {
  const _GradeTagPicker();

  /// Dropdown value for "Not counted"; category ids are never empty.
  static const _notCountedId = '';

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExamFormViewModel>();
    final scheme = viewModel.scheme;
    final counted = viewModel.isCounted;

    final kindId = viewModel.kind.categoryId ?? _notCountedId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          // The choices change with the class's rules: start over then.
          key: ValueKey('counts-as-${scheme.id}-$kindId'),
          initialValue: kindId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Counts as'),
          items: [
            for (final k in viewModel.kinds)
              DropdownMenuItem(
                value: k.categoryId ?? _notCountedId,
                child: Text(k.label),
              ),
          ],
          onChanged: (id) {
            for (final k in viewModel.kinds) {
              if ((k.categoryId ?? _notCountedId) == id) viewModel.setKind(k);
            }
          },
        ),
        if (counted) ...[
          const SizedBox(height: Gap.m),
          DropdownButtonFormField<int>(
            key: ValueKey('counts-in-${scheme.id}-${viewModel.period}'),
            initialValue: viewModel.period,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'In'),
            items: [
              for (var p = 1; p <= scheme.periodCount; p++)
                DropdownMenuItem(value: p, child: Text(scheme.periodLabel(p))),
            ],
            onChanged: (p) {
              if (p != null) viewModel.setPeriod(p);
            },
          ),
        ],
        const SizedBox(height: Gap.s),
        Text(
          counted
              ? 'Scores go to ${viewModel.kind.label} in '
                    '${scheme.periodLabel(viewModel.period)}'
                    '${scheme.isDepEd ? ' of your class record' : ''}.'
              : "Practice only: scores won't go into grades.",
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.inkMuted),
        ),
      ],
    );
  }
}
