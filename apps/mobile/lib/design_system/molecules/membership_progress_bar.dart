import 'package:flutter/material.dart';

/// Molécula de indicador de progreso hacia el siguiente nivel VIP
/// (Sovereign Tier).
class MembershipProgressBar extends StatelessWidget {
  /// Crea la barra de progreso de nivel VIP.
  const new({
    super.key,
    this.progress = 0.86,
    this.remainingPointsText = '550 PTS TO SOVEREIGN TIER',
  });

  /// Progreso normalizado de 0.0 a 1.0.
  final double progress;

  /// Texto indicativo de puntos requeridos para el siguiente nivel.
  final String remainingPointsText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Etiquetas superiores
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PROGRESS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: Color(0xFF989AA8),
              ),
            ),
            Text(
              remainingPointsText,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Color(0xFFE5C07B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Barra de progreso estilizada
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            height: 6,
            width: double.infinity,
            color: const Color(0xFF232532),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFF3E5AB)],
                  ),
                  boxShadow: [
                    BoxShadow(color: Color(0x66D4AF37), blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
