import 'package:egrado/domain/teaching_level.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Asks whether the teacher teaches under DepEd or in college, so the app
/// shows only that kind of grading. Returns null when they back out.
Future<TeachingLevel?> askTeachingLevel(
  BuildContext context, {
  TeachingLevel? current,
}) => showDialog<TeachingLevel>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Where do you teach?'),
    contentPadding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, Gap.m),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'eGrado sets up grading for one or the other. You can change '
            'this later in Account.',
            style: TextStyle(fontSize: 17, color: AppColors.inkMuted),
          ),
          const SizedBox(height: Gap.s),
          for (final level in TeachingLevel.values)
            Padding(
              padding: const EdgeInsets.only(top: Gap.s),
              child: _LevelOption(
                level: level,
                selected: level == current,
                onTap: () => Navigator.pop(context, level),
              ),
            ),
        ],
      ),
    ),
  ),
);

class _LevelOption extends StatelessWidget {
  const _LevelOption({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final TeachingLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.line,
          width: selected ? 2.5 : 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          selected: selected,
          child: Padding(
            padding: const EdgeInsets.all(Gap.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  level.detail,
                  style: const TextStyle(
                    fontSize: 17,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
