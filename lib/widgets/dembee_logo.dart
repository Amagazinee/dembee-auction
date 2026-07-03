import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Figma лого — алтан D + ДЭМБЭЭ
class DembeeLogo extends StatelessWidget {
  const DembeeLogo({
    super.key,
    this.size = 32,
    this.showText = true,
    this.textSize,
  });

  final double size;
  final bool showText;
  final double? textSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8C547), Color(0xFFC9A84C)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.gavel_rounded,
            size: size * 0.55,
            color: AppTheme.primaryForeground,
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            'ДЭМБЭЭ',
            style: AppTheme.headingStyle.copyWith(
              fontSize: textSize ?? size * 0.55,
              color: AppTheme.primary,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}
