import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Molécula para los botones de acción rápida y perfil en el encabezado.
class PaseoHeaderUserTile extends StatelessWidget {
  /// Crea el conjunto de acciones derechas de la barra superior.
  const new({super.key, this.onConciergeTap, this.onProfileTap, this.imageUrl});

  /// Acción al pulsar el botón de conserjería / mayordomo.
  final VoidCallback? onConciergeTap;

  /// Acción al pulsar el avatar compacto.
  final VoidCallback? onProfileTap;

  /// URL de imagen opcional.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón de notificaciones / avisos VIP
        IconButton(
          onPressed: onConciergeTap,
          tooltip: 'Notificaciones',
          icon: const Icon(
            Icons.notifications_none_rounded,
            size: 24,
            color: PaseoColors.textWhite,
          ),
        ),
        const SizedBox(width: 8),

        // Mini avatar con aro dorado y foto del socio
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
              boxShadow: [
                BoxShadow(
                  color: PaseoColors.goldPrimary.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/alejandro_avatar.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const ColoredBox(
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
    );
  }
}
