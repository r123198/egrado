import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/data/repositories/exam_repository.dart';
import 'package:egrado/domain/overviews.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/ui/class_detail/class_view_model.dart';
import 'package:egrado/ui/core/loading_scaffold.dart';
import 'package:egrado/ui/core/messages.dart';
import 'package:egrado/ui/core/navigation.dart';
import 'package:egrado/ui/exam/exam_view.dart';
import 'package:egrado/ui/exam_form/exam_form_view.dart';
import 'package:egrado/ui/grades/grades_view.dart';
import 'package:egrado/ui/students/students_view.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClassPage extends StatelessWidget {
  const ClassPage(this.classId, {super.key});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ClassViewModel(
        classId,
        context.read<ClassRepository>(),
        context.read<ExamRepository>(),
      ),
      child: const _ClassView(),
    );
  }
}

class _ClassView extends StatelessWidget {
  const _ClassView();

  Future<void> _rename(BuildContext context, SchoolClass c) async {
    final viewModel = context.read<ClassViewModel>();
    final name = await askForText(
      context,
      title: 'Rename class',
      label: 'Class name',
      initial: c.name,
    );
    if (name == null || !context.mounted) return;
    if (!await viewModel.rename(name) && context.mounted) {
      showMessage(context, Messages.saveFailed);
    }
  }

  Future<void> _delete(BuildContext context, SchoolClass c) async {
    final viewModel = context.read<ClassViewModel>();
    final ok = await confirmAction(
      context,
      title: 'Delete ${c.name}?',
      message:
          'This removes the class, its students, and all test scores. '
          'This cannot be undone.',
      confirmLabel: 'Delete class',
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
    final viewModel = context.watch<ClassViewModel>();
    if (viewModel.loadFailed) return const LoadErrorScaffold();
    if (viewModel.isLoading) return const LoadingScaffold();
    final schoolClass = viewModel.schoolClass;
    if (schoolClass == null) return const Scaffold();
    final students = viewModel.studentCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(schoolClass.name),
        actions: [
          PopupMenuButton<VoidCallback>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => action(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: () => _rename(context, schoolClass),
                child: const Text(
                  'Rename class',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              PopupMenuItem(
                value: () => _delete(context, schoolClass),
                child: const Text(
                  'Delete class',
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
          SurfaceCard(
            onTap: () =>
                openInTab<void>(context, StudentsPage(viewModel.classId)),
            child: Row(
              children: [
                const Icon(
                  Icons.groups_outlined,
                  size: 36,
                  color: AppColors.primary,
                ),
                const SizedBox(width: Gap.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Students',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        students == 0
                            ? 'Add your class list first'
                            : '$students in this class',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 32,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.s),
          SurfaceCard(
            onTap: () =>
                openInTab<void>(context, GradesPage(viewModel.classId)),
            child: Row(
              children: [
                const Icon(
                  Icons.table_view_outlined,
                  size: 36,
                  color: AppColors.primary,
                ),
                const SizedBox(width: Gap.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grades',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Term grades and your E-Class Record',
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 32,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
          ),
          const SectionTitle('Tests'),
          BigActionButton(
            icon: Icons.add,
            label: 'New test',
            detail: 'Set up questions and the answer key',
            onPressed: () => openFullScreen<void>(
              context,
              ExamFormPage(classId: viewModel.classId),
            ),
          ),
          const SizedBox(height: Gap.m),
          if (viewModel.exams.isEmpty)
            const EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No tests yet',
              message:
                  'Create a test, print the answer sheets, '
                  'then scan the papers.',
            ),
          for (final overview in viewModel.exams) ...[
            _ExamCard(overview: overview, classSize: students),
            const SizedBox(height: Gap.s),
          ],
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.overview, required this.classSize});

  final ExamOverview overview;
  final int classSize;

  @override
  Widget build(BuildContext context) {
    final exam = overview.exam;
    final checked = overview.checkedCount;
    return SurfaceCard(
      onTap: () => openFullScreen<void>(context, ExamPage(exam.id)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exam.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: Gap.xs),
                Text(
                  classSize > 0
                      ? '$checked of $classSize papers checked'
                      : '$checked papers checked',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.inkMuted),
                ),
                if (!exam.hasCompleteKey)
                  const Padding(
                    padding: EdgeInsets.only(top: Gap.xs),
                    child: Text(
                      'Answer key not finished',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.check,
                      ),
                    ),
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
