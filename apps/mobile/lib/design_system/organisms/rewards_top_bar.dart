import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Barra de navegación superior especializada para la sección de Recompensas.
///
/// Refleja la insignia "PASEO REWARDS / REWARDS", el botón de búsqueda y
/// el avatar del miembro.
class RewardsTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Crea la barra superior de recompensas.
  const new({super.key, this.onSearchTap, this.onProfileTap});

  /// Callback emitido al pulsar el botón de búsqueda.
  final VoidCallback? onSearchTap;

  /// Callback emitido al pulsar el avatar.
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
            // Mini tarjeta de membresía / Monograma
            Container(
              width: 32,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: PaseoColors.goldMetallic.withValues(alpha: 0.6),
                ),
                gradient: const LinearGradient(
                  colors: [Color(0xFF262734), Color(0xFF13141C)],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.diamond_outlined,
                  size: 12,
                  color: PaseoColors.goldLight,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Título "PASEO REWARDS" y subtítulo "REWARDS"
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PASEO REWARDS',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: PaseoColors.goldMetallic,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'REWARDS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                      color: PaseoColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Acciones derechas: Búsqueda y Avatar
            Row(
              children: [
                IconButton(
                  onPressed: onSearchTap,
                  tooltip: 'Buscar Beneficios',
                  icon: const Icon(
                    Icons.search,
                    size: 22,
                    color: PaseoColors.textWhite,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onProfileTap,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: PaseoColors.goldMetallic.withValues(alpha: 0.7),
                        width: 1.5,
                      ),
                      color: PaseoColors.surfaceIcon,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/alejandro_avatar.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
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
          ],
        ),
      ),
    );
  }
}
