import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Átomo de botón píldora dorado de alta gama ("Comenzar").
///
/// Implementa micro-interacciones táptiles mediante escalado suave,
/// degradado champán cálido con halo áurico y soporte completo de
/// accesibilidad.
class PaseoWelcomeButton extends StatefulWidget {
  /// Crea un botón de bienvenida en formato píldora.
  const new({
    required this.label,
    super.key,
    this.onPressed,
    this.height = 56.0,
    this.isLoading = false,
  });

  /// Texto a desplegar en el botón (por defecto "Comenzar").
  final String label;

  /// Callback ejecutado al pulsar el botón.
  final VoidCallback? onPressed;

  /// Altura fija del botón.
  final double height;

  /// Si muestra un indicador de carga circular en oro oscuro.
  final bool isLoading;

  @override
  State<PaseoWelcomeButton> createState() => _PaseoWelcomeButtonState();
}

class _PaseoWelcomeButtonState extends State<PaseoWelcomeButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.onPressed != null && !widget.isLoading,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: PaseoColors.champagnePillGradient,
              borderRadius: BorderRadius.circular(widget.height / 2),
              boxShadow: [
                BoxShadow(
                  color: PaseoColors.champagneDark.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: PaseoColors.champagneLight.withValues(alpha: 0.20),
                  blurRadius: 6,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          PaseoColors.champagneTextDark,
                        ),
                      ),
                    )
                  : Text(widget.label, style: PaseoTypography.welcomeButton),
            ),
          ),
        ),
      ),
    );
  }
}
