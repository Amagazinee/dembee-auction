import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Figma лого — assets/images/logo.png
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

  static const _assetPath = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            _assetPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _PlaceholderIcon(size: size),
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

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

/// Том лого — splash, login hero
class DembeeLogoLarge extends StatelessWidget {
  const DembeeLogoLarge({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.gavel_rounded,
        size: size * 0.7,
        color: AppTheme.primary,
      ),
    );
  }
}
