import 'package:egrado/domain/school_class.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';

/// Lets the teacher tap the right student when the number on the paper
/// could not be read. Returns the chosen student number.
Future<int?> pickStudent(
  BuildContext context, {
  required SchoolClass schoolClass,
  required Set<int> alreadyChecked,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
        children: [
          Text(
            'Whose paper is this?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: Gap.m),
          if (schoolClass.students.isEmpty)
            const EmptyState(
              icon: Icons.groups_outlined,
              title: 'No students in this class',
              message: 'Add your class list on the Students page first.',
            ),
          for (final s in schoolClass.students)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.xs),
              child: SurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gap.m,
                  vertical: 10,
                ),
                onTap: () => Navigator.pop(context, s.number),
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
                    if (alreadyChecked.contains(s.number))
                      const Text(
                        'checked',
                        style: TextStyle(
                          fontSize: 17,
                          color: AppColors.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
