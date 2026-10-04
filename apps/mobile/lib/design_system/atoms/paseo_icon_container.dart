import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo de contenedor para iconos de navegación o acción.
class PaseoIconContainer extends StatelessWidget {
  /// Crea un contenedor oscuro con borde sutil para alojar un icono.
  const new({
    required this.icon,
    super.key,
    this.size = 46,
    this.iconSize = 22,
    this.iconColor = PaseoColors.textWhite,
  });

  /// Icono que se muestra dentro del contenedor.
  final IconData icon;

  /// Diámetro del contenedor.
  final double size;

  /// Tamaño del icono.
  final double iconSize;

  /// Color del icono.
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: PaseoColors.surfaceIcon,
        shape: BoxShape.circle,
        border: Border.all(
          color: PaseoColors.surfaceBorder.withValues(alpha: 0.8),
        ),
      ),
      child: Center(
        child: Icon(icon, size: iconSize, color: iconColor),
      ),
    );
  }
}
