import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/data/repositories/result_repository.dart';
import 'package:egrado/omr/omr_reading.dart';
import 'package:egrado/ui/core/loading_scaffold.dart';
import 'package:egrado/ui/core/messages.dart';
import 'package:egrado/ui/scan/answer_grid.dart';
import 'package:egrado/ui/scan/result_review_view_model.dart';
import 'package:egrado/ui/scan/student_picker.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// What the teacher decided on the review screen of a fresh scan.
enum ReviewOutcome { saved, retake }

class ResultReviewPage extends StatelessWidget {
  /// Review a paper that was just scanned; pops a [ReviewOutcome].
  const ResultReviewPage.scanned(
    this.examId,
    OmrReading this.reading, {
    super.key,
  }) : savedStudent = null;

  /// Open a score that is already saved.
  const ResultReviewPage.saved(this.examId, int this.savedStudent, {super.key})
    : reading = null;

  final String examId;
  final OmrReading? reading;
  final int? savedStudent;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final exams = context.read<ExamRepository>();
        final classes = context.read<ClassRepository>();
        final results = context.read<ResultRepository>();
        return switch ((reading, savedStudent)) {
          (final reading?, _) => ResultReviewViewModel.scanned(
            examId: examId,
            reading: reading,
            exams: exams,
            classes: classes,
            results: results,
          ),
          (null, final student?) => ResultReviewViewModel.saved(
            examId: examId,
            savedStudent: student,
            exams: exams,
            classes: classes,
            results: results,
          ),
          (null, null) => throw ArgumentError('Nothing to review'),
        };
      },
      child: const _ResultReviewView(),
    );
  }
}

class _ResultReviewView extends StatelessWidget {
  const _ResultReviewView();

  Future<void> _chooseStudent(BuildContext context) async {
    final viewModel = context.read<ResultReviewViewModel>();
    final schoolClass = viewModel.schoolClass;
    if (schoolClass == null) return;
    final number = await pickStudent(
      context,
      schoolClass: schoolClass,
      alreadyChecked: viewModel.checkedNumbers,
    );
    if (number != null) viewModel.chooseStudent(number);
  }

  Future<void> _save(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (await context.read<ResultReviewViewModel>().save()) {
      navigator.pop(ReviewOutcome.saved);
    } else if (context.mounted) {
      showMessage(context, Messages.saveFailed);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final viewModel = context.read<ResultReviewViewModel>();
    final ok = await confirmAction(
      context,
      title: 'Delete this score?',
      message: 'You can scan the paper again later.',
      confirmLabel: 'Delete score',
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

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ResultReviewViewModel>();
    if (viewModel.loadFailed) return const LoadErrorScaffold();
    if (viewModel.isLoading) return const LoadingScaffold();
    final exam = viewModel.exam;
    if (exam == null) return const Scaffold();
    final needsCheck = viewModel.needsCheck;
    final replaced = viewModel.replacedScore;

    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.isNewScan ? 'Check this paper' : 'Saved score'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
        children: [
          _StudentCard(
            number: viewModel.studentNumber,
            name: viewModel.student?.name,
            onChoose: () => _chooseStudent(context),
          ),
          if (replaced != null) ...[
            const SizedBox(height: Gap.s),
            NoticeBanner(
              icon: Icons.info_outline,
              color: AppColors.primary,
              background: AppColors.primarySoft,
              text:
                  'Already checked before ($replaced/${viewModel.total}). '
                  'Saving replaces that score.',
            ),
          ],
          const SizedBox(height: Gap.m),
          _ScoreHero(
            score: viewModel.score,
            total: viewModel.total,
            percent: viewModel.percent,
          ),
          if (needsCheck.isNotEmpty) ...[
            const SizedBox(height: Gap.m),
            NoticeBanner(
              icon: Icons.help_outline_rounded,
              text:
                  '${needsCheck.length} '
                  '${needsCheck.length == 1 ? 'answer needs' : 'answers need'}'
                  ' a quick look. Tap the yellow boxes to fix them.',
            ),
          ],
          const SectionTitle('Answers'),
          AnswerGrid(
            answers: viewModel.answers,
            answerKey: exam.answerKey,
            choiceCount: exam.choiceCount,
            needsCheck: needsCheck,
            onChanged: viewModel.setAnswer,
          ),
          if (!viewModel.isNewScan) ...[
            const SizedBox(height: Gap.l),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete this score'),
              style: TextButton.styleFrom(foregroundColor: AppColors.wrong),
              onPressed: () => _delete(context),
            ),
          ],
        ],
      ),
      bottomNavigationBar: _BottomActions(
        isNewScan: viewModel.isNewScan,
        canSave: viewModel.canSave,
        onRetake: () => Navigator.pop(context, ReviewOutcome.retake),
        onSave: () => _save(context),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.number,
    required this.name,
    required this.onChoose,
  });

  final int? number;
  final String? name;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final number = this.number;
    final name = this.name;
    if (number == null || name == null) {
      final problem = number == null
          ? 'The student number could not be read.'
          : 'Number $number is not in your class list.';
      return SurfaceCard(
        color: AppColors.checkSoft,
        borderColor: AppColors.check,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person_search_outlined,
                  color: AppColors.check,
                  size: 32,
                ),
                const SizedBox(width: Gap.s),
                Expanded(
                  child: Text(
                    problem,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.check,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.m),
            FilledButton.icon(
              icon: const Icon(Icons.touch_app_outlined),
              label: const Text('Choose the student'),
              onPressed: onChoose,
            ),
          ],
        ),
      );
    }
    return SurfaceCard(
      child: Row(
        children: [
          NumberBadge(number),
          const SizedBox(width: Gap.m),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          TextButton(onPressed: onChoose, child: const Text('Change')),
        ],
      ),
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({
    required this.score,
    required this.total,
    required this.percent,
  });

  final int score;
  final int total;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Score $score out of $total, $percent percent',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$score',
            style: Theme.of(context).textTheme.displayMedium
                ?.copyWith(fontSize: 88, color: AppColors.primary),
          ),
          const SizedBox(width: Gap.s),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'out of $total\n$percent%',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: AppColors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.isNewScan,
    required this.canSave,
    required this.onRetake,
    required this.onSave,
  });

  final bool isNewScan;
  final bool canSave;
  final VoidCallback onRetake;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line, width: 1.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, Gap.s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.check, size: 28),
                label: Text(
                  !canSave
                      ? 'Choose the student first'
                      : isNewScan
                      ? 'Save score'
                      : 'Save changes',
                ),
                onPressed: canSave ? onSave : null,
              ),
              if (isNewScan)
                TextButton.icon(
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Retake photo'),
                  onPressed: onRetake,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
