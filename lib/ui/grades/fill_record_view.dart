import 'package:egrado/class_record/class_record_fill.dart';
import 'package:egrado/data/repositories/class_record_repository.dart';
import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/services/class_record_engine.dart';
import 'package:egrado/services/class_record_file_service.dart';
import 'package:egrado/ui/core/loading_scaffold.dart';
import 'package:egrado/ui/grades/fill_record_view_model.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Choose the teacher's E-Class Record, check names, fill it, save it.
class FillRecordPage extends StatelessWidget {
  const FillRecordPage(this.classId, {super.key});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FillRecordViewModel(
        classId: classId,
        classes: context.read<ClassRepository>(),
        exams: context.read<ExamRepository>(),
        records: context.read<ClassRecordRepository>(),
        files: context.read<ClassRecordFileService>(),
        engine: context.read<ClassRecordEngine>(),
      ),
      child: const _FillRecordView(),
    );
  }
}

class _FillRecordView extends StatelessWidget {
  const _FillRecordView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FillRecordViewModel>();
    if (viewModel.loadFailed) return const LoadErrorScaffold();
    if (viewModel.isLoading) return const LoadingScaffold();
    return Scaffold(
      appBar: AppBar(title: const Text('Fill E-Class Record')),
      body: switch (viewModel.step) {
        FillStep.choose => const _ChooseStep(),
        FillStep.reading => const _Working('Reading your class record…'),
        FillStep.review => const _ReviewStep(),
        FillStep.filling => const _Working('Writing the scores…'),
        FillStep.done => const _DoneStep(),
      },
    );
  }
}

String problemText(RecordProblem problem) => switch (problem) {
  RecordProblem.notAWorkbook =>
    'That file isn\'t an Excel (.xlsx) file, or it is damaged. If your class '
        'record is in Google Sheets, download it as Microsoft Excel (.xlsx) '
        'first.',
  RecordProblem.notAClassRecord =>
    'That file doesn\'t look like a DepEd E-Class Record: no sheet has a '
        '"HIGHEST POSSIBLE SCORE" row.',
  RecordProblem.noLearners =>
    'Your class record has no learner names yet. Type them in the '
        'INPUT DATA sheet, save, then choose the file again.',
};

String skipText(SkipReason reason, String periodName) => switch (reason) {
  SkipReason.noSuchPeriod =>
    'Your class record has no sheet for this '
        '${periodName.toLowerCase()}.',
  SkipReason.noFreeColumn =>
    'All columns for this are already filled in your class record.',
  SkipReason.noHighestScore => 'The answer key isn\'t finished.',
};

class _Working extends StatelessWidget {
  const _Working(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 5),
          const SizedBox(height: Gap.m),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ChooseStep extends StatelessWidget {
  const _ChooseStep();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FillRecordViewModel>();
    final text = Theme.of(context).textTheme;
    final activities = viewModel.activities;
    final problem = viewModel.problem;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
      children: [
        Text(
          'The app writes each scanned test into your own E-Class Record: '
          'the Highest Possible Score and every learner\'s raw score, in the '
          'right term and column. Your class record\'s formulas then work '
          'out the grades, just as if you had typed them.',
          style: text.bodyLarge,
        ),
        const SizedBox(height: Gap.m),
        if (problem != null) ...[
          NoticeBanner(icon: Icons.error_outline, text: problemText(problem)),
          const SizedBox(height: Gap.m),
        ],
        if (viewModel.fileError) ...[
          const NoticeBanner(
            icon: Icons.error_outline,
            text: 'The file could not be opened. Please try again.',
          ),
          const SizedBox(height: Gap.m),
        ],
        if (activities.isEmpty)
          const EmptyState(
            icon: Icons.fact_check_outlined,
            title: 'Nothing to fill yet',
            message:
                'Scan papers for tests that count toward grades (set '
                '"Counts toward" when you create or edit a test).',
          )
        else ...[
          BigActionButton(
            icon: Icons.upload_file_outlined,
            label: 'Choose my class record',
            detail: 'The .xlsx file from DepEd or your school',
            onPressed: viewModel.chooseFile,
          ),
          const SectionTitle('Tests that will be filled'),
          for (final a in activities)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.xs),
              child: SurfaceCard(
                padding: const EdgeInsets.all(Gap.s),
                child: Row(
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: Gap.s),
                    Expanded(child: Text(a.title, style: text.titleMedium)),
                    Text(
                      '${a.examPart?.code ?? a.component.code} · '
                      '${viewModel.periodName} ${a.period}',
                      style: text.bodyMedium?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Gap.s),
          Text(
            'Performance Tasks you score by hand stay as you typed them: '
            'the app only uses empty columns.',
            style: text.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FillRecordViewModel>();
    final text = Theme.of(context).textTheme;
    final unmatched = viewModel.unmatched;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.m),
            children: [
              Text(
                'Found ${viewModel.recordNames.length} learners in '
                '${viewModel.periodSheets.join(', ')}.',
                style: text.bodyLarge,
              ),
              const SizedBox(height: Gap.m),
              if (unmatched.isEmpty)
                const NoticeBanner(
                  icon: Icons.check_circle_outline,
                  color: AppColors.correct,
                  background: AppColors.correctSoft,
                  text: 'Every student was matched to the class record.',
                )
              else
                NoticeBanner(
                  icon: Icons.help_outline,
                  text:
                      '${unmatched.length} '
                      '${unmatched.length == 1 ? 'student needs' : 'students need'} '
                      'a name picked below. Their scores are skipped if left '
                      'blank.',
                ),
              if (viewModel.toConfirm.isNotEmpty) ...[
                const SizedBox(height: Gap.s),
                NoticeBanner(
                  icon: Icons.fact_check_outlined,
                  text:
                      'Please check ${viewModel.toConfirm.length} '
                      '${viewModel.toConfirm.length == 1 ? 'match' : 'matches'} '
                      'where the names are not exactly the same.',
                ),
              ],
              const SectionTitle('Check the names'),
              for (final s in viewModel.students)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.xs),
                  child: _NamePairTile(
                    number: s.number,
                    name: s.name,
                    recordName: viewModel.pairs[s.number],
                    needsConfirming: viewModel.needsConfirming(s.number),
                    options: viewModel.namesAvailableFor(s.number),
                    onChanged: (v) => viewModel.pair(s.number, v),
                    onConfirm: () => viewModel.confirm(s.number),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Gap.m),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: viewModel.canFill ? viewModel.fill : null,
                icon: const Icon(Icons.edit_note, size: 30),
                label: Text(
                  viewModel.toConfirm.isEmpty
                      ? 'Fill class record'
                      : 'Check the names above first',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NamePairTile extends StatelessWidget {
  const _NamePairTile({
    required this.number,
    required this.name,
    required this.recordName,
    required this.needsConfirming,
    required this.options,
    required this.onChanged,
    required this.onConfirm,
  });

  final int number;
  final String name;
  final String? recordName;
  final bool needsConfirming;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final matched = recordName != null && !needsConfirming;
    return SurfaceCard(
      borderColor: matched ? AppColors.line : AppColors.check,
      padding: const EdgeInsets.all(Gap.s),
      child: Row(
        children: [
          NumberBadge(number, muted: !matched),
          const SizedBox(width: Gap.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                DropdownButton<String?>(
                  isExpanded: true,
                  value: recordName,
                  hint: const Text(
                    'Pick from class record',
                    style: TextStyle(fontSize: 18, color: AppColors.check),
                  ),
                  style: const TextStyle(fontSize: 18, color: AppColors.ink),
                  items: [
                    for (final o in options)
                      DropdownMenuItem(value: o, child: Text(o)),
                    const DropdownMenuItem(
                      child: Text('Not in this class record'),
                    ),
                  ],
                  onChanged: onChanged,
                ),
                if (needsConfirming)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check),
                      label: const Text('Yes, same learner'),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            matched ? Icons.check_circle : Icons.help_outline,
            color: matched ? AppColors.correct : AppColors.check,
            semanticLabel: matched ? 'Matched' : 'Not matched',
          ),
        ],
      ),
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep();

  Future<void> _save(BuildContext context) async {
    final outcome = await context.read<FillRecordViewModel>().save();
    if (!context.mounted) return;
    switch (outcome) {
      case FileOutcome.done:
        showMessage(context, 'Saved. Open it in Excel to see the grades.');
      case FileOutcome.failed:
        showMessage(context, 'Could not save the file. Try Share instead.');
      case FileOutcome.cancelled:
        break;
    }
  }

  Future<void> _share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final outcome = await buttonContext.read<FillRecordViewModel>().share(
      origin: origin,
    );
    if (outcome == FileOutcome.failed && buttonContext.mounted) {
      showMessage(buttonContext, 'Could not share the file. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FillRecordViewModel>();
    final report = viewModel.report;
    if (report == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final written = report.outcomes.where((o) => o.isWritten).toList();
    final skipped = report.outcomes.where((o) => !o.isWritten).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
      children: [
        NoticeBanner(
          icon: Icons.check_circle_outline,
          color: AppColors.correct,
          background: AppColors.correctSoft,
          text:
              'Filled ${written.length} '
              '${written.length == 1 ? 'test' : 'tests'}. Save the file, '
              'then open it in Excel: the grades update by themselves. (If '
              'Excel shows "Enable Editing", tap it so the grades refresh.)',
        ),
        const SizedBox(height: Gap.m),
        BigActionButton(
          icon: Icons.save_alt,
          label: 'Save to phone',
          detail: viewModel.outputName,
          onPressed: () => _save(context),
        ),
        const SizedBox(height: Gap.s),
        Builder(
          builder: (buttonContext) => BigActionButton(
            icon: Icons.ios_share,
            label: 'Share',
            detail: 'Google Drive, Messenger, email…',
            primary: false,
            onPressed: () => _share(buttonContext),
          ),
        ),
        if (report.studentsNotInRecord.isNotEmpty) ...[
          const SizedBox(height: Gap.m),
          NoticeBanner(
            icon: Icons.person_off_outlined,
            text:
                'Not in the class record, so their scores were skipped: '
                '${report.studentsNotInRecord.map(viewModel.studentName).join(', ')}.',
          ),
        ],
        for (final o in report.outcomes)
          if (o.leftBehind case final old?) ...[
            const SizedBox(height: Gap.m),
            NoticeBanner(
              icon: Icons.warning_amber_outlined,
              text:
                  '"${o.activity.title}" moved. Its old scores are still in '
                  '${old.label}. Delete them there so it isn\'t counted twice.',
            ),
          ],
        const SectionTitle('Where each test went'),
        for (final o in written)
          _OutcomeTile(
            icon: Icons.check,
            color: AppColors.correct,
            title: o.activity.title,
            detail: '${o.columnLabel} · ${o.scoresWritten} scores',
          ),
        for (final o in skipped)
          _OutcomeTile(
            icon: Icons.block,
            color: AppColors.wrong,
            title: o.activity.title,
            detail: skipText(o.skipReason!, viewModel.periodName),
          ),
        const SizedBox(height: Gap.m),
        Text(
          'Next time, choose this new file so your newest scores are kept. '
          'Filling again updates the same columns, never duplicates.',
          style: text.bodyMedium?.copyWith(color: AppColors.inkMuted),
        ),
        const SizedBox(height: Gap.m),
        OutlinedButton(
          onPressed: viewModel.reset,
          child: const Text('Fill another file'),
        ),
      ],
    );
  }
}

class _OutcomeTile extends StatelessWidget {
  const _OutcomeTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.xs),
      child: SurfaceCard(
        padding: const EdgeInsets.all(Gap.s),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: Gap.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    detail,
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
    );
  }
}
