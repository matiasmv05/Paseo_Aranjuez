import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Átomo de enlace textual subrayado ("Iniciar sesión").
///
/// Proporciona micro-interacción de opacidad al pulsar, con soporte de
/// accesibilidad.
class PaseoTextLink extends StatefulWidget {
  /// Crea un enlace de texto subrayado.
  const new({required this.text, super.key, this.onPressed, this.style});

  /// Texto del enlace.
  final String text;

  /// Callback de pulsación.
  final VoidCallback? onPressed;

  /// Estilo tipográfico opcional (por defecto [PaseoTypography.welcomeLink]).
  final TextStyle? style;

  @override
  State<PaseoTextLink> createState() => _PaseoTextLinkState();
}

class _PaseoTextLinkState extends State<PaseoTextLink> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = widget.style ?? PaseoTypography.welcomeLink;

    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.text,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AnimatedOpacity(
            opacity: _isPressed ? 0.6 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Text(
              widget.text,
              style: effectiveStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
