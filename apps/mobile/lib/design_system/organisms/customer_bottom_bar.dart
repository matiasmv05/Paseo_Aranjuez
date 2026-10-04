import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/molecules/paseo_nav_item.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Organismo de barra de navegación inferior para el cliente final.
///
/// Aloja las 4 pestañas oficiales: CLUB, REWARDS, ACTIVITY y PROFILE.
class CustomerBottomBar extends StatelessWidget {
  /// Crea la barra de navegación inferior.
  const new({
    required this.currentIndex,
    required this.onTabSelected,
    super.key,
  });

  /// Índice de la pestaña actualmente activa (0 a 3).
  final int currentIndex;

  /// Callback emitido cuando el usuario selecciona una pestaña.
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PaseoColors.obsidianDark.withValues(alpha: 0.96),
        border: const Border(
          top: BorderSide(color: PaseoColors.surfaceBorder, width: 0.7),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 0: CLUB
              PaseoNavItem(
                icon: Icons.star_outline_rounded,
                label: 'CLUB',
                isSelected: currentIndex == 0,
                onTap: () => onTabSelected(0),
              ),

              // 1: REWARDS
              PaseoNavItem(
                icon: Icons.local_offer_outlined,
                label: 'REWARDS',
                isSelected: currentIndex == 1,
                onTap: () => onTabSelected(1),
              ),

              // 2: ACTIVITY
              PaseoNavItem(
                icon: Icons.history_rounded,
                label: 'ACTIVITY',
                isSelected: currentIndex == 2,
                onTap: () => onTabSelected(2),
              ),

              // 3: PROFILE
              PaseoNavItem(
                icon: Icons.person_outline_rounded,
                label: 'PROFILE',
                isSelected: currentIndex == 3,
                onTap: () => onTabSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
