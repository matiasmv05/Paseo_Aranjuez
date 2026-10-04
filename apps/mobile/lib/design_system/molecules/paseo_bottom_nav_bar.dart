import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Molécula de barra de navegación inferior oficial (5 pestañas).
///
/// Gestiona la transición entre: Inicio, Beneficios, Escanear,
/// Promociones y Perfil.
class PaseoBottomNavBar extends StatelessWidget {
  /// Crea la barra de navegación inferior.
  const new({required this.currentIndex, required this.onTap, super.key});

  /// Pestaña actualmente seleccionada (0 a 4).
  final int currentIndex;

  /// Callback al seleccionar una pestaña.
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: PaseoColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                label: 'Inicio',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
              ),
              _buildNavItem(
                index: 1,
                label: 'Beneficios',
                icon: Icons.card_giftcard_outlined,
                activeIcon: Icons.card_giftcard_rounded,
              ),
              _buildNavItem(
                index: 2,
                label: 'Escanear',
                icon: Icons.qr_code_scanner_rounded,
                activeIcon: Icons.qr_code_scanner_rounded,
              ),
              _buildNavItem(
                index: 3,
                label: 'Promociones',
                icon: Icons.local_offer_outlined,
                activeIcon: Icons.local_offer_rounded,
              ),
              _buildNavItem(
                index: 4,
                label: 'Perfil',
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? PaseoColors.primaryNavy
        : const Color(0xFF9EACB9);

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
