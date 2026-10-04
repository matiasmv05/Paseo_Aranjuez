import 'package:flutter/material.dart';
import 'package:paseo_mobile/data/mock/mock_data.dart';

/// Átomo de insignia visual del nivel de lealtad (HU-22).
///
/// Renderiza una píldora heráldica con el color temático del nivel:
/// Bronce, Plata, Oro o Platinum.
class PaseoTierBadge extends StatelessWidget {
  /// Crea la insignia de nivel.
  const new({required this.tier, super.key, this.isCompact = false});

  /// Nivel de lealtad a representar.
  final LoyaltyTier tier;

  /// Si muestra una versión reducida solo de icono y texto corto.
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final (label, icon, textColor, bgColor, borderColor) = switch (tier) {
      LoyaltyTier.platinum => (
        'PLATINUM',
        Icons.workspace_premium_rounded,
        const Color(0xFF2D3748),
        const Color(0xFFEDF2F7),
        const Color(0xFFCBD5E0),
      ),
      LoyaltyTier.oro => (
        'ORO',
        Icons.star_rounded,
        const Color(0xFF8C6527),
        const Color(0xFFF9F3EA),
        const Color(0xFFECC94B),
      ),
      LoyaltyTier.plata => (
        'PLATA',
        Icons.verified_rounded,
        const Color(0xFF4A5568),
        const Color(0xFFF7FAFC),
        const Color(0xFFCBD5E0),
      ),
      LoyaltyTier.bronce => (
        'BRONCE',
        Icons.shield_outlined,
        const Color(0xFF7B341E),
        const Color(0xFFFEEBC8),
        const Color(0xFFDD6B20),
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 13 : 15, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
