import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Barra superior del panel ejecutivo de administración (Molécula).
class AdminHeaderBar extends StatelessWidget {
  /// Crea la cabecera superior con migas de pan, búsqueda y perfil de admin.
  const new({
    this.section = 'EXECUTIVE',
    this.currentView = 'Overview',
    this.adminName = 'Alejandro Silva',
    this.adminRole = 'ADMIN',
    this.avatarAssetPath = 'assets/images/alejandro_silva_avatar.jpg',
    this.onSearchTap,
    this.onNotificationsTap,
    this.onProfileTap,
    super.key,
  });

  /// Sección raíz del módulo.
  final String section;

  /// Vista activa actual.
  final String currentView;

  /// Nombre del directivo o administrador autenticado.
  final String adminName;

  /// Rol asignado en la plataforma.
  final String adminRole;

  /// Ruta al avatar de usuario.
  final String avatarAssetPath;

  /// Callback al pulsar la búsqueda.
  final VoidCallback? onSearchTap;

  /// Callback al pulsar las notificaciones.
  final VoidCallback? onNotificationsTap;

  /// Callback al pulsar el perfil.
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0C11),
        border: Border(bottom: BorderSide(color: Color(0xFF1A1C26))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Migas de pan de navegación ejecutiva
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  section,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: Color(0xFF787B8A),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '/',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF3F4252),
                    ),
                  ),
                ),
                Text(
                  currentView,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0xFFE5C07B),
                  ),
                ),
              ],
            ),
          ),

          // 2. Acciones: Búsqueda, Notificaciones y Perfil Directivo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón de búsqueda
              _HeaderIconButton(
                icon: Icons.search_rounded,
                tooltip: 'Buscar transacciones, tiendas o usuarios',
                onTap: onSearchTap,
              ),
              const SizedBox(width: 12),

              // Botón de notificaciones con insignia
              _HeaderIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Alertas y notificaciones ejecutivas',
                hasBadge: true,
                onTap: onNotificationsTap,
              ),
              const SizedBox(width: 20),

              // Divisor vertical
              Container(height: 28, width: 1, color: const Color(0xFF232533)),
              const SizedBox(width: 20),

              // Perfil de Alejandro Silva (Admin)
              InkWell(
                onTap: onProfileTap,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            adminName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: PaseoColors.textWhite,
                            ),
                          ),
                          Text(
                            adminRole,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.3,
                              color: Color(0xFFC5A059),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFD4AF37)
                                .withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37)
                                  .withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            avatarAssetPath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.person_rounded,
                                  size: 20,
                                  color: Color(0xFFE5C07B),
                                ),
                          ),
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
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    this.hasBadge = false,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool hasBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF13151D),
            border: Border.all(color: const Color(0xFF232533)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF8A8D9E)),
              if (hasBadge)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5C07B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
