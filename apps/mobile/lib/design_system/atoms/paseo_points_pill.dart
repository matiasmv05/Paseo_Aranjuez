import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo de píldora para mostrar saldo de puntos en cabeceras ("● 3,450 PTS").
class PaseoPointsPill extends StatelessWidget {
  /// Crea una píldora con indicador dorado y saldo de puntos.
  const new({required this.pointsText, super.key});

  /// Texto del saldo de puntos (ej. "3,450 PTS").
  final String pointsText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: PaseoColors.surfaceIcon.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: PaseoColors.goldMetallic.withValues(alpha: 0.35),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Punto dorado con resplandor
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: PaseoColors.goldMetallic,
              boxShadow: [
                BoxShadow(
                  color: PaseoColors.goldPrimary,
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Valor numérico de puntos
          Text(
            pointsText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: PaseoColors.goldLight,
            ),
          ),
        ],
      ),
    );
  }
}
