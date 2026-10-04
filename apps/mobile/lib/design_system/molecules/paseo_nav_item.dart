import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Molécula de elemento para la barra de navegación inferior.
class PaseoNavItem extends StatelessWidget {
  /// Crea un botón de pestaña con animaciones de selección.
  const new({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  /// Icono representativo de la sección.
  final IconData icon;

  /// Etiqueta en mayúsculas ("CLUB", "REWARDS", etc.).
  final String label;

  /// Si la pestaña actual está seleccionada.
  final bool isSelected;

  /// Callback de pulsación.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = PaseoColors.goldLight;
    final inactiveColor = PaseoColors.textMuted.withValues(alpha: 0.5);

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono animado con escala suave al activarse
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 6),

            // Texto con color y estilo
            Text(
              label,
              style: PaseoTypography.navLabel.copyWith(
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),

            // Pequeño indicador dorado inferior para la pestaña activa
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isSelected ? 4 : 0,
              height: isSelected ? 4 : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? PaseoColors.goldMetallic
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
