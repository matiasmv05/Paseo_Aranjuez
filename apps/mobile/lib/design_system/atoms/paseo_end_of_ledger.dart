import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo indicador del final de transacciones recientes en el ledger.
class PaseoEndOfLedger extends StatelessWidget {
  /// Crea el indicador de fin de lista del ledger.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Línea vertical dorada sutil
        Container(
          width: 2,
          height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                PaseoColors.goldMetallic.withValues(alpha: 0.1),
                PaseoColors.goldMetallic.withValues(alpha: 0.5),
                PaseoColors.goldMetallic.withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Leyenda en gris oscuro/metálico
        Text(
          'END OF RECENT LEDGER',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.2,
            color: PaseoColors.textMuted.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
