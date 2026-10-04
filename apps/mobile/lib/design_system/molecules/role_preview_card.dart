import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Molécula de tarjeta de selección rápida de rol o vista del sistema.
class RolePreviewCard extends StatefulWidget {
  /// Crea una tarjeta de rol interactiva.
  const new({
    required this.title,
    required this.subtitle,
    required this.roleBadge,
    required this.icon,
    required this.onTap,
    super.key,
    this.badgeColor = PaseoColors.goldPrimary,
  });

  /// Título del rol o perfil.
  final String title;

  /// Descripción de la experiencia o permisos.
  final String subtitle;

  /// Etiqueta visible del rol (ej. "MÓVIL", "TERMINAL POS", "EXECUTIVE").
  final String roleBadge;

  /// Icono representativo.
  final IconData icon;

  /// Color para el badge y detalles áuricos.
  final Color badgeColor;

  /// Callback de selección.
  final VoidCallback onTap;

  @override
  State<RolePreviewCard> createState() => _RolePreviewCardState();
}

class _RolePreviewCardState extends State<RolePreviewCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isHovered ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered
                ? PaseoColors.surfaceCardHover
                : PaseoColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? widget.badgeColor.withValues(alpha: 0.6)
                  : PaseoColors.surfaceBorder,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: widget.badgeColor.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: PaseoColors.surfaceIcon,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.badgeColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(widget.icon, color: widget.badgeColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: PaseoColors.textWhite,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.roleBadge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: widget.badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PaseoColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: PaseoColors.textDark,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
