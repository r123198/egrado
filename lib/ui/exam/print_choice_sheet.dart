import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';

/// Pops `true` for name-printed sheets, `false` for blank ones.
class PrintChoiceSheet extends StatelessWidget {
  const PrintChoiceSheet({super.key});

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
              'Print answer sheets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Gap.m),
            BigActionButton(
              icon: Icons.badge_outlined,
              label: 'One per student',
              detail: 'Name and number already printed — fewest mistakes',
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: Gap.s),
            BigActionButton(
              icon: Icons.description_outlined,
              label: 'Blank sheets',
              detail: 'Students write and shade their own number',
              primary: false,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }
}
