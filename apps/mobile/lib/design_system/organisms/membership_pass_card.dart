import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_nfc_chip.dart';
import 'package:paseo_mobile/design_system/molecules/membership_balance_display.dart';
import 'package:paseo_mobile/design_system/molecules/membership_progress_bar.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Organismo de tarjeta digital de membresía VIP con saldo y validez.
class MembershipPassCard extends StatelessWidget {
  /// Crea la tarjeta digital de membresía.
  const new({
    super.key,
    this.pointsText = '3,450',
    this.currencyEquivalent = '€345',
    this.boutiquesCount = 54,
    this.progress = 0.86,
    this.validThru = '12/27',
  });

  /// Puntos acumulados en formato de texto.
  final String pointsText;

  /// Equivalente en euros.
  final String currencyEquivalent;

  /// Cantidad de boutiques acreditadas.
  final int boutiquesCount;

  /// Progreso hacia el siguiente nivel (0.0 a 1.0).
  final double progress;

  /// Fecha de validez de la credencial.
  final String validThru;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF13151D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: PaseoColors.goldMetallic.withValues(alpha: 0.28),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
          BoxShadow(color: Color(0x1AD4AF37), blurRadius: 36, spreadRadius: -4),
        ],
      ),
      child: Stack(
        children: [
          // Resplandor áurico ambiental en la esquina superior derecha
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    PaseoColors.goldMetallic.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Fila de Cabecera: Título y Chip NFC Ready
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MEMBERSHIP PASS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                        color: Color(0xFFE5C07B),
                      ),
                    ),
                    PaseoNfcChip(),
                  ],
                ),
                const SizedBox(height: 28),

                // 2. Saldo Acumulado y Equivalencia
                MembershipBalanceDisplay(
                  pointsText: pointsText,
                  currencyEquivalent: currencyEquivalent,
                  boutiquesCount: boutiquesCount,
                ),
                const SizedBox(height: 28),

                // 3. Barra de progreso a Sovereign Tier
                MembershipProgressBar(progress: progress),
                const SizedBox(height: 24),

                // 4. Pie de tarjeta: Identificación y Vigencia
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PASEO ARANJUEZ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Color(0xFF787B8A),
                      ),
                    ),
                    Text(
                      'VALID THRU $validThru',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Color(0xFF787B8A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
