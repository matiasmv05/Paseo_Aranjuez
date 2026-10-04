import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_nfc_beacon.dart';
import 'package:paseo_mobile/design_system/molecules/paseo_curated_reward_card.dart';
import 'package:paseo_mobile/design_system/organisms/curated_privileges_header.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Vista de beneficios y experiencias exclusivas ("Curated Privilèges").
///
/// Reproduce con fidelidad absoluta la captura de pantalla:
/// Encabezado "ATELIER ALLOCATIONS / Curated Privilèges", las tarjetas
/// de Haute Horlogerie y Degustación de Champagne en cava privada,
/// y la barra inferior de balizamiento NFC Concierge Beacon.
class RewardsPage extends StatefulWidget {
  /// Crea la pantalla de beneficios curados.
  const new({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _card1Slide;
  late final Animation<Offset> _card2Slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _card1Slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    _card2Slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabecera "ATELIER ALLOCATIONS / Curated Privilèges"
          const CuratedPrivilegesHeader(),
          const SizedBox(height: 28),

          // 2. Tarjetas de Experiencias con entrada escalonada
          FadeTransition(
            opacity: _fade,
            child: Column(
              children: [
                // Tarjeta 1: Haute Horlogerie Watch Service
                SlideTransition(
                  position: _card1Slide,
                  child: PaseoCuratedRewardCard(
                    categoryTag: 'HAUTE HORLOGERIE',
                    title: 'Swiss Automatic Watch\nService',
                    description:
                        'Comprehensive movement overhaul & ultrasonic '
                        'restoration at Haute Horlogerie Boutique.',
                    requiredPoints: '12,500 PTS',
                    imageAssetPath: 'assets/images/watch_service.jpg',
                    onReserve: () => _showReservationModal(
                      context,
                      'Swiss Automatic Watch Service',
                      '12,500 PTS',
                      'Haute Horlogerie Boutique',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tarjeta 2: Private Cellar Champagne Tasting
                SlideTransition(
                  position: _card2Slide,
                  child: PaseoCuratedRewardCard(
                    categoryTag: 'FINE GASTRONOMY',
                    title: 'Private Cellar Champagne\nTasting',
                    description:
                        'Sommelier flight of rare vintage blanc de blancs '
                        'paired with pristine Imperial Ossetra caviar.',
                    requiredPoints: '4,500 PTS',
                    imageAssetPath: 'assets/images/champagne_tasting.jpg',
                    onReserve: () => _showReservationModal(
                      context,
                      'Private Cellar Champagne Tasting',
                      '4,500 PTS',
                      'Private Cellar Sommelier Reserve',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 3. Sensor de autenticación NFC Concierge Beacon
          const PaseoNfcBeacon(),
        ],
      ),
    );
  }

  void _showReservationModal(
    BuildContext context,
    String privilegeTitle,
    String pointsRequired,
    String atelierName,
  ) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: PaseoColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'CONFIRMACIÓN DE ASIGNACIÓN VIP',
                  style: PaseoTypography.brandLabel,
                ),
                const SizedBox(height: 8),
                Text(
                  privilegeTitle,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: PaseoColors.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(atelierName, style: PaseoTypography.actionSubtitle),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PaseoColors.surfaceIcon,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PaseoColors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PUNTOS A DEDUCIR:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: PaseoColors.textMuted,
                        ),
                      ),
                      Text(
                        pointsRequired,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE5C07B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: PaseoColors.surfaceCard,
                        content: Text(
                          'Privilegio reservado. Presenta tu token NFC '
                          'en $atelierName',
                          style: const TextStyle(color: PaseoColors.goldLight),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5C07B),
                    foregroundColor: PaseoColors.obsidianBlack,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'CONFIRMAR RESERVA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
