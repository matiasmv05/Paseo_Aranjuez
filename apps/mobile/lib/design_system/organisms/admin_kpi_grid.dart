import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/molecules/admin_kpi_card.dart';

/// Cuadrícula con las 3 tarjetas de métricas clave ejecutivas (Organismo).
class AdminKpiGrid extends StatelessWidget {
  /// Crea la cuadrícula de métricas clave para el panel directivo.
  const new({
    this.totalUsers = '18,420',
    this.usersGrowth = '12.4%',
    this.tierBreakdown = '2,140 Black Tier • 16,280 Gold',
    this.pointsToday = '48,290',
    this.usdEquivalent = r'~$4,829 USD',
    this.circulatingRatio = '94.2% Circulating Ratio',
    this.activeStores = '54',
    this.storesCoverage = '100% estate coverage across all wings',
    this.terminalsOnline = '54 / 54 Online',
    super.key,
  });

  /// Total de usuarios activos registrados.
  final String totalUsers;

  /// Crecimiento porcentual este mes.
  final String usersGrowth;

  /// Desglose por niveles VIP.
  final String tierBreakdown;

  /// Puntos emitidos en el día corriente.
  final String pointsToday;

  /// Equivalente en dólares americanos.
  final String usdEquivalent;

  /// Ratio de circulación y canje.
  final String circulatingRatio;

  /// Comercios y boutiques activas en el complejo.
  final String activeStores;

  /// Cobertura de tiendas en las alas comerciales.
  final String storesCoverage;

  /// Estado de sincronización de terminales.
  final String terminalsOnline;

  @override
  Widget build(BuildContext context) {
    final card1 = AdminKpiCard(
      title: 'TOTAL USERS',
      icon: Icons.person_outline_rounded,
      value: totalUsers,
      highlightWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.arrow_upward_rounded,
            size: 13,
            color: Color(0xFFE5C07B),
          ),
          const SizedBox(width: 3),
          Text(
            usersGrowth,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE5C07B),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'this month',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF787B8A),
            ),
          ),
        ],
      ),
      metaLabel: 'TIER BREAKDOWN',
      metaValue: tierBreakdown,
    );

    final card2 = AdminKpiCard(
      title: 'POINTS ISSUED TODAY',
      icon: Icons.monetization_on_outlined,
      value: pointsToday,
      valueSuffix: 'PTS',
      valueColor: const Color(0xFFE5C07B),
      highlightWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Valued at',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF787B8A),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            usdEquivalent,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFC7CBD8),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'equivalent',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF787B8A),
            ),
          ),
        ],
      ),
      metaLabel: 'REDEMPTION RATE',
      metaValue: circulatingRatio,
    );

    final card3 = AdminKpiCard(
      title: 'ACTIVE STORES',
      icon: Icons.storefront_outlined,
      value: activeStores,
      valueSuffix: 'STORES',
      highlightWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFFE5C07B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              storesCoverage,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9EA2B3),
              ),
            ),
          ),
        ],
      ),
      metaLabel: 'TERMINAL SYNC',
      metaValue: terminalsOnline,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: 18),
              Expanded(child: card2),
              const SizedBox(width: 18),
              Expanded(child: card3),
            ],
          );
        }

        return Column(
          children: [
            card1,
            const SizedBox(height: 14),
            card2,
            const SizedBox(height: 14),
            card3,
          ],
        );
      },
    );
  }
}
