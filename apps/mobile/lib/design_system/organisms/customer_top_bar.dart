import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/molecules/paseo_header_user_tile.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Organismo de barra superior para clientes VIP de Paseo Points.
class CustomerTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Crea la barra de navegación superior.
  const new({
    required this.title,
    super.key,
    this.onConciergeTap,
    this.onProfileTap,
  });

  /// Título de la vista actual ("Activity", "Profile", "Club", etc.).
  final String title;

  /// Acción al presionar el icono de conserjería.
  final VoidCallback? onConciergeTap;

  /// Acción al presionar el avatar compacto.
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
            // Monograma circular de Paseo Points
            Container(
              width: 28,
              height: 28,
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

            // Título de la marca y título de la pantalla
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PASEO POINTS', style: PaseoTypography.brandLabel),
                  Text(title, style: PaseoTypography.screenTitle),
                ],
              ),
            ),

            // Acciones superiores (conserjería y avatar)
            PaseoHeaderUserTile(
              onConciergeTap: onConciergeTap,
              onProfileTap: onProfileTap,
            ),
          ],
        ),
      ),
    );
  }
}
