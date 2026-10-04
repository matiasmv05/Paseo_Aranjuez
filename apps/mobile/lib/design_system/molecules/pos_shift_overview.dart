import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Molécula de resumen de turno de caja y conciliación diaria.
class PosShiftOverview extends StatelessWidget {
  /// Crea el cuadro de balance del turno del terminal.
  const new({
    super.key,
    this.terminalName = 'TERMINAL 01',
    this.todaysVolume = '€3,730.00',
    this.totalPointsIssued = '4,065 PTS',
  });

  /// Identificador del terminal.
  final String terminalName;

  /// Volumen total registrado en el turno.
  final String todaysVolume;

  /// Puntos totales emitidos.
  final String totalPointsIssued;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13151F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262838)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabecera con reconciliación
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'SHIFT OVERVIEW ($terminalName)',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: Color(0xFF787B8A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 13,
                    color: Color(0xFF48BB78),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '100% RECONCILED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Color(0xFF48BB78),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Métricas del turno
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Volume:",
                      style: TextStyle(fontSize: 11, color: Color(0xFF787B8A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      todaysVolume,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: PaseoColors.textWhite,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: const Color(0xFF232534)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Points Issued:',
                      style: TextStyle(fontSize: 11, color: Color(0xFF787B8A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalPointsIssued,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE5C07B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
