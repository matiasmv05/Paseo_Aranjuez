import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo de etiqueta de sección con punto distintivo áurico.
///
/// Usado para rotular jerarquías como "● MEMBER ACTIVITY".
class PaseoSectionTag extends StatelessWidget {
  /// Crea una etiqueta de sección con viñeta dorada.
  const new({required this.label, super.key});

  /// Texto de la etiqueta en mayúsculas.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Punto dorado brillante
        Container(
          width: 5,
          height: 5,
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

        // Texto rotulado en mayúsculas
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: PaseoColors.goldMetallic,
          ),
        ),
      ],
    );
  }
}
