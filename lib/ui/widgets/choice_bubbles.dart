import 'package:egrado/omr/sheet_layout.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A row of large lettered circles, like the bubbles on the paper.
/// Tapping the selected one again clears it.
class ChoiceBubbles extends StatelessWidget {
  const ChoiceBubbles({
    super.key,
    required this.choiceCount,
    required this.selected,
    required this.onChanged,
    this.questionLabel,
  });

  final int choiceCount;
  final int? selected;
  final ValueChanged<int?> onChanged;

  /// For screen readers, e.g. "Question 4".
  final String? questionLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var c = 0; c < choiceCount; c++)
          _Bubble(
            letter: kChoiceLetters[c],
            isSelected: selected == c,
            semanticLabel: '${questionLabel ?? ''} choice ${kChoiceLetters[c]}',
            onTap: () => onChanged(selected == c ? null : c),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.letter,
    required this.isSelected,
    required this.semanticLabel,
    required this.onTap,
  });

  final String letter;
  final bool isSelected;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        shape: CircleBorder(
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.inkMuted,
            width: 2,
          ),
        ),
        color: isSelected ? AppColors.primary : AppColors.surface,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 58,
            height: 58,
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
