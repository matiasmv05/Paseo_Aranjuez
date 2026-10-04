import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo de insignia VIP Obsidian con código de socio exclusivo (#ARJ-9921).
class PaseoVipPill extends StatelessWidget {
  /// Crea la insignia VIP Obsidian con código de socio.
  const new({
    super.key,
    this.tierName = 'VIP\nOBSIDIAN',
    this.memberCode = '#ARJ-9921',
  });

  /// Nombre del nivel de membresía.
  final String tierName;

  /// Código único del socio.
  final String memberCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1D27).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: PaseoColors.goldMetallic.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: PaseoColors.goldPrimary.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE5C07B),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x88E5C07B),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tierName,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  height: 1.2,
                  color: Color(0xFFE5C07B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          memberCode,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            color: PaseoColors.textMuted,
          ),
        ),
      ],
    );
  }
}
