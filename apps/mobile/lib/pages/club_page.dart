import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_cta_button.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_vip_pill.dart';
import 'package:paseo_mobile/design_system/organisms/membership_pass_card.dart';
import 'package:paseo_mobile/design_system/organisms/nfc_payment_sheet.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Pantalla principal de socio VIP ("PASEO POINTS CLUB").
///
/// Reproduce exactamente la captura de pantalla oficial:
/// - Saludo: "Good evening, Alejandro" con insignia VIP OBSIDIAN (#ARJ-9921).
/// - Tarjeta de membresía con saldo acumulado: "3,450 PTS"
///   (€345 en 54 tiendas).
/// - Progreso de nivel: "550 PTS TO SOVEREIGN TIER".
/// - Botones de acción: "REDEEM PRIVILÈGES  →" y "TAP TO PAY (NFC READY)".
class ClubPage extends StatefulWidget {
  /// Crea la pantalla VIP Club.
  const new({super.key, this.onRedeemTap});

  /// Callback emitido al pulsar el botón de canje de privilegios.
  final VoidCallback? onRedeemTap;

  @override
  State<ClubPage> createState() => _ClubPageState();
}

class _ClubPageState extends State<ClubPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fade;
  late final Animation<Offset> _heroSlide;
  late final Animation<Offset> _cardSlide;
  late final Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
          ),
        );

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.2, 0.75, curve: Curves.easeOutCubic),
          ),
        );

    _buttonsSlide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.4, 0.95, curve: Curves.easeOutCubic),
          ),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
      child: FadeTransition(
        opacity: _fade,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero: Saludo y Píldora VIP
            SlideTransition(
              position: _heroSlide,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PASEO ARANJUEZ PRIVILÈGES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                      color: Color(0xFFE5C07B),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Good evening,\nAlejandro',
                          style: PaseoTypography.greetingTitle,
                        ),
                      ),
                      PaseoVipPill(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Tarjeta principal de membresía (Membership Pass)
            SlideTransition(
              position: _cardSlide,
              child: const MembershipPassCard(),
            ),
            const SizedBox(height: 24),

            // 3. Botones de acción CTA
            SlideTransition(
              position: _buttonsSlide,
              child: Column(
                children: [
                  // Botón 1: Canje de privilegios
                  PaseoCtaButton(
                    label: 'REDEEM PRIVILÈGES  →',
                    onTap: () {
                      if (widget.onRedeemTap != null) {
                        widget.onRedeemTap!();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: PaseoColors.surfaceCard,
                            content: Text(
                              'Accediendo al catálogo de beneficios curados...',
                              style: TextStyle(color: PaseoColors.goldLight),
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Botón 2: Tap to Pay con sensor NFC
                  PaseoCtaButton(
                    label: 'TAP TO PAY (NFC READY)',
                    style: PaseoCtaStyle.dark,
                    icon: Icons.contactless_outlined,
                    onTap: () {
                      unawaited(NfcPaymentSheet.show(context));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
