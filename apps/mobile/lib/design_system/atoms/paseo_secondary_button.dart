import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo de botón secundario (Borde sutil, fondo blanco o transparente).
///
/// Utilizado en acciones como "Continuar con Google", "Cancelar" o filtros.
class PaseoSecondaryButton extends StatefulWidget {
  /// Crea un botón secundario estilizado.
  const new({
    required this.label,
    super.key,
    this.onPressed,
    this.height = 50.0,
    this.icon,
    this.borderColor = PaseoColors.borderLight,
    this.backgroundColor = Colors.white,
    this.textColor = PaseoColors.textDarkPrimary,
  });

  /// Texto del botón.
  final String label;

  /// Callback de pulsación.
  final VoidCallback? onPressed;

  /// Altura del botón.
  final double height;

  /// Widget de icono (por ejemplo logo de Google).
  final Widget? icon;

  /// Color del borde.
  final Color borderColor;

  /// Color de fondo.
  final Color backgroundColor;

  /// Color del texto.
  final Color textColor;

  @override
  State<PaseoSecondaryButton> createState() => _PaseoSecondaryButtonState();
}

class _PaseoSecondaryButtonState extends State<PaseoSecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) {
          if (isEnabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (_isPressed) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (_isPressed) setState(() => _isPressed = false);
        },
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.borderColor, width: 1.2),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                      color: widget.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
