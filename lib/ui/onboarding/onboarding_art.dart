import 'package:egrado/ui/theme/app_theme.dart';
import 'package:egrado/ui/widgets/brand_mark.dart';
import 'package:flutter/material.dart';

/// Simple drawings for each tour page, built from the app's own shapes.
class OnboardingArt extends StatelessWidget {
  const OnboardingArt(this.index, {super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: 220,
        child: Center(
          child: switch (index) {
            0 => const BrandMark(size: 120, showName: false),
            1 => const _Sheet(),
            2 => const _Scanning(),
            _ => const _Score(),
          },
        ),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  /// Which bubble is shaded in each row of the drawing.
  static const _filled = {0: 1, 1: 3, 2: 0, 3: 2};

  @override
  Widget build(BuildContext context) {
    Widget bubble(bool on) => Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? AppColors.ink : AppColors.surface,
        border: Border.all(color: AppColors.ink, width: 2),
      ),
    );
    Widget corner() => Container(width: 16, height: 16, color: AppColors.ink);
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [corner(), corner()],
          ),
          for (var row = 0; row < 4; row++)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (var c = 0; c < 4; c++) bubble(_filled[row] == c)],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [corner(), corner()],
          ),
        ],
      ),
    );
  }
}

class _Scanning extends StatelessWidget {
  const _Scanning();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(angle: -0.08, child: const _Sheet()),
        Container(
          width: 210,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary, width: 5),
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_camera_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }
}

class _Score extends StatelessWidget {
  const _Score();

  @override
  Widget build(BuildContext context) {
    Widget row(String name, String score) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.correct, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            score,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row('Ana', '48/50'),
          row('Ben', '45/50'),
          row('Lea', '50/50'),
        ],
      ),
    );
  }
}
