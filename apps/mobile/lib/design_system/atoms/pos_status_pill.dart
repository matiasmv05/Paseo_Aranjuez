import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo de píldora de estatus para terminales POS del comercio.
class PosStatusPill extends StatelessWidget {
  /// Crea una píldora de estado de conexión o sincronización.
  const new({
    required this.label,
    super.key,
    this.dotColor,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.icon,
  });

  /// Texto de la píldora.
  final String label;

  /// Color del punto de estado (opcional).
  final Color? dotColor;

  /// Color del texto.
  final Color? textColor;

  /// Color de fondo del contenedor.
  final Color? backgroundColor;

  /// Color del borde perimetral.
  final Color? borderColor;

  /// Icono opcional al inicio.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF161822),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? PaseoColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                boxShadow: [
                  BoxShadow(
                    color: dotColor!.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor ?? PaseoColors.goldLight),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: textColor ?? const Color(0xFFC7CBD8),
            ),
          ),
        ],
      ),
    );
  }
}
