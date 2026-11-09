import 'package:egrado/ui/onboarding/onboarding_art.dart';
import 'package:egrado/ui/onboarding/onboarding_view_model.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The welcome tour. [onDone] runs after the last page or "Skip".
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: _OnboardingView(onDone: onDone),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final _pages = PageController();

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next(OnboardingViewModel viewModel) {
    if (viewModel.isLast) {
      widget.onDone();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OnboardingViewModel>();
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(Gap.s),
                child: viewModel.isLast
                    ? const SizedBox(height: 56)
                    : TextButton(
                        onPressed: widget.onDone,
                        child: const Text('Skip'),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: OnboardingViewModel.steps.length,
                onPageChanged: viewModel.goTo,
                itemBuilder: (context, i) {
                  final step = OnboardingViewModel.steps[i];
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: Gap.l),
                    children: [
                      const SizedBox(height: Gap.m),
                      OnboardingArt(i),
                      const SizedBox(height: Gap.xl),
                      Text(step.title, style: text.headlineMedium),
                      const SizedBox(height: Gap.m),
                      Text(
                        step.body,
                        style: text.bodyLarge?.copyWith(
                          fontSize: 21,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _Dots(
              count: OnboardingViewModel.steps.length,
              index: viewModel.index,
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.m),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _next(viewModel),
                  child: Text(viewModel.isLast ? 'Get started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${index + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: i == index ? 28 : 12,
              height: 12,
              decoration: BoxDecoration(
                color: i == index ? AppColors.primary : AppColors.line,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
        ],
      ),
    );
  }
}
