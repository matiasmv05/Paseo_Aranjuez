import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_shimmer.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Organismo de tarjeta digital de socio VIP con saldo y QR dinámico.
class ClubPassCard extends StatefulWidget {
  /// Crea la tarjeta digital de membresía.
  const new({
    required this.memberName,
    required this.memberCode,
    required this.pointsBalance,
    super.key,
  });

  /// Nombre del socio.
  final String memberName;

  /// Código único del socio (#ARJ-9921).
  final String memberCode;

  /// Saldo actual de puntos del cliente.
  final int pointsBalance;

  @override
  State<ClubPassCard> createState() => _ClubPassCardState();
}

class _ClubPassCardState extends State<ClubPassCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: PaseoColors.metalCardGradient,
        border: Border.all(
          color: PaseoColors.goldMetallic.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: PaseoColors.goldPrimary.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          const BoxShadow(
            color: Color(0x88000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Resplandor de fondo metálico
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      PaseoColors.goldMetallic.withValues(alpha: 0.2),
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
                  // Cabecera de la tarjeta: Chip VIP + Monograma
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.diamond_outlined,
                            size: 18,
                            color: PaseoColors.goldLight,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'VIP OBSIDIAN PASS',
                            style: PaseoTypography.brandLabel.copyWith(
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: PaseoColors.goldMetallic.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: PaseoColors.goldMetallic.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Text(
                          widget.memberCode,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: PaseoColors.goldLight,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Saldo de puntos destacado con shimmer
                  Text(
                    'SALDO DISPONIBLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                      color: PaseoColors.textMuted.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  PaseoShimmer(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${widget.pointsBalance}',
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: PaseoColors.goldLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PTS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: PaseoColors.goldMetallic.withValues(
                              alpha: 0.9,
                            ),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pie de tarjeta: Nombre y botón de QR dinámico
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TITULAR',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: PaseoColors.textMuted.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.memberName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: PaseoColors.textWhite,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),

                      // Botón para desplegar el QR de identificación
                      InkWell(
                        onTap: () => _openQrDialog(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: PaseoColors.goldMetallic,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: PaseoColors.goldPrimary.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                size: 18,
                                color: PaseoColors.obsidianBlack,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'QR PASS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: PaseoColors.obsidianBlack,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openQrDialog(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: PaseoColors.surfaceCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PaseoColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'TOKEN DE IDENTIFICACIÓN',
                  style: PaseoTypography.brandLabel,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Muestra este código en caja para acumular o canjear',
                  textAlign: TextAlign.center,
                  style: PaseoTypography.actionSubtitle,
                ),
                const SizedBox(height: 24),

                // Contenedor del QR simulado (~60s token)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: PaseoColors.goldPrimary.withValues(alpha: 0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    size: 160,
                    color: PaseoColors.obsidianBlack,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: PaseoColors.goldMetallic,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Se actualiza automáticamente cada 60s',
                      style: TextStyle(
                        fontSize: 12,
                        color: PaseoColors.goldMetallic.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
