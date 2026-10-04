import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/molecules/admin_header_bar.dart';
import 'package:paseo_mobile/design_system/organisms/admin_sidebar.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Plantilla base del panel de control ejecutivo de administración (Template).
class AdminDashboardTemplate extends StatelessWidget {
  /// Crea la estructura responsiva con barra lateral fija y contenido
  /// scrollable.
  const new({
    required this.body,
    this.selectedNavIndex = 0,
    this.onNavIndexChanged,
    this.onSearchTap,
    this.onNotificationsTap,
    this.onProfileTap,
    super.key,
  });

  /// Contenido principal del cuerpo del dashboard.
  final Widget body;

  /// Índice seleccionado en la barra lateral.
  final int selectedNavIndex;

  /// Callback de navegación lateral.
  final ValueChanged<int>? onNavIndexChanged;

  /// Callback de búsqueda.
  final VoidCallback? onSearchTap;

  /// Callback de notificaciones.
  final VoidCallback? onNotificationsTap;

  /// Callback de perfil de usuario.
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaseoColors.obsidianDark,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          return Row(
            children: [
              // Barra lateral fija para pantallas de escritorio
              if (isDesktop)
                AdminSidebar(
                  selectedIndex: selectedNavIndex,
                  onItemSelected: onNavIndexChanged,
                ),

              // Área de trabajo principal
              Expanded(
                child: Column(
                  children: [
                    AdminHeaderBar(
                      onSearchTap: onSearchTap,
                      onNotificationsTap: onNotificationsTap,
                      onProfileTap: onProfileTap,
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF0F1017), Color(0xFF090A0E)],
                          ),
                        ),
                        child: body,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
