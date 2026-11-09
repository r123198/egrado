import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/domain/overviews.dart';
import 'package:egrado/ui/core/loading_scaffold.dart';
import 'package:egrado/ui/core/navigation.dart';
import 'package:egrado/ui/exam/exam_view.dart';
import 'package:egrado/ui/exam_form/exam_form_view.dart';
import 'package:egrado/ui/shell/shell_view_model.dart';
import 'package:egrado/ui/tests_tab/all_tests_view_model.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/brand_mark.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Tests tab — where a teacher lands after signing in.
class AllTestsPage extends StatelessWidget {
  const AllTestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AllTestsViewModel(
        context.read<ExamRepository>(),
        context.read<ClassRepository>(),
      ),
      child: const _AllTestsView(),
    );
  }
}

class _AllTestsView extends StatelessWidget {
  const _AllTestsView();

  Future<void> _newTest(BuildContext context) async {
    final viewModel = context.read<AllTestsViewModel>();
    final classes = viewModel.classes;
    final classId = classes.length == 1
        ? classes.single.id
        : await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            builder: (_) => _ClassChooser(classes: classes),
          );
    if (classId == null || !context.mounted) return;
    await openFullScreen<void>(context, ExamFormPage(classId: classId));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AllTestsViewModel>();
    if (viewModel.loadFailed) return const LoadErrorScaffold();
    if (viewModel.isLoading) return const LoadingScaffold();
    final tests = viewModel.tests;

    return Scaffold(
      appBar: AppBar(title: const BrandMark()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
        children: [
          Text('My tests', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: Gap.m),
          if (viewModel.hasClasses)
            BigActionButton(
              icon: Icons.add,
              label: 'New test',
              detail: 'Set up questions and the answer key',
              onPressed: () => _newTest(context),
            )
          else ...[
            const EmptyState(
              icon: Icons.groups_outlined,
              title: 'Start with a class',
              message:
                  'Add your class and its students first. Then make a test '
                  'for them here.',
            ),
            BigActionButton(
              icon: Icons.groups_outlined,
              label: 'Go to Classes',
              onPressed: () =>
                  context.read<ShellViewModel>().select(AppTab.classes),
            ),
          ],
          const SizedBox(height: Gap.m),
          if (viewModel.hasClasses && tests.isEmpty)
            const EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No tests yet',
              message:
                  'Make a test, print the answer sheets, then check the '
                  'papers with your camera.',
            ),
          for (final overview in tests) ...[
            _TestCard(overview: overview),
            const SizedBox(height: Gap.s),
          ],
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.overview});

  final ExamOverview overview;

  @override
  Widget build(BuildContext context) {
    final exam = overview.exam;
    final checked = overview.checkedCount;
    final size = overview.classSize;
    final done = size > 0 && checked >= size;
    final muted = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(color: AppColors.inkMuted);
    return SurfaceCard(
      onTap: () => openFullScreen<void>(context, ExamPage(exam.id)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exam.title, style: Theme.of(context).textTheme.titleLarge),
                Text(overview.className, style: muted),
                const SizedBox(height: Gap.xs),
                if (!exam.hasCompleteKey)
                  const _Status(
                    icon: Icons.vpn_key_outlined,
                    text: 'Answer key not finished',
                    color: AppColors.check,
                  )
                else if (done)
                  const _Status(
                    icon: Icons.check_circle_outline,
                    text: 'All papers checked',
                    color: AppColors.correct,
                  )
                else
                  Text(
                    size > 0
                        ? '$checked of $size papers checked'
                        : '$checked papers checked',
                    style: muted,
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 32, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: Gap.xs),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClassChooser extends StatelessWidget {
  const _ClassChooser({required this.classes});

  final List<ClassOverview> classes;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
        children: [
          Text(
            'Which class is this test for?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: Gap.m),
          for (final c in classes)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.s),
              child: SurfaceCard(
                onTap: () => Navigator.pop(context, c.id),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${c.studentCount} students',
                      style: const TextStyle(
                        fontSize: 17,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
