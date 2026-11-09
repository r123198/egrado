import 'package:egrado/data/auth/auth_repository.dart';
import 'package:egrado/ui/account/account_view_model.dart';
import 'package:egrado/ui/core/messages.dart';
import 'package:egrado/ui/core/navigation.dart';
import 'package:egrado/ui/onboarding/onboarding_view.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

/// The Account tab.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AccountViewModel(
        context.read<AuthRepository>(),
        loadVersion: () async {
          final info = await PackageInfo.fromPlatform();
          return '${info.version} (${info.buildNumber})';
        },
      ),
      child: const _AccountView(),
    );
  }
}

class _AccountView extends StatelessWidget {
  const _AccountView();

  Future<void> _signOut(BuildContext context) async {
    final viewModel = context.read<AccountViewModel>();
    final ok = await confirmAction(
      context,
      title: 'Sign out?',
      message:
          'Your classes and scores stay safely on this phone. '
          'Sign in again to see them.',
      confirmLabel: 'Sign out',
    );
    if (!ok || !context.mounted) return;
    if (!await viewModel.signOut() && context.mounted) {
      showMessage(context, Messages.signOutFailed);
    }
  }

  void _showTour(BuildContext context) {
    openFullScreen<void>(
      context,
      Builder(
        builder: (tourContext) =>
            OnboardingPage(onDone: () => Navigator.pop(tourContext)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AccountViewModel>();
    final user = viewModel.user;
    final text = Theme.of(context).textTheme;
    final version = viewModel.version;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
        children: [
          SurfaceCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    viewModel.initials,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: Gap.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? user?.greetingName ?? 'Teacher',
                        style: text.titleLarge,
                      ),
                      if (user?.email case final email?)
                        Text(
                          email,
                          style: text.bodyLarge?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gap.l),
          BigActionButton(
            icon: Icons.help_outline,
            label: 'How eGrado works',
            detail: 'See the short welcome tour again',
            primary: false,
            onPressed: () => _showTour(context),
          ),
          const SizedBox(height: Gap.s),
          BigActionButton(
            icon: Icons.logout,
            label: 'Sign out',
            primary: false,
            onPressed: () => _signOut(context),
          ),
          if (version != null) ...[
            const SizedBox(height: Gap.l),
            Text(
              'eGrado $version',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}
