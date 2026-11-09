import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/domain/school_class.dart';
import 'package:egrado/ui/core/loading_scaffold.dart';
import 'package:egrado/ui/core/messages.dart';
import 'package:egrado/ui/core/navigation.dart';
import 'package:egrado/ui/students/add_students_view.dart';
import 'package:egrado/ui/students/students_view_model.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StudentsPage extends StatelessWidget {
  const StudentsPage(this.classId, {super.key});

  final String classId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          StudentsViewModel(classId, context.read<ClassRepository>()),
      child: const _StudentsView(),
    );
  }
}

enum _StudentAction { rename, remove }

class _StudentsView extends StatelessWidget {
  const _StudentsView();

  Future<void> _edit(BuildContext context, Student s) async {
    final viewModel = context.read<StudentsViewModel>();
    final action = await showModalBottomSheet<_StudentAction>(
      context: context,
      builder: (_) => _StudentActions(student: s),
    );
    if (action == null || !context.mounted) return;
    final bool ok;
    switch (action) {
      case _StudentAction.rename:
        final name = await askForText(
          context,
          title: 'Student ${s.number}',
          label: 'Full name',
          initial: s.name,
        );
        if (name == null) return;
        ok = await viewModel.rename(s.number, name);
      case _StudentAction.remove:
        final confirmed = await confirmAction(
          context,
          title: 'Remove ${s.name}?',
          message:
              'Scores already saved for number ${s.number} are kept, '
              'but will show without a name.',
          confirmLabel: 'Remove',
          destructive: true,
        );
        if (!confirmed) return;
        ok = await viewModel.remove(s.number);
    }
    if (!ok && context.mounted) showMessage(context, Messages.saveFailed);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StudentsViewModel>();
    if (viewModel.loadFailed) return const LoadErrorScaffold();
    if (viewModel.isLoading) return const LoadingScaffold();
    final students = viewModel.students;
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
        children: [
          Text(
            'Each student shades their number on the answer sheet, '
            'so their score is saved under their name automatically.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: Gap.m),
          BigActionButton(
            icon: Icons.person_add_alt_1_outlined,
            label: 'Add students',
            detail: 'Type or paste names, one per line',
            primary: students.isEmpty,
            onPressed: viewModel.isFull
                ? null
                : () => openInTab<void>(
                    context,
                    AddStudentsPage(viewModel.classId),
                  ),
          ),
          const SizedBox(height: Gap.m),
          if (students.isEmpty)
            const EmptyState(
              icon: Icons.groups_outlined,
              title: 'No students yet',
              message: 'Add your class list. You only need to do this once.',
            ),
          for (final s in students)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.s),
              child: SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.m,
                  vertical: Gap.s,
                ),
                onTap: () => _edit(context, s),
                child: Row(
                  children: [
                    NumberBadge(s.number),
                    const SizedBox(width: Gap.m),
                    Expanded(
                      child: Text(
                        s.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.edit_outlined, color: AppColors.inkMuted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StudentActions extends StatelessWidget {
  const _StudentActions({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${student.number}.  ${student.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Gap.m),
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Change name'),
              onPressed: () => Navigator.pop(context, _StudentAction.rename),
            ),
            const SizedBox(height: Gap.s),
            OutlinedButton.icon(
              icon: const Icon(Icons.person_remove_outlined),
              label: const Text('Remove from class'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.wrong,
                side: const BorderSide(color: AppColors.wrong, width: 2),
              ),
              onPressed: () => Navigator.pop(context, _StudentAction.remove),
            ),
          ],
        ),
      ),
    );
  }
}
