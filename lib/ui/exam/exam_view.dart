import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/data/repositories/result_repository.dart';
import 'package:egrado/domain/exam.dart';
import 'package:egrado/services/results_export_service.dart';
import 'package:egrado/services/sheet_print_service.dart';
import 'package:egrado/ui/answer_key/answer_key_view.dart';
import 'package:egrado/ui/core/loading_scaffold.dart';
import 'package:egrado/ui/core/messages.dart';
import 'package:egrado/ui/exam/exam_view_model.dart';
import 'package:egrado/ui/exam/print_choice_sheet.dart';
import 'package:egrado/ui/exam/score_widgets.dart';
import 'package:egrado/ui/exam/test_action_bar.dart';
import 'package:egrado/ui/exam_form/exam_form_view.dart';
import 'package:egrado/ui/scan/result_review_view.dart';
import 'package:egrado/ui/scan/scan_session_view.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Everything about one test: scan, key, print, scores, export.
class ExamPage extends StatelessWidget {
  const ExamPage(this.examId, {super.key});

  final String examId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExamViewModel(
        examId: examId,
        exams: context.read<ExamRepository>(),
        classes: context.read<ClassRepository>(),
        results: context.read<ResultRepository>(),
        printer: context.read<SheetPrintService>(),
        exporter: context.read<ResultsExportService>(),
      ),
      child: const _ExamView(),
    );
  }
}

class _ExamView extends StatelessWidget {
  const _ExamView();

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));

  Future<void> _delete(BuildContext context, Exam exam) async {
    final viewModel = context.read<ExamViewModel>();
    final ok = await confirmAction(
      context,
      title: 'Delete ${exam.title}?',
      message: 'All scanned scores for this test will be deleted too.',
      confirmLabel: 'Delete test',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final navigator = Navigator.of(context);
    if (await viewModel.delete()) {
      navigator.pop();
    } else if (context.mounted) {
      showMessage(context, Messages.saveFailed);
    }
  }

  Future<void> _print(BuildContext context) async {
    final viewModel = context.read<ExamViewModel>();
    final named = viewModel.hasStudents
        ? await showModalBottomSheet<bool>(
            context: context,
            builder: (_) => const PrintChoiceSheet(),
          )
        : false;
    if (named == null) return;
    final outcome = await viewModel.printSheets(named: named);
    if (outcome == ActionOutcome.unavailable && context.mounted) {
      showMessage(context, Messages.printUnavailable);
    }
  }

  Future<void> _export(BuildContext buttonContext) async {
    // iPad needs to know where the share popover should point.
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final outcome = await buttonContext.read<ExamViewModel>().exportScores(
      origin: origin,
    );
    if (outcome == ActionOutcome.unavailable && buttonContext.mounted) {
      showMessage(buttonContext, Messages.exportFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExamViewModel>();
    if (viewModel.loadFailed) return const LoadErrorScaffold();
    if (viewModel.isLoading) return const LoadingScaffold();
    final exam = viewModel.exam;
    final schoolClass = viewModel.schoolClass;
    if (exam == null || schoolClass == null) return const Scaffold();
    final canCheck = viewModel.canCheckPapers;

    return Scaffold(
      appBar: AppBar(
        title: Text(exam.title),
        actions: [
          PopupMenuButton<VoidCallback>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => action(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: () => _delete(context, exam),
                child: const Text(
                  'Delete test',
                  style: TextStyle(fontSize: 20, color: AppColors.wrong),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
        children: [
          Text(
            '${schoolClass.name}  ·  ${exam.questionCount} questions',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: Gap.m),
          if (!canCheck) ...[
            const NoticeBanner(
              icon: Icons.vpn_key_outlined,
              text: 'Next step: tap Key below and set the correct answers.',
            ),
            const SizedBox(height: Gap.m),
          ] else if (!viewModel.hasResults) ...[
            const NoticeBanner(
              icon: Icons.photo_camera_outlined,
              color: AppColors.primary,
              background: AppColors.primarySoft,
              text: 'Ready! Tap Scan below to check the first paper.',
            ),
            const SizedBox(height: Gap.m),
          ],
          Text('Scores', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Gap.s),
          ScoreSummaryCard(summary: viewModel.summary),
          const SizedBox(height: Gap.m),
          if (viewModel.scoreLines.isEmpty)
            const EmptyState(
              icon: Icons.fact_check_outlined,
              title: 'No papers checked yet',
              message: 'Scores appear here as soon as you scan a paper.',
            ),
          for (final line in viewModel.scoreLines)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.xs),
              child: ScoreLineTile(
                line: line,
                total: viewModel.summary.total,
                onTap: line.isChecked
                    ? () => _open(
                        context,
                        ResultReviewPage.saved(exam.id, line.number),
                      )
                    : null,
              ),
            ),
        ],
      ),
      bottomNavigationBar: TestActionBar(
        scanReady: canCheck,
        onKey: () => _open(context, AnswerKeyPage(exam.id)),
        onPrint: () => _print(context),
        onScan: () => canCheck
            ? _open(context, ScanSessionPage(exam.id))
            : _keyFirst(context, exam.id),
        onExport: (buttonContext) => viewModel.hasResults
            ? _export(buttonContext)
            : showMessage(
                context,
                'Nothing to export yet. Scan some papers first.',
              ),
        onEdit: () =>
            _open(context, ExamFormPage(classId: exam.classId, exam: exam)),
      ),
    );
  }

  /// Scan was tapped before the key exists: explain, then open the key.
  void _keyFirst(BuildContext context, String examId) {
    showMessage(context, 'Set the answer key first, then you can scan.');
    _open(context, AnswerKeyPage(examId));
  }
}
