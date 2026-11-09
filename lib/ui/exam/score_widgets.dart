import 'package:egrado/ui/exam/exam_view_model.dart';
import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/common.dart';
import 'package:flutter/material.dart';

class ScoreSummaryCard extends StatelessWidget {
  const ScoreSummaryCard({super.key, required this.summary});

  final ScoreSummary summary;

  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String label) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          Text(
            label,
            style: const TextStyle(fontSize: 17, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
    final s = summary;
    return SurfaceCard(
      child: Row(
        children: [
          stat(
            s.classSize > 0 ? '${s.checked}/${s.classSize}' : '${s.checked}',
            'checked',
          ),
          stat(s.average?.toStringAsFixed(1) ?? '—', 'average'),
          stat(s.highest?.toString() ?? '—', 'highest of ${s.total}'),
        ],
      ),
    );
  }
}

class ScoreLineTile extends StatelessWidget {
  const ScoreLineTile({
    super.key,
    required this.line,
    required this.total,
    required this.onTap,
  });

  final ScoreLine line;
  final int total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final score = line.score;
    final checked = score != null;
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: 10),
      color: checked ? AppColors.surface : AppColors.paper,
      child: Row(
        children: [
          NumberBadge(line.number, muted: !checked),
          const SizedBox(width: Gap.m),
          Expanded(
            child: Text(
              line.name ?? 'Not in class list',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: checked ? AppColors.ink : AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: Gap.s),
          if (score != null)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$score',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' / $total',
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            const Text(
              'Not checked',
              style: TextStyle(fontSize: 17, color: AppColors.inkMuted),
            ),
        ],
      ),
    );
  }
}
