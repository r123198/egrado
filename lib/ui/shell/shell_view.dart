import 'package:egrado/ui/account/account_view.dart';
import 'package:egrado/ui/home/home_view.dart';
import 'package:egrado/ui/shell/shell_view_model.dart';
import 'package:egrado/ui/tests_tab/all_tests_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The signed-in app: Tests · Classes · Account tabs along the bottom.
/// Each tab keeps its own history, so the tab bar stays visible while
/// moving around inside a tab.
class ShellPage extends StatelessWidget {
  const ShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShellViewModel(),
      child: const _ShellView(),
    );
  }
}

class _ShellView extends StatefulWidget {
  const _ShellView();

  @override
  State<_ShellView> createState() => _ShellViewState();
}

class _ShellViewState extends State<_ShellView> {
  final _navigators = {
    for (final tab in AppTab.values) tab: GlobalKey<NavigatorState>(),
  };

  static const _roots = {
    AppTab.tests: AllTestsPage(),
    AppTab.classes: ClassesPage(),
    AppTab.account: AccountPage(),
  };

  void _select(ShellViewModel viewModel, AppTab tab) {
    if (viewModel.select(tab)) {
      _navigators[tab]?.currentState?.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ShellViewModel>();
    final current = viewModel.tab;
    return NavigatorPopHandler<Object?>(
      onPopWithResult: (_) => _navigators[current]?.currentState?.maybePop(),
      child: Scaffold(
        body: IndexedStack(
          index: current.index,
          children: [
            for (final tab in AppTab.values)
              Navigator(
                key: _navigators[tab],
                onGenerateRoute: (_) =>
                    MaterialPageRoute<void>(builder: (_) => _roots[tab]!),
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: current.index,
          onDestinationSelected: (i) => _select(viewModel, AppTab.values[i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Tests',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'Classes',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
