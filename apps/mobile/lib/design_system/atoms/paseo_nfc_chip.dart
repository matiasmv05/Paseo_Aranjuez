import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo de micro-insignia que indica la disponibilidad de enlace NFC.
class PaseoNfcChip extends StatelessWidget {
  /// Crea la micro-insignia NFC Ready.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1D27).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PaseoColors.goldMetallic.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.contactless_outlined,
            size: 13,
            color: PaseoColors.goldLight.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 5),
          const Text(
            'NFC READY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Color(0xFFC7CBD8),
            ),
          ),
        ],
      ),
    );
  }
}
