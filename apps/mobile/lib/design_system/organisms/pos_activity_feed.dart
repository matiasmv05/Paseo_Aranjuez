import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/molecules/pos_activity_item.dart';
import 'package:paseo_mobile/design_system/molecules/pos_shift_overview.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Modelo ligero para representar un registro en el feed de actividad de caja.
class PosTransactionEntry {
  /// Crea una entrada de transacción en el feed.
  const new({
    required this.time,
    required this.clientName,
    required this.memberCode,
    required this.ticketNumber,
    required this.amountEuro,
    required this.pointsText,
  });

  /// Hora de la venta.
  final String time;

  /// Nombre del socio.
  final String clientName;

  /// Código del socio.
  final String memberCode;

  /// Número de factura / comprobante.
  final String ticketNumber;

  /// Monto en euros.
  final String amountEuro;

  /// Puntos asignados.
  final String pointsText;
}

/// Organismo de feed en vivo de actividad del comercio y balance de turno.
class PosActivityFeed extends StatelessWidget {
  /// Crea el feed de actividad del POS de boutique.
  const new({
    super.key,
    this.transactions = defaultTransactions,
    this.onViewFullLedger,
  });

  /// Transacciones por defecto que reproducen la captura de pantalla oficial.
  static const List<PosTransactionEntry> defaultTransactions = [
    PosTransactionEntry(
      time: '14:35',
      clientName: 'Alejandro Morales',
      memberCode: '#ARJ-9921',
      ticketNumber: 'TCK-88203',
      amountEuro: '€1,250.00',
      pointsText: '+1,375',
    ),
    PosTransactionEntry(
      time: '13:12',
      clientName: 'Elena Rostova',
      memberCode: '#ARJ-4412',
      ticketNumber: 'TCK-88202',
      amountEuro: '€380.00',
      pointsText: '+380',
    ),
    PosTransactionEntry(
      time: '11:45',
      clientName: 'Carlos Mendez',
      memberCode: '#ARJ-1089',
      ticketNumber: 'TCK-88201',
      amountEuro: '€2,100.00',
      pointsText: '+2,310',
    ),
  ];

  /// Lista de transacciones recientes a desplegar.
  final List<PosTransactionEntry> transactions;

  /// Callback emitido al pulsar "FULL LEDGER ↗".
  final VoidCallback? onViewFullLedger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF10121A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF202332)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabecera con enlace al libro mayor completo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEDGER HU-13',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: Color(0xFF787B8A),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Store Activity Feed',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: PaseoColors.textWhite,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onViewFullLedger,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'FULL LEDGER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: Color(0xFFE5C07B),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 13,
                      color: Color(0xFFE5C07B),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Encabezados de columna
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    'TIME',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Color(0xFF5B5D6D),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    'CLIENT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Color(0xFF5B5D6D),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'TICKET',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Color(0xFF5B5D6D),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'AMOUNT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Color(0xFF5B5D6D),
                    ),
                  ),
                ),
                Text(
                  'PTS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0xFF5B5D6D),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E202B), height: 1),

          // 3. Filas de transacción
          ...transactions.map(
            (t) => PosActivityItem(
              time: t.time,
              clientName: t.clientName,
              memberCode: t.memberCode,
              ticketNumber: t.ticketNumber,
              amountEuro: t.amountEuro,
              pointsText: t.pointsText,
            ),
          ),
          const SizedBox(height: 24),

          // 4. Resumen del turno (Shift Overview)
          const PosShiftOverview(),
        ],
      ),
    );
  }
}
