import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo de botón principal institucional (Navy profundo, texto blanco).
///
/// Utilizado en acciones prioritarias como "Iniciar sesión", "Canjear",
/// "Confirmar" y "Volver a beneficios".
class PaseoPrimaryButton extends StatefulWidget {
  /// Crea un botón primario con micro-interacción de escala.
  const new({
    required this.label,
    super.key,
    this.onPressed,
    this.height = 50.0,
    this.isLoading = false,
    this.backgroundColor = PaseoColors.primaryNavy,
    this.textColor = Colors.white,
    this.icon,
  });

  /// Texto a desplegar en el botón.
  final String label;

  /// Callback al presionar el botón.
  final VoidCallback? onPressed;

  /// Altura fija del botón.
  final double height;

  /// Si muestra un indicador de carga.
  final bool isLoading;

  /// Color de fondo del botón.
  final Color backgroundColor;

  /// Color del texto.
  final Color textColor;

  /// Icono opcional a la izquierda del texto.
  final IconData? icon;

  @override
  State<PaseoPrimaryButton> createState() => _PaseoPrimaryButtonState();
}

class _PaseoPrimaryButtonState extends State<PaseoPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

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
              color: isEnabled
                  ? widget.backgroundColor
                  : widget.backgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (isEnabled)
                  BoxShadow(
                    color: widget.backgroundColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: widget.textColor, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
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
