import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_end_of_ledger.dart';
import 'package:paseo_mobile/design_system/molecules/paseo_history_card.dart';
import 'package:paseo_mobile/design_system/organisms/points_history_header.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Vista de actividad del ledger privado (pantalla "Activity").
///
/// Reproduce con precisión absoluta el diseño de la captura:
/// Encabezado "● MEMBER ACTIVITY / Points History", las tarjetas
/// de Haute Horlogerie Boutique y Boutique Valldemossa, y el pie
/// "END OF RECENT LEDGER".
class ActivityPage extends StatefulWidget {
  /// Crea la pantalla de historial de puntos.
  const new({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage>
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
      duration: const Duration(milliseconds: 700),
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
          // 1. Cabecera "● MEMBER ACTIVITY / Points History"
          const PointsHistoryHeader(),
          const SizedBox(height: 28),

          // 2. Tarjetas de transacciones con entrada escalonada
          FadeTransition(
            opacity: _fade,
            child: Column(
              children: [
                // Tarjeta 1: Haute Horlogerie Boutique (-12,500 PTS)
                SlideTransition(
                  position: _card1Slide,
                  child: PaseoHistoryCard(
                    icon: Icons.watch_outlined,
                    categoryLabel: 'BOUTIQUE TAP',
                    timestamp: 'Today, 14:35',
                    storeName: 'Haute Horlogerie Boutique',
                    serviceDescription: 'Swiss Automatic Watch Service',
                    pointsText: '-12,500',
                    isNegative: true,
                    onTap: () => _showTransactionDetails(
                      context: context,
                      title: 'Haute Horlogerie Boutique',
                      subtitle: 'Swiss Automatic Watch Service',
                      points: '-12,500 PTS',
                      date: 'Today, 14:35',
                      reference: '#TX-88291',
                      category: 'BOUTIQUE TAP',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tarjeta 2: Boutique Valldemossa (+2,400 PTS)
                SlideTransition(
                  position: _card2Slide,
                  child: PaseoHistoryCard(
                    icon: Icons.checkroom_outlined,
                    categoryLabel: 'IN-STORE PURCHASE',
                    timestamp: 'Yesterday, 18:20',
                    storeName: 'Boutique Valldemossa',
                    serviceDescription: 'Cashmere Collection',
                    pointsText: '+2,400',
                    onTap: () => _showTransactionDetails(
                      context: context,
                      title: 'Boutique Valldemossa',
                      subtitle: 'Cashmere Collection',
                      points: '+2,400 PTS',
                      date: 'Yesterday, 18:20',
                      reference: '#TX-88104',
                      category: 'IN-STORE PURCHASE',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // 3. Indicador de fin de historial reciente
          const Center(child: PaseoEndOfLedger()),
        ],
      ),
    );
  }

  void _showTransactionDetails({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String points,
    required String date,
    required String reference,
    required String category,
  }) {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(category, style: PaseoTypography.brandLabel),
                    Text(
                      reference,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PaseoColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: PaseoColors.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: PaseoTypography.actionSubtitle),
                const SizedBox(height: 24),
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
                        'MOVIMIENTO EN LEDGER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: PaseoColors.textMuted,
                        ),
                      ),
                      Text(
                        points,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: PaseoColors.goldLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fecha y Hora:',
                      style: TextStyle(
                        fontSize: 13,
                        color: PaseoColors.textMuted,
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 13,
                        color: PaseoColors.textWhite,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estado:',
                      style: TextStyle(
                        fontSize: 13,
                        color: PaseoColors.textMuted,
                      ),
                    ),
                    Text(
                      'Auditado en Ledger Inmutable',
                      style: TextStyle(
                        fontSize: 13,
                        color: PaseoColors.goldMetallic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
