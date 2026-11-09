import 'package:egrado/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// The eGrado logo mark (from assets/icons), optionally with the name.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 36, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final mark = Image.asset(
      'assets/branding/egrado_mark.png',
      width: size,
      height: size * 798 / 1038,
      color: AppColors.ink,
      semanticLabel: showName ? null : 'eGrado',
    );
    if (!showName) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.3),
        Text(
          'eGrado',
          // A logo keeps its size; the rest of the app scales with the
          // phone's text setting.
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: size * 0.7,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
