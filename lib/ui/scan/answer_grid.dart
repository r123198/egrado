import 'package:egrado/omr/sheet_layout.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/choice_bubbles.dart';
import 'package:flutter/material.dart';

enum _Verdict { correct, wrong, check }

/// Every question as a tile: right (green ✓), wrong (red ✗, shows the
/// correct letter) or needs a look (amber ?). Tap a tile to change it.
class AnswerGrid extends StatelessWidget {
  const AnswerGrid({
    super.key,
    required this.answers,
    required this.answerKey,
    required this.choiceCount,
    required this.needsCheck,
    required this.onChanged,
  });

  final List<int?> answers;
  final List<int?> answerKey;
  final int choiceCount;
  final Set<int> needsCheck;
  final void Function(int question, int? choice) onChanged;

  Future<void> _edit(BuildContext context, int q) async {
    final result = await showModalBottomSheet<({int? choice})>(
      context: context,
      builder: (_) => _EditAnswerSheet(
        question: q,
        current: answers[q],
        choiceCount: choiceCount,
      ),
    );
    if (result != null) onChanged(q, result.choice);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 150).floor().clamp(2, 6);
        final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var q = 0; q < answers.length; q++)
              SizedBox(
                width: width,
                child: _AnswerTile(
                  question: q,
                  answer: answers[q],
                  correct: answerKey[q],
                  verdict: needsCheck.contains(q)
                      ? _Verdict.check
                      : answers[q] != null && answers[q] == answerKey[q]
                      ? _Verdict.correct
                      : _Verdict.wrong,
                  onTap: () => _edit(context, q),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.question,
    required this.answer,
    required this.correct,
    required this.verdict,
    required this.onTap,
  });

  final int question;
  final int? answer;
  final int? correct;
  final _Verdict verdict;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon, spoken) = switch (verdict) {
      _Verdict.correct => (
        AppColors.correct,
        AppColors.correctSoft,
        Icons.check_rounded,
        'correct',
      ),
      _Verdict.wrong => (
        AppColors.wrong,
        AppColors.wrongSoft,
        Icons.close_rounded,
        'wrong',
      ),
      _Verdict.check => (
        AppColors.check,
        AppColors.checkSoft,
        Icons.help_outline_rounded,
        'please check',
      ),
    };
    final answer = this.answer;
    final correct = this.correct;
    final letter = answer == null ? '—' : kChoiceLetters[answer];
    final correctLetter = verdict == _Verdict.wrong && correct != null
        ? kChoiceLetters[correct]
        : null;
    return Semantics(
      button: true,
      label:
          'Question ${question + 1}, answer '
          '${answer == null ? 'blank' : letter}, $spoken',
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: color,
            width: verdict == _Verdict.check ? 2.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${question + 1}.',
                  style: const TextStyle(
                    fontSize: 17,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (correctLetter != null) ...[
                  const Icon(
                    Icons.arrow_right_alt_rounded,
                    size: 22,
                    color: AppColors.correct,
                  ),
                  Text(
                    correctLetter,
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.correct,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const Spacer(),
                Icon(icon, color: color, size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditAnswerSheet extends StatelessWidget {
  const _EditAnswerSheet({
    required this.question,
    required this.current,
    required this.choiceCount,
  });

  final int question;
  final int? current;
  final int choiceCount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${question + 1}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Gap.xs),
            Text(
              'Tap the letter the student shaded.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: Gap.m),
            ChoiceBubbles(
              choiceCount: choiceCount,
              selected: current,
              questionLabel: 'Question ${question + 1}',
              onChanged: (c) => Navigator.pop(context, (choice: c)),
            ),
            const SizedBox(height: Gap.m),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, (choice: null)),
              child: const Text('No answer / not valid'),
            ),
          ],
        ),
      ),
    );
  }
}
