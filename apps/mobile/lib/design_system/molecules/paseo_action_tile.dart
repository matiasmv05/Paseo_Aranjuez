import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_icon_container.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_spacing.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Molécula de tarjeta interactiva de acción para configuraciones y servicios.
///
/// Implementa micro-interacciones de presión (escala fluida y resplandor
/// de borde) respetando el diseño VIP Obsidian.
class PaseoActionTile extends StatefulWidget {
  /// Crea una tarjeta de acción interactiva.
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
    this.onTap,
    this.isDestructive = false,
  });

  /// Icono descriptivo de la acción.
  final IconData icon;

  /// Título en alta jerarquía (ej. "Settings").
  final String title;

  /// Descripción de soporte (ej. "Preferences & security").
  final String subtitle;

  /// Callback ejecutado al pulsar la tarjeta.
  final VoidCallback? onTap;

  /// Indica si la acción es de cierre o destructiva (ej. "Log Out").
  final bool isDestructive;

  @override
  State<PaseoActionTile> createState() => _PaseoActionTileState();
}

class _PaseoActionTileState extends State<PaseoActionTile> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _isPressed || _isHovered
        ? PaseoColors.goldMetallic.withValues(alpha: 0.4)
        : PaseoColors.surfaceBorder;

    final cardBackground = _isPressed || _isHovered
        ? PaseoColors.surfaceCardHover
        : PaseoColors.surfaceCard;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: PaseoSpacing.cardPadding,
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(PaseoSpacing.radiusCard),
              border: Border.all(color: borderColor),
              boxShadow: [
                if (_isHovered || _isPressed)
                  BoxShadow(
                    color: PaseoColors.goldPrimary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                // Icono en contenedor circular oscuro
                PaseoIconContainer(
                  icon: widget.icon,
                  iconColor: widget.isDestructive
                      ? const Color(0xFFE57373)
                      : PaseoColors.textWhite,
                ),
                const SizedBox(width: 16),

                // Títulos principal y secundario
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: PaseoTypography.actionTitle.copyWith(
                          color: widget.isDestructive
                              ? const Color(0xFFFF8A80)
                              : PaseoColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: PaseoTypography.actionSubtitle,
                      ),
                    ],
                  ),
                ),

                // Chevron sutil hacia la derecha
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: PaseoColors.textMuted.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
