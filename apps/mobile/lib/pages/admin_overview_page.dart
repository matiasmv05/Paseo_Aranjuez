import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/admin_pill_badge.dart';
import 'package:paseo_mobile/design_system/organisms/admin_kpi_grid.dart';
import 'package:paseo_mobile/design_system/organisms/admin_transaction_chart.dart';
import 'package:paseo_mobile/design_system/templates/admin_dashboard_template.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Pantalla ejecutiva general de administración (Executive Overview).
class AdminOverviewPage extends StatefulWidget {
  /// Crea la pantalla principal del panel directivo con analítica en vivo.
  const new({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  int _selectedNavIndex = 0;
  bool _isRefreshing = false;

  void _handleRefreshFeed() {
    setState(() => _isRefreshing = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isRefreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF161822),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF2E3144)),
            ),
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFFE5C07B),
                  size: 18,
                ),
                SizedBox(width: 10),
                Text(
                  'Datos ejecutivos sincronizados con el ledger privado.',
                  style: TextStyle(color: PaseoColors.textWhite, fontSize: 13),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminDashboardTemplate(
      selectedNavIndex: _selectedNavIndex,
      onNavIndexChanged: (index) {
        setState(() => _selectedNavIndex = index);
      },
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cabecera ejecutiva con fecha y acción de refresco
            _buildExecutiveHeader(),
            const SizedBox(height: 24),

            // 2. Cuadrícula de 3 métricas clave (Total Users, Points, Stores)
            const AdminKpiGrid(),
            const SizedBox(height: 24),

            // 3. Tarjeta central de actividad analítica con curva spline
            const AdminTransactionChart(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PASEO POINTS INTELLIGENCE • LIVE NODE 01',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: Color(0xFF787B8A),
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;

            const titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Executive Overview',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: PaseoColors.textWhite,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Real-time loyalty volume, active participants, and daily '
                  'issuance dynamics across Paseo Aranjuez.',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(fontSize: 12, color: Color(0xFF787B8A)),
                ),
              ],
            );

            final actionsBlock = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AdminPillBadge(
                  label: 'TODAY • OCT 24',
                  dotColor: Color(0xFFE5C07B),
                  textColor: Color(0xFFE5C07B),
                ),
                const SizedBox(width: 10),
                AdminPillBadge(
                  label: 'REFRESH FEED',
                  textColor: const Color(0xFFC7CAD6),
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFE5C07B),
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.sync_rounded,
                          size: 13,
                          color: Color(0xFF8A8D9E),
                        ),
                  onTap: _handleRefreshFeed,
                ),
              ],
            );

            if (isWide) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(child: titleBlock),
                  const SizedBox(width: 16),
                  actionsBlock,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleBlock, const SizedBox(height: 14), actionsBlock],
            );
          },
        ),
      ],
    );
  }
}
