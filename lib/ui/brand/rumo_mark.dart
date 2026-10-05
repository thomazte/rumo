import 'dart:math' as math;

import 'package:flutter/widgets.dart';

const rumoGradient = [Color(0xFF4673FF), Color(0xFF2143C2)];

/// O ícone do Rumo: anel de progresso em 3/4 com um check no meio.
/// Desenhado numa caixa de 100×100 (mesma geometria de design/icone/*.svg).
class RumoMarkPainter extends CustomPainter {
  const RumoMarkPainter({
    this.background = true,
    this.rounded = true,
    this.glyphColor = const Color(0xFFFFFFFF),
    this.designScale = 1.0,
    this.glyph = true,
  });

  final bool background;
  final bool rounded;
  final Color glyphColor;

  /// Quanto da tela a caixa de 100×100 ocupa, centralizada.
  /// 0.667 = área segura do ícone adaptativo do Android; 1.39 = bandeja.
  final double designScale;
  final bool glyph;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final area = Offset.zero & size;

    if (background) {
      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: rumoGradient,
        ).createShader(area);
      if (rounded) {
        canvas.drawRRect(RRect.fromRectAndRadius(area, Radius.circular(side * 0.23)), paint);
      } else {
        canvas.drawRect(area, paint);
      }
    }

    if (!glyph) return;
    final box = side * designScale;
    canvas.save();
    canvas.translate((size.width - box) / 2, (size.height - box) / 2);
    canvas.scale(box / 100);

    Paint stroke(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = c
      ..isAntiAlias = true;

    final ring = Rect.fromCircle(center: const Offset(50, 50), radius: 30);
    canvas.drawCircle(ring.center, 30, stroke(glyphColor.withValues(alpha: glyphColor.a * 0.3)));
    canvas.drawArc(ring, -math.pi / 2, math.pi * 1.5, false, stroke(glyphColor));
    final check = Path()
      ..moveTo(38, 51)
      ..lineTo(47, 60)
      ..lineTo(63, 42);
    canvas.drawPath(check, stroke(glyphColor));
    canvas.restore();
  }

  @override
  bool shouldRepaint(RumoMarkPainter old) =>
      old.background != background || old.rounded != rounded || old.glyphColor != glyphColor || old.designScale != designScale || old.glyph != glyph;
}

class RumoLogo extends StatelessWidget {
  const RumoLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: RumoMarkPainter()),
      );
}
