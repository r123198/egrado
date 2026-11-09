import 'package:egrado/data/auth/auth_repository.dart';
import 'package:egrado/ui/auth/sign_in_view_model.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/brand_mark.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SignInViewModel(context.read<AuthRepository>()),
      child: const _SignInView(),
    );
  }
}

class _SignInView extends StatefulWidget {
  const _SignInView();

  @override
  State<_SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<_SignInView> {
  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignInViewModel>();
    final text = Theme.of(context).textTheme;
    final creating = viewModel.isCreating;
    final busy = viewModel.isBusy;
    final error = viewModel.error;
    final info = viewModel.info;

    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Gap.m, Gap.l, Gap.m, Gap.xl),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: BrandMark(size: 44),
              ),
              const SizedBox(height: Gap.l),
              Text(
                creating ? 'Create your account' : 'Welcome',
                style: text.headlineMedium,
              ),
              const SizedBox(height: Gap.xs),
              Text(
                creating
                    ? 'Your classes and scores stay on this phone.'
                    : 'Sign in to check papers.',
                style: text.bodyLarge?.copyWith(color: AppColors.inkMuted),
              ),
              const SizedBox(height: Gap.l),
              _GoogleButton(
                onPressed: busy ? null : viewModel.signInWithGoogle,
              ),
              const _OrDivider(),
              if (creating) ...[
                TextField(
                  enabled: !busy,
                  style: const TextStyle(fontSize: 22),
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  onChanged: viewModel.setName,
                  decoration: InputDecoration(
                    labelText: 'Your name',
                    errorText: viewModel.nameError,
                    errorStyle: const TextStyle(fontSize: 17),
                  ),
                ),
                const SizedBox(height: Gap.m),
              ],
              TextField(
                enabled: !busy,
                style: const TextStyle(fontSize: 22),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                onChanged: viewModel.setEmail,
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: viewModel.emailError,
                  errorStyle: const TextStyle(fontSize: 17),
                ),
              ),
              const SizedBox(height: Gap.m),
              TextField(
                enabled: !busy,
                style: const TextStyle(fontSize: 22),
                obscureText: _hidePassword,
                autofillHints: [
                  creating ? AutofillHints.newPassword : AutofillHints.password,
                ],
                textInputAction: TextInputAction.done,
                onChanged: viewModel.setPassword,
                onSubmitted: (_) => viewModel.submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: viewModel.passwordError,
                  errorStyle: const TextStyle(fontSize: 17),
                  suffixIcon: IconButton(
                    iconSize: 28,
                    tooltip: _hidePassword ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: Gap.m),
                NoticeBanner(
                  icon: Icons.error_outline,
                  color: AppColors.wrong,
                  background: AppColors.wrongSoft,
                  text: error,
                ),
              ],
              if (info != null) ...[
                const SizedBox(height: Gap.m),
                NoticeBanner(
                  icon: Icons.mark_email_read_outlined,
                  color: AppColors.correct,
                  background: AppColors.correctSoft,
                  text: info,
                ),
              ],
              const SizedBox(height: Gap.m),
              FilledButton(
                onPressed: busy ? null : viewModel.submit,
                child: busy
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Text(creating ? 'Create account' : 'Sign in'),
              ),
              if (!creating)
                TextButton(
                  onPressed: busy ? null : viewModel.sendPasswordReset,
                  child: const Text('Forgot password?'),
                ),
              const SizedBox(height: Gap.m),
              const Divider(),
              const SizedBox(height: Gap.s),
              Text(
                creating ? 'Already have an account?' : 'New to eGrado?',
                textAlign: TextAlign.center,
                style: text.bodyLarge,
              ),
              OutlinedButton(
                onPressed: busy ? null : viewModel.toggleMode,
                child: Text(creating ? 'Sign in instead' : 'Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.inkMuted, width: 1.5),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'G',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4285F4),
            ),
          ),
          SizedBox(width: Gap.s),
          Flexible(child: Text('Continue with Google')),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: Gap.m),
      child: Row(
        children: [
          Expanded(child: Divider()),
          Flexible(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Gap.s),
              child: Text(
                'or use email',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: AppColors.inkMuted),
              ),
            ),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
  }
}
