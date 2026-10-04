import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_spacing.dart';

/// Átomo de barra informativa del sensor de autenticación NFC.
class PaseoNfcBeacon extends StatelessWidget {
  /// Crea el banner inferior de estado del balizamiento NFC.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF101116),
        borderRadius: BorderRadius.circular(PaseoSpacing.radiusCard),
        border: Border.all(color: PaseoColors.surfaceBorder, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono circular con sensor inalámbrico
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PaseoColors.surfaceIcon,
              border: Border.all(
                color: PaseoColors.goldMetallic.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              size: 18,
              color: PaseoColors.goldLight,
            ),
          ),
          const SizedBox(width: 14),

          // Texto informativo
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NFC CONCIERGE BEACON',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: PaseoColors.textWhite,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Terminal authentication ready',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: PaseoColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Estado activo
          Text(
            'ACTIVE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: PaseoColors.goldMetallic.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
