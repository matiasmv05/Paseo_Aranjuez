import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Átomo que renderiza el emblema áurico y monograma floral de Paseo Aranjuez.
///
/// Dibuja con precisión vectorial filigranas doradas, volutas barrocas y
/// la tipografía solemne "PASEO ARANJUEZ" en corte serif de alta joyería.
class PaseoBrandCrest extends StatelessWidget {
  /// Crea el emblema oficial de Paseo Aranjuez.
  const new({super.key, this.size = 64.0, this.showWordmark = true});

  /// Diámetro base de la filigrana del escudo.
  final double size;

  /// Si muestra el texto "PASEO ARANJUEZ" debajo del escudo.
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _PaseoFiligreePainter()),
        ),
        if (showWordmark) ...[
          const SizedBox(height: 10),
          Text(
            'PASEO',
            style: PaseoTypography.brandCrestText.copyWith(
              fontSize: 10,
              letterSpacing: 4.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'ARANJUEZ',
            style: PaseoTypography.brandCrestText.copyWith(
              fontSize: 14,
              letterSpacing: 5.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Painter vectorial que reproduce la orla de filigrana dorada de Paseo
/// Aranjuez.
class _PaseoFiligreePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    const goldGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFF9E8C8),
        PaseoColors.champagneLight,
        PaseoColors.champagneDark,
        Color(0xFFA88048),
      ],
    );

    final paintStroke = Paint()
      ..shader = goldGradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintFill = Paint()
      ..shader = goldGradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    // 1. Flor de lis central superior
    final centerFleur = Path()
      ..moveTo(center.dx, center.dy - h * 0.42)
      ..cubicTo(
        center.dx + w * 0.08,
        center.dy - h * 0.28,
        center.dx + w * 0.12,
        center.dy - h * 0.15,
        center.dx,
        center.dy - h * 0.05,
      )
      ..cubicTo(
        center.dx - w * 0.12,
        center.dy - h * 0.15,
        center.dx - w * 0.08,
        center.dy - h * 0.28,
        center.dx,
        center.dy - h * 0.42,
      );
    canvas
      ..drawPath(centerFleur, paintStroke)
      ..drawCircle(Offset(center.dx, center.dy - h * 0.44), 1.8, paintFill);

    // 2. Volutas laterales en espejo (izquierda y derecha)
    _drawScrollFlourish(canvas, center, w, h, paintStroke, isLeft: true);
    _drawScrollFlourish(canvas, center, w, h, paintStroke, isLeft: false);

    // 3. Lazos inferiores estilizados
    final bottomArcLeft = Path()
      ..moveTo(center.dx - w * 0.05, center.dy + h * 0.08)
      ..cubicTo(
        center.dx - w * 0.24,
        center.dy + h * 0.15,
        center.dx - w * 0.26,
        center.dy + h * 0.38,
        center.dx - w * 0.08,
        center.dy + h * 0.38,
      )
      ..cubicTo(
        center.dx - w * 0.02,
        center.dy + h * 0.32,
        center.dx - w * 0.02,
        center.dy + h * 0.22,
        center.dx,
        center.dy + h * 0.22,
      );
    canvas.drawPath(bottomArcLeft, paintStroke);

    final bottomArcRight = Path()
      ..moveTo(center.dx + w * 0.05, center.dy + h * 0.08)
      ..cubicTo(
        center.dx + w * 0.24,
        center.dy + h * 0.15,
        center.dx + w * 0.26,
        center.dy + h * 0.38,
        center.dx + w * 0.08,
        center.dy + h * 0.38,
      )
      ..cubicTo(
        center.dx + w * 0.02,
        center.dy + h * 0.32,
        center.dx + w * 0.02,
        center.dy + h * 0.22,
        center.dx,
        center.dy + h * 0.22,
      );
    canvas
      ..drawPath(bottomArcRight, paintStroke)
      ..drawCircle(Offset(center.dx, center.dy + h * 0.39), 2, paintFill);
  }

  void _drawScrollFlourish(
    Canvas canvas,
    Offset center,
    double w,
    double h,
    Paint paint, {
    required bool isLeft,
  }) {
    final sign = isLeft ? -1.0 : 1.0;

    final scrollPath = Path()
      ..moveTo(center.dx + sign * w * 0.05, center.dy - h * 0.15)
      ..cubicTo(
        center.dx + sign * w * 0.32,
        center.dy - h * 0.36,
        center.dx + sign * w * 0.44,
        center.dy - h * 0.05,
        center.dx + sign * w * 0.28,
        center.dy + h * 0.08,
      )
      ..cubicTo(
        center.dx + sign * w * 0.18,
        center.dy + h * 0.14,
        center.dx + sign * w * 0.12,
        center.dy + h * 0.05,
        center.dx + sign * w * 0.20,
        center.dy - h * 0.04,
      )
      ..cubicTo(
        center.dx + sign * w * 0.25,
        center.dy - h * 0.10,
        center.dx + sign * w * 0.32,
        center.dy - h * 0.06,
        center.dx + sign * w * 0.30,
        center.dy - h * 0.02,
      );

    canvas.drawPath(scrollPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
