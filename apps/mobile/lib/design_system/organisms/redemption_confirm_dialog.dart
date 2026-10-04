import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_primary_button.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Organismo de diálogo de confirmación de canje de recompensa (Pantalla 7).
class RedemptionConfirmDialog extends StatelessWidget {
  /// Crea el diálogo de confirmación de canje.
  const new({
    required this.points,
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  /// Puntos que se descontarán del saldo.
  final int points;

  /// Callback de confirmación.
  final VoidCallback onConfirm;

  /// Callback de cancelación.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de regalo en círculo champán
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF9F3EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Color(0xFFC79E69),
                size: 28,
              ),
            ),
            const SizedBox(height: 18),

            // Título serif
            const Text(
              '¿Quieres canjear esta\nrecompensa?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: PaseoColors.textDarkPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),

            // Detalle de puntos
            Text(
              'Se descontarán $points puntos\nde tu saldo.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: PaseoColors.textDarkSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),

            // Botón Confirmar
            PaseoPrimaryButton(label: 'Confirmar', onPressed: onConfirm),
            const SizedBox(height: 10),

            // Botón Cancelar
            TextButton(
              onPressed: onCancel,
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: PaseoColors.textDarkSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
