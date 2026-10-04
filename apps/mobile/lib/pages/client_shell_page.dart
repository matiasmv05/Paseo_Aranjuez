import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/molecules/paseo_bottom_nav_bar.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/pages/benefits_page.dart';
import 'package:paseo_mobile/pages/home_dashboard_page.dart';
import 'package:paseo_mobile/pages/profile_page.dart';
import 'package:paseo_mobile/pages/promotions_page.dart';
import 'package:paseo_mobile/pages/qr_page.dart';

/// Contenedor maestro de navegación del cliente móvil (Paseo Points).
///
/// Aloja las 5 pantallas principales según el mockup oficial:
/// - 0: Inicio / Dashboard ([HomeDashboardPage])
/// - 1: Beneficios ([BenefitsPage])
/// - 2: Escanear / Mi QR ([QrPage])
/// - 3: Promociones ([PromotionsPage])
/// - 4: Perfil ([ProfilePage])
class ClientShellPage extends StatefulWidget {
  /// Crea el shell de navegación del cliente.
  const new({super.key, this.initialTab = 0});

  /// Pestaña inicial a mostrar (por defecto 0: Inicio).
  final int initialTab;

  @override
  State<ClientShellPage> createState() => _ClientShellPageState();
}

class _ClientShellPageState extends State<ClientShellPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaseoColors.bgLight,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeDashboardPage(onNavigateToTab: _onTabSelected),
          const BenefitsPage(),
          const QrPage(showBackButton: false),
          const PromotionsPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: PaseoBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
