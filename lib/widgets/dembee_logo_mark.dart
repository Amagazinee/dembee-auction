import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// ДЭМБЭЭ брэнд тэмдэг — logo.png байхгүй үед Figma загвартай ойролцоо
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
    final radius = borderRadius ?? size * 0.04;

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
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: size * 0.3,
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

  static const _goldLight = Color(0xFFF5D76E);
  static const _gold = Color(0xFFE8C547);
  static const _goldMid = AppTheme.primary;
  static const _goldDark = Color(0xFF9A7A32);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFC8C8CC), Color(0xFF6E6E74), Color(0xFF1A1A1F)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, bgPaint);

    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.02
      ..color = const Color(0xFF0A0A0A);
    canvas.drawRRect(rrect.deflate(size.shortestSide * 0.01), framePaint);

    _drawLetterD(canvas, size);
    _drawGavel(canvas, size);
  }

  void _drawLetterD(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final goldShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_goldLight, _gold, _goldMid, _goldDark],
      stops: [0.0, 0.35, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, s, s));

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'D',
        style: GoogleFonts.fraunces(
          fontSize: s * 0.78,
          fontWeight: FontWeight.w800,
          foreground: Paint()..shader = goldShader,
          height: 1,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final offset = Offset(
      (size.width - textPainter.width) / 2 - s * 0.02,
      (size.height - textPainter.height) / 2 + s * 0.02,
    );
    textPainter.paint(canvas, offset);
  }

  void _drawGavel(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(math.pi / 4);

    final goldGradient = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_goldLight, _gold, _goldMid, _goldDark],
      ).createShader(Rect.fromCenter(
        center: Offset.zero,
        width: s * 0.75,
        height: s * 0.75,
      ));

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    void drawShadow(void Function() draw) {
      canvas.save();
      canvas.translate(1.5, 2);
      draw();
      canvas.restore();
      draw();
    }

    drawShadow(() {
      final head = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.12, -s * 0.2),
          width: s * 0.44,
          height: s * 0.17,
        ),
        Radius.circular(s * 0.035),
      );
      canvas.drawRRect(head, shadow);
    });

    final head = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(-s * 0.12, -s * 0.2),
        width: s * 0.44,
        height: s * 0.17,
      ),
      Radius.circular(s * 0.035),
    );
    canvas.drawRRect(head, goldGradient);

    final headCap = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(s * 0.1, -s * 0.2),
        width: s * 0.09,
        height: s * 0.22,
      ),
      Radius.circular(s * 0.025),
    );
    canvas.drawRRect(headCap, goldGradient);

    final handle = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(-s * 0.14, s * 0.1),
        width: s * 0.085,
        height: s * 0.5,
      ),
      Radius.circular(s * 0.04),
    );
    canvas.drawRRect(handle, goldGradient);

    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012;
    canvas.drawLine(
      Offset(-s * 0.28, -s * 0.26),
      Offset(-s * 0.02, -s * 0.14),
      shine,
    );
    canvas.drawLine(
      Offset(-s * 0.16, -s * 0.02),
      Offset(-s * 0.12, s * 0.22),
      shine,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DembeeLogoMarkPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius;
}
