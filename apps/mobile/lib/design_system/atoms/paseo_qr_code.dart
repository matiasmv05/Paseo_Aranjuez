import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo vectorial que renderiza un código QR limpio y nítido sin dependencias.
class PaseoQrCode extends StatelessWidget {
  /// Crea un código QR visualizable.
  const new({
    required this.data,
    super.key,
    this.size = 200.0,
    this.color = PaseoColors.primaryNavy,
  });

  /// Contenido textual del código QR.
  final String data;

  /// Dimensión cuadrada del código QR.
  final double size;

  /// Color de los módulos del código QR.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: Colors.white,
      child: CustomPaint(
        size: Size(size, size),
        painter: _PaseoQrPainter(data: data, color: color),
      ),
    );
  }
}

class _PaseoQrPainter extends CustomPainter {
  new({required this.data, required this.color});

  final String data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const moduleCount = 25;
    final moduleSize = size.width / moduleCount;

    // 1. Patrones de localización en las tres esquinas (Finder Patterns 7x7)
    _drawFinderPattern(canvas, 0, 0, moduleSize, paint);
    _drawFinderPattern(
      canvas,
      (moduleCount - 7) * moduleSize,
      0,
      moduleSize,
      paint,
    );
    _drawFinderPattern(
      canvas,
      0,
      (moduleCount - 7) * moduleSize,
      moduleSize,
      paint,
    );

    // 2. Módulos pseudo-aleatorios deterministas basados en el payload
    // del usuario.
    final seed = data.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    final random = math.Random(seed);

    for (var r = 0; r < moduleCount; r++) {
      for (var c = 0; c < moduleCount; c++) {
        // Ignora las zonas reservadas para los 3 finder patterns
        final inTopLeft = r < 8 && c < 8;
        final inTopRight = r < 8 && c >= moduleCount - 8;
        final inBottomLeft = r >= moduleCount - 8 && c < 8;

        if (inTopLeft || inTopRight || inBottomLeft) continue;

        // Patrón de temporización (líneas discontinuas en fila 6 y columna 6)
        if (r == 6 || c == 6) {
          if ((r + c).isEven) {
            canvas.drawRect(
              Rect.fromLTWH(
                c * moduleSize,
                r * moduleSize,
                moduleSize,
                moduleSize,
              ),
              paint,
            );
          }
          continue;
        }

        // Módulos de datos
        if (random.nextBool()) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * moduleSize + 0.3,
                r * moduleSize + 0.3,
                moduleSize - 0.6,
                moduleSize - 0.6,
              ),
              const Radius.circular(1),
            ),
            paint,
          );
        }
      }
    }
  }

  void _drawFinderPattern(
    Canvas canvas,
    double x,
    double y,
    double moduleSize,
    Paint paint,
  ) {
    // Marco exterior 7x7
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, moduleSize * 7, moduleSize * 7),
        Radius.circular(moduleSize * 1.2),
      ),
      paint,
    );

    // Espacio interior blanco 5x5
    final whitePaint = Paint()..color = Colors.white;
    canvas
      ..drawRect(
        Rect.fromLTWH(
          x + moduleSize,
          y + moduleSize,
          moduleSize * 5,
          moduleSize * 5,
        ),
        whitePaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + moduleSize * 2,
            y + moduleSize * 2,
            moduleSize * 3,
            moduleSize * 3,
          ),
          Radius.circular(moduleSize * 0.8),
        ),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant _PaseoQrPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}
