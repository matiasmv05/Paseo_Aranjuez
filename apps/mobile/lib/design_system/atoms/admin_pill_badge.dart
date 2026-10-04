import 'package:flutter/material.dart';

/// Píldora de estado o insignia informativa para el panel ejecutivo.
class AdminPillBadge extends StatelessWidget {
  /// Crea una píldora con texto e indicador opcional.
  const new({
    required this.label,
    this.dotColor,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    this.fontSize = 11,
    this.icon,
    this.onTap,
    super.key,
  });

  /// Texto mostrado dentro de la píldora.
  final String label;

  /// Color del indicador de punto luminoso (si existe).
  final Color? dotColor;

  /// Color del texto de la píldora.
  final Color? textColor;

  /// Color de fondo del contenedor.
  final Color? backgroundColor;

  /// Color del borde exterior.
  final Color? borderColor;

  /// Padding interno.
  final EdgeInsetsGeometry padding;

  /// Tamaño de fuente tipográfica.
  final double fontSize;

  /// Icono opcional que precede al texto.
  final Widget? icon;

  /// Callback de interacción al pulsar la píldora.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? const Color(0xFFC7CAD6);
    final effectiveBgColor = backgroundColor ?? const Color(0xFF141620);
    final effectiveBorderColor = borderColor ?? const Color(0xFF262838);

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: effectiveBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor!.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (icon != null) ...[icon!, const SizedBox(width: 6)],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: effectiveTextColor,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: content,
      );
    }

    return content;
  }
}
