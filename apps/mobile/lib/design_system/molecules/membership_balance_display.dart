import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Molécula de saldo acumulado de privilegios y equivalencia comercial.
class MembershipBalanceDisplay extends StatelessWidget {
  /// Crea la sección de saldo de privilegios.
  const new({
    super.key,
    this.pointsText = '3,450',
    this.currencyEquivalent = '€345',
    this.boutiquesCount = 54,
  });

  /// Puntos acumulados en formato de texto.
  final String pointsText;

  /// Equivalente monetario en euros o crédito en boutique.
  final String currencyEquivalent;

  /// Número de boutiques y talleres acreditados en el mall.
  final int boutiquesCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Etiqueta superior
        const Text(
          'ACCUMULATED PRIVILEGE BALANCE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: Color(0xFFC4C7D4),
          ),
        ),
        const SizedBox(height: 8),

        // Saldo numérico y unidad PTS
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(pointsText, style: PaseoTypography.balanceHero),
            const SizedBox(width: 8),
            const Text(
              'PTS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Color(0xFFE5C07B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Equivalencia de crédito en boutiques
        Text(
          'Equivalent to $currencyEquivalent store credit across '
          '$boutiquesCount accredited boutiques',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.1,
            height: 1.4,
            color: Color(0xFF989AA8),
          ),
        ),
      ],
    );
  }
}
