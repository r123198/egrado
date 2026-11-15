import 'package:egrado/data/repositories/class_record_repository.dart';
import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/data/repositories/workspace_repository.dart';
import 'package:egrado/domain/teaching_level.dart';
import 'package:egrado/grading/grading_scheme.dart';
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

/// A class's grades per grading period under its grading scheme, and
/// (for DepEd) the way into filling the teacher's E-Class Record.
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
        workspace: context.read<WorkspaceRepository>(),
      ),
      child: const _GradesView(),
    );
  }
}

class _GradesView extends StatelessWidget {
  const _GradesView();

  Future<void> _setup(BuildContext context) async {
    final viewModel = context.read<GradesViewModel>();
    final chosen = await showModalBottomSheet<GradingChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => GradingSetupSheet(
        level: viewModel.level,
        policy: viewModel.policy,
        subject: viewModel.subject,
        customScheme: viewModel.customScheme,
      ),
    );
    if (chosen == null || !context.mounted) return;
    final saved = await switch (chosen) {
      DepEdChoice(:final policy, :final subject) => viewModel.setGrading(
        policy,
        subject,
      ),
      CustomChoice(:final scheme) => viewModel.setCustomScheme(scheme),
    };
    if (!saved && context.mounted) showMessage(context, Messages.saveFailed);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GradesViewModel>();
    if (viewModel.loadFailed) return const LoadErrorScaffold();
    if (viewModel.isLoading) return const LoadingScaffold();
    final schoolClass = viewModel.schoolClass;
    if (schoolClass == null) return const Scaffold();
    final scheme = viewModel.scheme;
    final isSetUp = viewModel.hasGradingSetup;
    final periodLabel = scheme.periodLabel(viewModel.period);
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
                        !isSetUp
                            ? viewModel.level == TeachingLevel.college
                                  ? 'Choose the grading rules'
                                  : 'Choose the subject'
                            : viewModel.customScheme?.label ??
                                  viewModel.subject?.label ??
                                  scheme.label,
                        style: text.titleMedium,
                      ),
                      Text(
                        !isSetUp
                            ? 'Needed to know the grade weights'
                            : viewModel.customScheme != null
                            ? scheme.weightSummary
                            : '${scheme.weightSummary}\n${scheme.label}',
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
          if (scheme.isDepEd) ...[
            const SizedBox(height: Gap.m),
            BigActionButton(
              icon: Icons.table_view_outlined,
              label: 'Fill my E-Class Record',
              detail: 'Put every scanned score into your Excel class record',
              onPressed: () =>
                  openInTab<void>(context, FillRecordPage(viewModel.classId)),
            ),
          ],
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
                  "counted under something these rules don't have. Open "
                  'each test, tap Edit, and set "Counts toward" again.',
            ),
          ],
          SectionTitle(periodLabel),
          const _PeriodPicker(),
          const SizedBox(height: Gap.m),
          if (!isSetUp)
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
                    "yet in $periodLabel, so the grade isn't final."
                    '${scheme.isDepEd ? ' Your class record will compute '
                              'it once those scores are in.' : ''}',
              ),
              const SizedBox(height: Gap.m),
            ] else if (viewModel.needsPreviousPeriod) ...[
              NoticeBanner(
                icon: Icons.info_outline,
                color: AppColors.primary,
                background: AppColors.primarySoft,
                text:
                    '$periodLabel builds on '
                    '${scheme.periodLabel(viewModel.period - 1)}, which '
                    "isn't complete yet, so there is no grade here.",
              ),
              const SizedBox(height: Gap.m),
            ],
            for (final line in viewModel.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.xs),
                child: _GradeTile(line: line, scheme: scheme),
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
    final scheme = viewModel.scheme;
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
        for (var p = 1; p <= scheme.periodCount; p++)
          ButtonSegment(value: p, label: Text(scheme.periodShortLabel(p))),
      ],
      selected: {viewModel.period},
      onSelectionChanged: (s) => viewModel.selectPeriod(s.first),
    );
  }
}

class _GradeTile extends StatelessWidget {
  const _GradeTile({required this.line, required this.scheme});

  final GradeLine line;
  final GradingScheme scheme;

  @override
  Widget build(BuildContext context) {
    final grade = line.grade;
    final parts = [
      for (final c in scheme.categories)
        if (grade.components[c.id] case final score?)
          '${c.shortLabel} ${score.percentage.toStringAsFixed(0)}%',
    ];
    final value = grade.grade;
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
            _GradeFigure(grade: value, scale: scheme.scale)
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

/// The grade and its mark, whichever the scale reports first on top:
/// "88 / Benchmarking" for DepEd, "2.25 / 84" for a college scale.
class _GradeFigure extends StatelessWidget {
  const _GradeFigure({required this.grade, required this.scale});

  final int grade;
  final GradeScale scale;

  @override
  Widget build(BuildContext context) {
    final mark = scale.mark(grade);
    final (big, small) = scale.marksFirst ? (mark, '$grade') : ('$grade', mark);
    return Semantics(
      label: 'Grade $big, $small',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            big,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: scale.passes(grade) ? AppColors.ink : AppColors.wrong,
            ),
          ),
          Text(
            small,
            style: const TextStyle(fontSize: 15, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
