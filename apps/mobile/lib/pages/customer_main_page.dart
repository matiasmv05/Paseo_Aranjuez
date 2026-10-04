import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/organisms/club_top_bar.dart';
import 'package:paseo_mobile/design_system/organisms/customer_bottom_bar.dart';
import 'package:paseo_mobile/design_system/organisms/customer_top_bar.dart';
import 'package:paseo_mobile/design_system/organisms/rewards_top_bar.dart';
import 'package:paseo_mobile/design_system/templates/customer_scaffold_template.dart';
import 'package:paseo_mobile/pages/activity_page.dart';
import 'package:paseo_mobile/pages/club_page.dart';
import 'package:paseo_mobile/pages/profile_page.dart';
import 'package:paseo_mobile/pages/rewards_page.dart';

/// Pantalla contenedora principal para el cliente final de Paseo Points.
class CustomerMainPage extends StatefulWidget {
  /// Crea la pantalla principal del cliente.
  const new({
    super.key,
    this.initialIndex = 0, // Pestaña CLUB activa según la pantalla de inicio
  });

  /// Índice inicial de la pestaña seleccionada.
  final int initialIndex;

  @override
  State<CustomerMainPage> createState() => _CustomerMainPageState();
}

class _CustomerMainPageState extends State<CustomerMainPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  String get _currentTitle {
    switch (_currentIndex) {
      case 0:
        return 'VIP Club';
      case 1:
        return 'Rewards';
      case 2:
        return 'Activity';
      case 3:
      default:
        return 'Profile';
    }
  }

  PreferredSizeWidget get _currentTopBar {
    if (_currentIndex == 0) {
      return ClubTopBar(
        onNotificationTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No tienes notificaciones pendientes.'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        onProfileTap: () {
          setState(() => _currentIndex = 3);
        },
      );
    }
    if (_currentIndex == 1) {
      return RewardsTopBar(
        onSearchTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Búsqueda en catálogo de Atelier...'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        onProfileTap: () {
          setState(() => _currentIndex = 3);
        },
      );
    }
    return CustomerTopBar(
      title: _currentTitle,
      onConciergeTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conectando con la línea privada de conserjería...'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      onProfileTap: () {
        setState(() => _currentIndex = 3);
      },
    );
  }

  Widget get _currentBody {
    switch (_currentIndex) {
      case 0:
        return ClubPage(
          onRedeemTap: () {
            setState(() => _currentIndex = 1);
          },
        );
      case 1:
        return const RewardsPage();
      case 2:
        return const ActivityPage();
      case 3:
      default:
        return const ProfilePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomerScaffoldTemplate(
      topBar: _currentTopBar,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _currentBody,
        ),
      ),
      bottomBar: CustomerBottomBar(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
