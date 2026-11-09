import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/services/photo_service.dart';
import 'package:egrado/services/sheet_reader.dart';
import 'package:egrado/ui/answer_key/answer_key_view_model.dart';
import 'package:egrado/ui/core/loading_scaffold.dart';
import 'package:egrado/ui/core/messages.dart';
import 'package:egrado/ui/scan/photo_source_sheet.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/choice_bubbles.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AnswerKeyPage extends StatelessWidget {
  const AnswerKeyPage(this.examId, {super.key});

  final String examId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AnswerKeyViewModel(
        examId: examId,
        exams: context.read<ExamRepository>(),
        reader: context.read<SheetReader>(),
        photos: context.read<PhotoService>(),
      ),
      child: const _AnswerKeyView(),
    );
  }
}

class _AnswerKeyView extends StatelessWidget {
  const _AnswerKeyView();

  Future<void> _scanKey(BuildContext context) async {
    final viewModel = context.read<AnswerKeyViewModel>();
    final source = await askPhotoSource(context);
    if (source == null) return;
    final outcome = await viewModel.scanKey(source);
    if (!context.mounted) return;
    switch (outcome) {
      case KeyScanCancelled():
        return;
      case KeyScanFailed(:final message):
        showMessage(context, message);
      case KeyScanRead(:final unreadable):
        showMessage(
          context,
          unreadable == 0
              ? 'Answer key read. Please look it over, then save.'
              : '$unreadable answers could not be read. '
                    'They are marked below.',
        );
    }
  }

  Future<void> _save(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (await context.read<AnswerKeyViewModel>().save()) {
      navigator.pop();
    } else if (context.mounted) {
      showMessage(context, Messages.saveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AnswerKeyViewModel>();
    final exam = viewModel.exam;
    if (viewModel.loadFailed) return const LoadErrorScaffold();
    if (viewModel.isLoading) return const LoadingScaffold();
    if (exam == null) return const Scaffold();
    final draft = viewModel.draft;

    return PopScope(
      canPop: !viewModel.isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final leave = await confirmAction(
          context,
          title: 'Leave without saving?',
          message: 'Your changes to the answer key will be lost.',
          confirmLabel: 'Leave',
          destructive: true,
        );
        if (leave) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Answer key')),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
          itemCount: draft.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return _Header(
                title: exam.title,
                isReading: viewModel.isReading,
                onScan: () => _scanKey(context),
              );
            }
            final q = i - 1;
            return _KeyRow(
              question: q,
              choiceCount: exam.choiceCount,
              selected: draft[q],
              needsCheck: viewModel.needsCheck(q),
              onChanged: (c) => viewModel.setAnswer(q, c),
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Gap.m),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${viewModel.setCount} of ${draft.length} answers set',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: Gap.s),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _save(context),
                    child: const Text('Save answer key'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.isReading,
    required this.onScan,
  });

  final String title;
  final bool isReading;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: Gap.s),
          Text(
            'Tap the correct letter for each question — or shade one answer '
            'sheet with the right answers and scan it.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: Gap.m),
          if (isReading)
            const SurfaceCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 4),
                  ),
                  SizedBox(width: Gap.m),
                  Text('Reading the sheet…', style: TextStyle(fontSize: 20)),
                ],
              ),
            )
          else
            BigActionButton(
              icon: Icons.document_scanner_outlined,
              label: 'Scan a filled answer key',
              primary: false,
              onPressed: onScan,
            ),
        ],
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.question,
    required this.choiceCount,
    required this.selected,
    required this.needsCheck,
    required this.onChanged,
  });

  final int question;
  final int choiceCount;
  final int? selected;
  final bool needsCheck;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Gap.xs),
      padding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: 10),
      decoration: needsCheck
          ? BoxDecoration(
              color: AppColors.checkSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.check, width: 1.5),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '${question + 1}.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ChoiceBubbles(
              choiceCount: choiceCount,
              selected: selected,
              questionLabel: 'Question ${question + 1}',
              onChanged: onChanged,
            ),
          ),
          if (needsCheck)
            const Tooltip(
              message: 'Could not read this one',
              child: Icon(Icons.help_outline, color: AppColors.check, size: 30),
            ),
        ],
      ),
    );
  }
}
