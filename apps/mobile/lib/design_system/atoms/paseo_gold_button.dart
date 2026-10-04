import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo de botón dorado redondeado de alta gama ("RESERVE").
class PaseoGoldButton extends StatefulWidget {
  /// Crea un botón de reserva con acento dorado y micro-interacción.
  const new({
    required this.label,
    super.key,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  });

  /// Texto del botón en mayúsculas (ej. "RESERVE").
  final String label;

  /// Callback de pulsación.
  final VoidCallback? onPressed;

  /// Relleno interno del botón.
  final EdgeInsets padding;

  @override
  State<PaseoGoldButton> createState() => _PaseoGoldButtonState();
}

class _PaseoGoldButtonState extends State<PaseoGoldButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: const Color(0xFFE5C07B),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: PaseoColors.goldPrimary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: PaseoColors.obsidianBlack,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
