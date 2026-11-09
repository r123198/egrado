import 'package:egrado/data/repositories/class_record_repository.dart';
import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/grading/grading_policy.dart';
import 'package:egrado/grading/term_grade.dart';
import 'package:egrado/grading/transmutation.dart';
import 'package:egrado/ui/core/loading_scaffold.dart';
import 'package:egrado/ui/core/messages.dart';
import 'package:egrado/ui/core/navigation.dart';
import 'package:egrado/ui/grades/fill_record_view.dart';
import 'package:egrado/ui/grades/grades_view_model.dart';
import 'package:egrado/ui/grades/grading_setup_sheet.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A class's DepEd grades per term, and the way into filling the
/// teacher's E-Class Record.
class GradesPage extends StatelessWidget {
  const GradesPage(this.classId, {super.key});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GradesViewModel(
        classId: classId,
        classes: context.read<ClassRepository>(),
        exams: context.read<ExamRepository>(),
        records: context.read<ClassRecordRepository>(),
      ),
      child: const _GradesView(),
    );
  }
}

class _GradesView extends StatelessWidget {
  const _GradesView();

  Future<void> _setup(BuildContext context) async {
    final viewModel = context.read<GradesViewModel>();
    final chosen = await showModalBottomSheet<(GradingPolicy, SubjectGroup?)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => GradingSetupSheet(
        policy: viewModel.policy,
        subject: viewModel.subject,
      ),
    );
    if (chosen == null || !context.mounted) return;
    final (policy, subject) = chosen;
    if (!await viewModel.setGrading(policy, subject) && context.mounted) {
      showMessage(context, Messages.saveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GradesViewModel>();
    if (viewModel.loadFailed) return const LoadErrorScaffold();
    if (viewModel.isLoading) return const LoadingScaffold();
    final schoolClass = viewModel.schoolClass;
    if (schoolClass == null) return const Scaffold();
    final policy = viewModel.policy;
    final subject = viewModel.subject;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Grades · ${schoolClass.name}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
        children: [
          SurfaceCard(
            onTap: () => _setup(context),
            child: Row(
              children: [
                const Icon(Icons.rule, size: 34, color: AppColors.primary),
                const SizedBox(width: Gap.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject?.label ?? 'Choose the subject',
                        style: text.titleMedium,
                      ),
                      Text(
                        subject == null
                            ? 'Needed to know the grade weights'
                            : 'WW ${subject.weights.writtenWork}% · '
                                  'PT ${subject.weights.performanceTask}% · '
                                  'Exam ${subject.weights.exam}%\n'
                                  '${policy.label}',
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined, color: AppColors.inkMuted),
              ],
            ),
          ),
          const SizedBox(height: Gap.m),
          BigActionButton(
            icon: Icons.table_view_outlined,
            label: 'Fill my E-Class Record',
            detail: 'Put every scanned score into your Excel class record',
            onPressed: () =>
                openInTab<void>(context, FillRecordPage(viewModel.classId)),
          ),
          if (viewModel.untaggedCount > 0) ...[
            const SizedBox(height: Gap.m),
            NoticeBanner(
              icon: Icons.label_off_outlined,
              text:
                  '${viewModel.untaggedCount} '
                  '${viewModel.untaggedCount == 1 ? "test doesn't" : "tests don't"} '
                  'count toward grades yet. Open the test, tap Edit, and '
                  'set "Counts toward".',
            ),
          ],
          if (viewModel.outOfRangeCount > 0) ...[
            const SizedBox(height: Gap.m),
            NoticeBanner(
              icon: Icons.event_busy_outlined,
              text:
                  '${viewModel.outOfRangeCount} '
                  '${viewModel.outOfRangeCount == 1 ? 'test is' : 'tests are'} '
                  'set to a ${policy.periodName.toLowerCase()} these rules '
                  "don't have. Edit them and pick a "
                  '${policy.periodName.toLowerCase()} from 1 to '
                  '${policy.periodCount}.',
            ),
          ],
          SectionTitle(policy.periodLabel(viewModel.period)),
          const _PeriodPicker(),
          const SizedBox(height: Gap.m),
          if (subject == null)
            const EmptyState(
              icon: Icons.rule,
              title: 'Choose the subject first',
              message: 'Tap the card above so the app knows the weights.',
            )
          else ...[
            if (viewModel.unkeyedCount > 0) ...[
              NoticeBanner(
                icon: Icons.vpn_key_outlined,
                text:
                    '${viewModel.unkeyedCount} '
                    '${viewModel.unkeyedCount == 1 ? 'test here has' : 'tests here have'} '
                    "an unfinished answer key and isn't counted yet.",
              ),
              const SizedBox(height: Gap.m),
            ],
            if (viewModel.missingComponents.isNotEmpty) ...[
              NoticeBanner(
                icon: Icons.info_outline,
                color: AppColors.primary,
                background: AppColors.primarySoft,
                text:
                    'No ${viewModel.missingComponents.map((c) => c.label).join(' or ')} '
                    'yet in ${policy.periodLabel(viewModel.period)}, so the '
                    'term grade isn\'t final. Your class record will '
                    'compute it once those scores are in.',
              ),
              const SizedBox(height: Gap.m),
            ],
            for (final line in viewModel.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.xs),
                child: _GradeTile(line: line, policy: policy),
              ),
          ],
        ],
      ),
    );
  }
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GradesViewModel>();
    final policy = viewModel.policy;
    return SegmentedButton<int>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        minimumSize: const Size.fromHeight(kTouchHeight),
        textStyle: Theme.of(context).textTheme.labelLarge,
        selectedBackgroundColor: AppColors.primary,
        selectedForegroundColor: Colors.white,
        side: const BorderSide(color: AppColors.primary, width: 2),
      ),
      segments: [
        for (var p = 1; p <= policy.periodCount; p++)
          ButtonSegment(value: p, label: Text('${policy.periodName[0]}$p')),
      ],
      selected: {viewModel.period},
      onSelectionChanged: (s) => viewModel.selectPeriod(s.first),
    );
  }
}

class _GradeTile extends StatelessWidget {
  const _GradeTile({required this.line, required this.policy});

  final GradeLine line;
  final GradingPolicy policy;

  @override
  Widget build(BuildContext context) {
    final grade = line.grade;
    final parts = [
      for (final MapEntry(key: c, value: s) in grade.components.entries)
        '${c.code} ${s.percentage.toStringAsFixed(0)}%',
    ];
    final value = grade.grade;
    final passed = value != null && value >= kPassingGrade;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: Gap.s),
      child: Row(
        children: [
          NumberBadge(line.student.number),
          const SizedBox(width: Gap.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.student.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  parts.isEmpty ? 'No scores yet' : parts.join(' · '),
                  style: const TextStyle(
                    fontSize: 17,
                    color: AppColors.inkMuted,
                  ),
                ),
                if (grade.missedActivities > 0)
                  Text(
                    '${grade.missedActivities} not scanned (counts as 0)',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.check,
                    ),
                  ),
              ],
            ),
          ),
          if (value != null)
            Semantics(
              label: 'Grade $value, ${descriptor(value, policy)}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: passed ? AppColors.ink : AppColors.wrong,
                    ),
                  ),
                  Text(
                    descriptor(value, policy),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            const Text(
              '—',
              style: TextStyle(fontSize: 30, color: AppColors.inkMuted),
            ),
        ],
      ),
    );
  }
}
