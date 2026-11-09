import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/data/repositories/result_repository.dart';
import 'package:egrado/services/photo_service.dart';
import 'package:egrado/services/sheet_reader.dart';
import 'package:egrado/ui/scan/photo_source_sheet.dart';
import 'package:egrado/ui/scan/result_review_view.dart';
import 'package:egrado/ui/scan/scan_session_view_model.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScanSessionPage extends StatelessWidget {
  const ScanSessionPage(this.examId, {super.key});

  final String examId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ScanSessionViewModel(
        examId: examId,
        exams: context.read<ExamRepository>(),
        classes: context.read<ClassRepository>(),
        results: context.read<ResultRepository>(),
        photos: context.read<PhotoService>(),
        reader: context.read<SheetReader>(),
      ),
      child: const _ScanSessionView(),
    );
  }
}

class _ScanSessionView extends StatefulWidget {
  const _ScanSessionView();

  @override
  State<_ScanSessionView> createState() => _ScanSessionViewState();
}

class _ScanSessionViewState extends State<_ScanSessionView> {
  @override
  void initState() {
    super.initState();
    // Go straight to the camera: that's why the teacher tapped "Check papers".
    WidgetsBinding.instance.addPostFrameCallback((_) => _nextPaper());
  }

  /// photo → read → review → (saved: next photo | retake | back: wait).
  Future<void> _nextPaper() async {
    final viewModel = context.read<ScanSessionViewModel>();
    while (mounted) {
      final source = viewModel.source ?? await askPhotoSource(context);
      if (source == null || !mounted) return;
      final reading = await viewModel.captureAndRead(source);
      if (reading == null || !mounted) return;
      final outcome = await Navigator.push<ReviewOutcome>(
        context,
        MaterialPageRoute(
          builder: (_) => ResultReviewPage.scanned(viewModel.examId, reading),
        ),
      );
      if (!mounted) return;
      switch (outcome) {
        case ReviewOutcome.saved:
          viewModel.recordSaved();
          showMessage(context, 'Score saved.');
        case ReviewOutcome.retake:
          break;
        case null:
          return; // Back button: stay here so the teacher can decide.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ScanSessionViewModel>();
    final exam = viewModel.exam;
    if (exam == null) return const Scaffold();
    final step = viewModel.step;
    final classSize = viewModel.classSize;
    final checked = viewModel.checkedCount;
    final savedNow = viewModel.savedThisSession;

    return Scaffold(
      appBar: AppBar(title: Text(exam.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, Gap.xl),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classSize > 0 ? '$checked of $classSize' : '$checked',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                Text(
                  'papers checked${savedNow > 0 ? '  ·  $savedNow just now' : ''}',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.l),
          ...switch (step) {
            ScanReading() => [const _ReadingIndicator()],
            ScanFailed(:final message) => [
              NoticeBanner(
                icon: Icons.error_outline,
                color: AppColors.wrong,
                background: AppColors.wrongSoft,
                text: message,
              ),
              const SizedBox(height: Gap.m),
              const PhotoTips(),
            ],
            ScanWaiting() => [const PhotoTips()],
          },
        ],
      ),
      bottomNavigationBar: step is ScanReading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Gap.m),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.photo_camera_outlined, size: 28),
                      label: Text(
                        step is ScanFailed ? 'Try again' : 'Check next paper',
                      ),
                      onPressed: viewModel.isBusy ? null : _nextPaper,
                    ),
                    const SizedBox(height: Gap.s),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("I'm finished"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ReadingIndicator extends StatelessWidget {
  const _ReadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: Gap.l),
        const SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(strokeWidth: 6),
        ),
        const SizedBox(height: Gap.m),
        Text(
          'Reading the answers…',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}
