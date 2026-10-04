import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Molécula de resumen de cálculo instantáneo de puntos según regla de negocio.
class PosComputationSummary extends StatelessWidget {
  /// Crea el cuadro de cálculo dinámico de puntos.
  const new({
    required this.basePoints,
    required this.bonusPoints,
    required this.totalPoints,
    super.key,
  });

  /// Puntos base correspondientes al valor neto de compra (1 EUR = 1 PT).
  final int basePoints;

  /// Puntos bonus correspondientes al tier del cliente (+10%).
  final int bonusPoints;

  /// Puntos totales calculados para acreditar al ledger.
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF13151F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF262838)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabecera con indicación de regla y multiplicador
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 13, color: Color(0xFFE5C07B)),
                  SizedBox(width: 6),
                  Text(
                    'INSTANT REWARD COMPUTATION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Color(0xFFE5C07B),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '1 EUR = 1 BASE PT • TIER OBSIDIAN MULTIPLIER: +10%',
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: Color(0xFF787B8A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Valores calculados en fila
          Row(
            children: [
              const Text(
                'Points to\nassign:',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF787B8A),
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 20),

              // Puntos Base
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '+$basePoints PTS',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: PaseoColors.textWhite,
                    ),
                  ),
                  const Text(
                    'Base',
                    style: TextStyle(fontSize: 10, color: Color(0xFF787B8A)),
                  ),
                ],
              ),
              const SizedBox(width: 24),

              // Bonus VIP
              Text(
                '(+$bonusPoints VIP\nBonus)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD4AF37),
                  height: 1.2,
                ),
              ),
              const Spacer(),

              // Total en destacado
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$totalPoints',
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE5C07B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PTS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Color(0xFFE5C07B),
                        ),
                      ),
                      Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Color(0xFF787B8A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
