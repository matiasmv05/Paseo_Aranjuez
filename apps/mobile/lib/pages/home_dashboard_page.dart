import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paseo_mobile/data/mock/mock_data.dart';
import 'package:paseo_mobile/design_system/molecules/benefit_list_card.dart';
import 'package:paseo_mobile/design_system/molecules/paseo_points_card.dart';
import 'package:paseo_mobile/design_system/organisms/notifications_sheet.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/pages/benefit_detail_page.dart';
import 'package:paseo_mobile/pages/establishments_page.dart';
import 'package:paseo_mobile/pages/points_history_page.dart';
import 'package:paseo_mobile/pages/promotions_page.dart';

/// Pantalla 3: Inicio / Dashboard principal de Paseo Points.
class HomeDashboardPage extends StatelessWidget {
  /// Crea el dashboard principal.
  const new({required this.onNavigateToTab, super.key});

  /// Callback para conmutar a otra pestaña del Shell (0: Inicio, 1: Beneficios,
  /// 2: QR, etc.).
  final ValueChanged<int> onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    const user = MockData.currentUser;
    final topBenefit = MockData.benefits.first;
    const topPromo = MockData.promotions;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // 1. Saludo superior y campana de notificaciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, Valentina 👋',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: PaseoColors.textDarkPrimary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Disfruta todos los beneficios de Paseo Aranjuez',
                    style: TextStyle(
                      fontSize: 12,
                      color: PaseoColors.textDarkSecondary,
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: PaseoColors.textDarkPrimary,
                      size: 24,
                    ),
                    onPressed: () {
                      unawaited(
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const NotificationsSheet(),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    right: 12,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4AF37),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Tarjeta principal de Paseo Points
          GestureDetector(
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const PointsHistoryPage()),
              );
            },
            child: PaseoPointsCard(
              points: user.balance,
              onShowQr: () => onNavigateToTab(2), // Navega a la pestaña de QR
            ),
          ),
          const SizedBox(height: 20),

          // 3. Sección: Beneficios para ti
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Beneficios para ti',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: PaseoColors.textDarkPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => onNavigateToTab(1), // Pestaña Beneficios
                child: const Text(
                  'Ver todos >',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PaseoColors.textDarkSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          BenefitListCard(
            benefit: topBenefit,
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => BenefitDetailPage(benefit: topBenefit),
                ),
              );
            },
          ),
          const SizedBox(height: 22),

          // 4. Sección: Promociones vigentes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Promociones vigentes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: PaseoColors.textDarkPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => onNavigateToTab(3), // Pestaña Promociones
                child: const Text(
                  'Ver todos >',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PaseoColors.textDarkSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (topPromo.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const PromotionsPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: PaseoColors.borderLight,
                    width: 1.1,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        topPromo.first.imageAsset,
                        width: 76,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topPromo.first.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: PaseoColors.textDarkPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFECE8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              topPromo.first.badge,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD94A38),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: PaseoColors.textPlaceholder,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 22),

          // 5. Sección: Establecimientos participantes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Establecimientos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: PaseoColors.textDarkPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const EstablishmentsPage(),
                    ),
                  );
                },
                child: const Text(
                  'Ver todos >',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PaseoColors.textDarkSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: MockData.establishments.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final est = MockData.establishments[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => const EstablishmentsPage(),
                      ),
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: PaseoColors.borderLight,
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        est.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            ColoredBox(
                              color: PaseoColors.primaryNavy,
                              child: Center(
                                child: Text(
                                  est.name.substring(0, 1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
