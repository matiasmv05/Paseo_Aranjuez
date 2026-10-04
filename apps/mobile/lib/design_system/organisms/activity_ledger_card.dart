import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_spacing.dart';

/// Modelo ligero para representar un movimiento en el ledger de puntos.
class LedgerItemData {
  /// Crea un registro del ledger.
  const new({
    required this.id,
    required this.establishmentName,
    required this.dateLabel,
    required this.pointsDelta,
    required this.type,
    this.amountBs,
  });

  /// Identificador único del movimiento.
  final String id;

  /// Nombre del establecimiento comercial.
  final String establishmentName;

  /// Fecha formateada del evento.
  final String dateLabel;

  /// Variación de puntos (+350, -500, etc.).
  final int pointsDelta;

  /// Tipo de movimiento ('PURCHASE', 'REDEMPTION', 'REVERSAL').
  final String type;

  /// Monto neto en Bolivianos opcional.
  final double? amountBs;
}

/// Organismo de tarjeta para transacciones del ledger de auditoría.
class ActivityLedgerCard extends StatelessWidget {
  /// Crea una tarjeta de movimiento de puntos.
  const new({required this.item, super.key});

  /// Datos del movimiento del ledger.
  final LedgerItemData item;

  @override
  Widget build(BuildContext context) {
    final isEarn = item.pointsDelta > 0;
    final isReversal = item.type == 'REVERSAL';

    final deltaColor = isReversal
        ? PaseoColors.ruby
        : isEarn
        ? const Color(0xFF66BB6A)
        : PaseoColors.goldLight;

    final typeIcon = isReversal
        ? Icons.replay_rounded
        : isEarn
        ? Icons.add_circle_outline_rounded
        : Icons.redeem_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: PaseoSpacing.cardPadding,
      decoration: BoxDecoration(
        color: PaseoColors.surfaceCard,
        borderRadius: BorderRadius.circular(PaseoSpacing.radiusCard),
        border: Border.all(
          color: isReversal
              ? PaseoColors.ruby.withValues(alpha: 0.3)
              : PaseoColors.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          // Icono según tipo de movimiento
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: deltaColor.withValues(alpha: 0.12),
              border: Border.all(color: deltaColor.withValues(alpha: 0.3)),
            ),
            child: Icon(typeIcon, size: 20, color: deltaColor),
          ),
          const SizedBox(width: 14),

          // Información del comercio y fecha
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.establishmentName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: PaseoColors.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item.dateLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PaseoColors.textMuted,
                      ),
                    ),
                    if (item.amountBs != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${item.amountBs!.toStringAsFixed(2)} Bs.',
                        style: TextStyle(
                          fontSize: 12,
                          color: PaseoColors.textMuted.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Delta de puntos acumulados / canjeados
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isEarn ? '+' : ''}${item.pointsDelta} PTS',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: deltaColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.type,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: PaseoColors.textMuted.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
