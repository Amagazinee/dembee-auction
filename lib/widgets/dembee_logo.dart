import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dembee_logo_mark.dart';

/// Figma лого — assets/images/logo.png эсвэл зохион бүтээсэн тэмдэг
class DembeeLogo extends StatelessWidget {
  const DembeeLogo({
    super.key,
    this.size = 32,
    this.showText = true,
    this.textSize,
    this.compact = false,
  });

  final double size;
  final bool showText;
  final double? textSize;
  final bool compact;

  static const assetPath = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DembeeLogoIcon(size: size),
        if (showText) ...[
          SizedBox(width: compact ? 6 : 8),
          _Wordmark(
            fontSize: textSize ?? size * 0.55,
            compact: compact,
          ),
        ],
      ],
    );
  }
}

/// Зөвхөн дөрвөлжин тэмдэг — PNG эсвэл CustomPainter
class DembeeLogoIcon extends StatelessWidget {
  const DembeeLogoIcon({
    super.key,
    required this.size,
    this.showGlow = false,
  });

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.04;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        DembeeLogo.assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => DembeeLogoMark(
          size: size,
          borderRadius: radius,
          showGlow: showGlow,
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({
    required this.fontSize,
    this.compact = false,
    this.showTagline = false,
  });

  final double fontSize;
  final bool compact;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    if (showTagline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _brandText(fontSize),
          SizedBox(height: fontSize * 0.15),
          Text(
            'AUCTION',
            style: AppTheme.monoStyle.copyWith(
              fontSize: fontSize * 0.32,
              letterSpacing: fontSize * 0.2,
              color: AppTheme.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return _brandText(fontSize);
  }

  Widget _brandText(double fontSize) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE8C547), AppTheme.primary, Color(0xFF9A7A32)],
      ).createShader(bounds),
      child: Text(
        'ДЭМБЭЭ',
        style: AppTheme.headingStyle.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: compact ? 0.8 : 1.2,
          height: 1,
          color: Colors.white,
        ),
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
    final textSize = size * 0.28;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DembeeLogoIcon(size: size, showGlow: true),
        SizedBox(height: size * 0.14),
        _Wordmark(
          fontSize: textSize,
          showTagline: true,
        ),
      ],
    );
  }
}
