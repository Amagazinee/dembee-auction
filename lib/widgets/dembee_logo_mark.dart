import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ДЭМБЭЭ брэнд тэмдэг — Figma Asset_1.png байхгүй үед CustomPainter
class DembeeLogoMark extends StatelessWidget {
  const DembeeLogoMark({
    super.key,
    required this.size,
    this.borderRadius,
    this.showGlow = false,
  });

  final double size;
  final double? borderRadius;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size * 0.12;

    Widget mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DembeeLogoMarkPainter(borderRadius: radius),
      ),
    );

    if (showGlow) {
      mark = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.35),
              blurRadius: size * 0.35,
              spreadRadius: size * 0.02,
            ),
          ],
        ),
        child: mark,
      );
    }

    return mark;
  }
}

class _DembeeLogoMarkPainter extends CustomPainter {
  _DembeeLogoMarkPainter({required this.borderRadius});

  final double borderRadius;

  static const _goldLight = Color(0xFFE8C547);
  static const _gold = AppTheme.primary;
  static const _goldDark = Color(0xFF9A7A32);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E1C18), Color(0xFF0F0F12)],
      ).createShader(rect);
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.04
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_goldLight, _gold, _goldDark],
      ).createShader(rect);
    canvas.drawRRect(rrect.deflate(size.shortestSide * 0.02), borderPaint);

    _drawGavel(canvas, size);
  }

  void _drawGavel(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-math.pi / 6);

    final goldGradient = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_goldLight, _gold, _goldDark],
      ).createShader(Rect.fromCenter(
        center: Offset.zero,
        width: s * 0.7,
        height: s * 0.7,
      ));

    final head = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(-s * 0.04, -s * 0.14),
        width: s * 0.52,
        height: s * 0.2,
      ),
      Radius.circular(s * 0.04),
    );
    canvas.drawRRect(head, goldGradient);

    final headCap = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(s * 0.22, -s * 0.14),
        width: s * 0.1,
        height: s * 0.24,
      ),
      Radius.circular(s * 0.03),
    );
    canvas.drawRRect(headCap, goldGradient);

    final handle = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(-s * 0.1, s * 0.12),
        width: s * 0.1,
        height: s * 0.42,
      ),
      Radius.circular(s * 0.05),
    );
    canvas.drawRRect(handle, goldGradient);

    final base = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(s * 0.08, s * 0.28),
        width: s * 0.34,
        height: s * 0.1,
      ),
      Radius.circular(s * 0.03),
    );
    canvas.drawRRect(base, goldGradient);

    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.015;
    canvas.drawLine(
      Offset(-s * 0.2, -s * 0.2),
      Offset(s * 0.05, -s * 0.05),
      shine,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DembeeLogoMarkPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius;
}
