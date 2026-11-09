import 'package:egrado/ui/core/view_model.dart';

/// One page of the welcome tour.
class OnboardingStep {
  const OnboardingStep({required this.title, required this.body});

  final String title;
  final String body;
}

class OnboardingViewModel extends ViewModel {
  static const steps = [
    OnboardingStep(
      title: 'Check papers in seconds',
      body:
          'eGrado reads bubble answer sheets with your phone camera and '
          'saves every score for you. No more typing grades.',
    ),
    OnboardingStep(
      title: '1. Print the answer sheets',
      body:
          'Make a test, set the answer key, and print. Each student can get '
          'a sheet with their name and number already filled in.',
    ),
    OnboardingStep(
      title: '2. Take a photo of each paper',
      body:
          'The score appears right away. Anything unclear is marked in '
          'yellow so you can fix it with one tap.',
    ),
    OnboardingStep(
      title: '3. Your grades, ready',
      body:
          'Scores are saved on this phone, even without internet. Send them '
          'to Excel whenever you need them.',
    ),
  ];

  int _index = 0;

  int get index => _index;
  bool get isLast => _index == steps.length - 1;
  OnboardingStep get step => steps[_index];

  void goTo(int index) {
    if (index == _index || index < 0 || index >= steps.length) return;
    _index = index;
    notifyListeners();
  }
}
