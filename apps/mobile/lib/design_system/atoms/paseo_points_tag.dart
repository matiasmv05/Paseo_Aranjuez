import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo de insignia de puntos en oro cálido (ej. "★ 500 puntos").
class PaseoPointsTag extends StatelessWidget {
  /// Crea una insignia de puntos dorada.
  const new({required this.points, super.key, this.customText});

  /// Cantidad de puntos a mostrar.
  final int points;

  /// Texto personalizado alternativo si aplica.
  final String? customText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: PaseoColors.goldBadgeBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PaseoColors.goldBadgeBorder, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 14,
            color: PaseoColors.goldBadgeText,
          ),
          const SizedBox(width: 4),
          Text(
            customText ?? '$points puntos',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: PaseoColors.goldBadgeText,
            ),
          ),
        ],
      ),
    );
  }
}
