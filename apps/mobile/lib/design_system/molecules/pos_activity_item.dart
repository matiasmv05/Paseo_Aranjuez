import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Molécula de fila de transacción en el feed de actividad del POS.
class PosActivityItem extends StatelessWidget {
  /// Crea una fila de registro en el feed de actividad.
  const new({
    required this.time,
    required this.clientName,
    required this.memberCode,
    required this.ticketNumber,
    required this.amountEuro,
    required this.pointsText,
    super.key,
  });

  /// Hora de la transacción (ej. "14:35").
  final String time;

  /// Nombre del cliente.
  final String clientName;

  /// Código único del socio (#ARJ-9921).
  final String memberCode;

  /// Número de ticket / factura (TCK-88203).
  final String ticketNumber;

  /// Monto total en euros (€1,250.00).
  final String amountEuro;

  /// Puntos otorgados (+1,375 • co).
  final String pointsText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF1B1D28), width: 0.8),
        ),
      ),
      child: Row(
        children: [
          // 1. Hora
          SizedBox(
            width: 44,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF787B8A),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Cliente y Código
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  clientName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PaseoColors.textWhite,
                  ),
                ),
                Text(
                  memberCode,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF787B8A),
                  ),
                ),
              ],
            ),
          ),

          // 3. Ticket #
          Expanded(
            flex: 2,
            child: Text(
              ticketNumber,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Color(0xFFC7CBD8),
              ),
            ),
          ),

          // 4. Monto (€)
          Expanded(
            flex: 2,
            child: Text(
              amountEuro,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: PaseoColors.textWhite,
              ),
            ),
          ),

          // 5. Puntos otorgados
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pointsText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE5C07B),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE5C07B),
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                'co',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF787B8A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
