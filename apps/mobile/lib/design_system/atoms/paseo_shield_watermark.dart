import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Átomo de marca de agua inferior de seguridad y prestigio privado.
class PaseoShieldWatermark extends StatelessWidget {
  /// Crea el pie de página oficial con escudo y leyenda de auditoría privada.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Escudo de seguridad en oro antiguo
        Icon(
          Icons.shield_outlined,
          size: 26,
          color: PaseoColors.goldMetallic.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 10),
        const Text(
          'PASEO ARANJUEZ  •  PRIVATE LEDGER',
          style: PaseoTypography.watermark,
        ),
      ],
    );
  }
}
