import 'package:flutter/material.dart';
import 'package:paseo_mobile/data/mock/mock_data.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Molécula de fila de transacción del ledger de puntos.
class TransactionTile extends StatelessWidget {
  /// Crea una fila de transacción para el historial.
  const new({required this.transaction, super.key, this.onTap});

  /// Modelo de la transacción.
  final MockTransaction transaction;

  /// Callback opcional de pulsación.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEarned = transaction.type == TransactionType.earned;
    final pointsColor = isEarned
        ? PaseoColors.pointsEarned
        : PaseoColors.pointsSpent;
    final pointsBg = isEarned
        ? PaseoColors.pointsEarnedBg
        : PaseoColors.pointsSpentBg;
    final prefix = isEarned ? '+' : '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icono circular
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: pointsBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEarned
                    ? Icons.arrow_upward_rounded
                    : Icons.card_giftcard_rounded,
                color: pointsColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),

            // Puntos y establecimiento
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        '$prefix${transaction.points} pts',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: pointsColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: pointsBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          transaction.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: pointsColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.establishment,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: PaseoColors.textDarkPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: PaseoColors.textPlaceholder,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
