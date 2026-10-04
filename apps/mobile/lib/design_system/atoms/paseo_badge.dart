import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Átomo de insignia / badge para categorías y rangos de membresía.
class PaseoBadge extends StatelessWidget {
  /// Crea una insignia de membresía VIP.
  const new({required this.label, super.key, this.memberCode});

  /// Texto del nivel o categoría (ej. "VIP OBSIDIAN MEMBER").
  final String label;

  /// Código o identificador opcional del socio (ej. "#ARJ-9921").
  final String? memberCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: PaseoColors.surfaceCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: PaseoColors.goldMetallic.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: PaseoTypography.vipBadge),
          if (memberCode != null && memberCode!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: PaseoColors.goldMetallic,
                ),
              ),
            ),
            Text(
              memberCode!,
              style: PaseoTypography.vipBadge.copyWith(
                color: PaseoColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
