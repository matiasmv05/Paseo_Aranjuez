import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo para la tarjeta de estado del canal NFC en el pie de la barra lateral.
class PosSidebarCard extends StatelessWidget {
  /// Crea la tarjeta de estatus de terminal de boutique.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF14161F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: PaseoColors.goldMetallic.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TERMINAL STATUS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Color(0xFF787B8A),
                    ),
                  ),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE5C07B),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66E5C07B),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Paseo Direct NFC Channel',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: PaseoColors.textWhite,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'PA-8842-VIP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Color(0xFFE5C07B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 13,
              color: Color(0xFF787B8A),
            ),
            SizedBox(width: 6),
            Text(
              'ENCRYPTED TUNNEL',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: Color(0xFF787B8A),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
