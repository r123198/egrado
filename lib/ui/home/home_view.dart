import 'package:egrado/data/repositories/class_repository.dart';
import 'package:egrado/domain/overviews.dart';
import 'package:egrado/ui/class_detail/class_view.dart';
import 'package:egrado/ui/core/loading_scaffold.dart';
import 'package:egrado/ui/core/messages.dart';
import 'package:egrado/ui/core/navigation.dart';
import 'package:egrado/ui/home/home_view_model.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Classes tab.
class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeViewModel(context.read<ClassRepository>()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  Future<void> _addClass(BuildContext context) async {
    final viewModel = context.read<HomeViewModel>();
    final name = await askForText(
      context,
      title: 'New class',
      label: 'Class name, e.g. Grade 7 – Rizal',
      confirmLabel: 'Add class',
    );
    if (name == null || !context.mounted) return;
    final id = await viewModel.addClass(name);
    if (!context.mounted) return;
    if (id == null) {
      showMessage(context, Messages.saveFailed);
      return;
    }
    await openInTab<void>(context, ClassPage(id));
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    if (viewModel.loadFailed) return const LoadErrorScaffold();
    if (viewModel.isLoading) return const LoadingScaffold();
    final classes = viewModel.classes;
    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
        children: [
          if (classes.isEmpty)
            const EmptyState(
              icon: Icons.groups_outlined,
              title: 'No classes yet',
              message: 'Add your first class to start checking papers.',
            ),
          for (final c in classes) ...[
            _ClassCard(overview: c),
            const SizedBox(height: Gap.s),
          ],
          const SizedBox(height: Gap.m),
          BigActionButton(
            icon: Icons.add,
            label: 'Add a class',
            primary: classes.isEmpty,
            onPressed: () => _addClass(context),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.overview});

  final ClassOverview overview;

  @override
  Widget build(BuildContext context) {
    final students = overview.studentCount;
    final tests = overview.testCount;
    return SurfaceCard(
      onTap: () => openInTab<void>(context, ClassPage(overview.id)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overview.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  '$students ${students == 1 ? 'student' : 'students'}'
                  '  ·  $tests ${tests == 1 ? 'test' : 'tests'}',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.inkMuted),
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
