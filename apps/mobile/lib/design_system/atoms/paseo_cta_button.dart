import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Tipos de botón de acción principal en el sistema de diseño.
enum PaseoCtaStyle {
  /// Botón dorado sólido de alto impacto para canje.
  gold,

  /// Botón obsidiana oscuro con borde sutil para pago contactless.
  dark,
}

/// Átomo de botón de llamada a la acción con micro-interacción al pulsar.
class PaseoCtaButton extends StatefulWidget {
  /// Crea un botón CTA de lujo.
  const new({
    required this.label,
    required this.onTap,
    super.key,
    this.style = PaseoCtaStyle.gold,
    this.icon,
  });

  /// Texto del botón.
  final String label;

  /// Callback de interacción.
  final VoidCallback onTap;

  /// Estilo visual del botón.
  final PaseoCtaStyle style;

  /// Icono opcional a la izquierda del texto.
  final IconData? icon;

  @override
  State<PaseoCtaButton> createState() => _PaseoCtaButtonState();
}

class _PaseoCtaButtonState extends State<PaseoCtaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) => _controller.forward();
  void _handleTapUp(TapUpDetails details) => _controller.reverse();
  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final isGold = widget.style == PaseoCtaStyle.gold;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: isGold ? const Color(0xFFE5C07B) : const Color(0xFF161822),
            borderRadius: BorderRadius.circular(28),
            border: isGold
                ? null
                : Border.all(
                    color: PaseoColors.goldMetallic.withValues(alpha: 0.25),
                  ),
            boxShadow: isGold
                ? const [
                    BoxShadow(
                      color: Color(0x33E5C07B),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x44000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 19,
                    color: isGold
                        ? PaseoColors.obsidianBlack
                        : const Color(0xFFE5C07B),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                    color: isGold
                        ? PaseoColors.obsidianBlack
                        : PaseoColors.textWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
