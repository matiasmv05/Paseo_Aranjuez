import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Barra de navegación superior especializada para la pantalla VIP Club.
///
/// Muestra la insignia "PASEO / POINTS CLUB", la campana de notificaciones
/// y la miniatura fotográfica del socio VIP.
class ClubTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Crea la barra superior del club VIP.
  const new({super.key, this.onNotificationTap, this.onProfileTap});

  /// Acción al pulsar la campana de avisos.
  final VoidCallback? onNotificationTap;

  /// Acción al pulsar la miniatura del perfil.
  final VoidCallback? onProfileTap;

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            // Monograma circular de Paseo
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: PaseoColors.goldMetallic.withValues(alpha: 0.6),
                ),
                gradient: const RadialGradient(
                  colors: [Color(0xFF2E2F3B), Color(0xFF14151C)],
                ),
              ),
              child: const Center(
                child: Text(
                  'P',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: PaseoColors.goldLight,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Título "PASEO" y subtítulo "POINTS CLUB"
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PASEO',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Color(0xFFE5C07B),
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'POINTS CLUB',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: Color(0xFFC7CBD8),
                    ),
                  ),
                ],
              ),
            ),

            // Acciones derechas: Notificaciones y Foto de perfil
            IconButton(
              onPressed: onNotificationTap,
              tooltip: 'Notificaciones',
              icon: const Icon(
                Icons.notifications_none_rounded,
                size: 24,
                color: PaseoColors.textWhite,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: PaseoColors.goldMetallic.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/alejandro_avatar.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(
                          color: PaseoColors.surfaceIcon,
                          child: Icon(
                            Icons.person,
                            size: 20,
                            color: PaseoColors.goldLight,
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
