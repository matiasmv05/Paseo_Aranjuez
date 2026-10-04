import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_spacing.dart';

/// Molécula de tarjeta de transacción para el historial de puntos.
///
/// Reproduce con precisión la estructura visual de la captura de actividad:
/// categoría superior, marca de tiempo, comercio, descripción del servicio
/// y el delta de puntos en tipografía serif dorada.
class PaseoHistoryCard extends StatefulWidget {
  /// Crea una tarjeta para el historial de actividad de puntos.
  const new({
    required this.icon,
    required this.categoryLabel,
    required this.timestamp,
    required this.storeName,
    required this.serviceDescription,
    required this.pointsText,
    super.key,
    this.isNegative = false,
    this.onTap,
  });

  /// Icono temático del comercio (reloj, perchero, etc.).
  final IconData icon;

  /// Etiqueta superior (ej. "BOUTIQUE TAP", "IN-STORE PURCHASE").
  final String categoryLabel;

  /// Fecha y hora (ej. "Today, 14:35", "Yesterday, 18:20").
  final String timestamp;

  /// Nombre del establecimiento (ej. "Haute Horlogerie Boutique").
  final String storeName;

  /// Detalle de la compra o servicio (ej. "Swiss Automatic Watch Service").
  final String serviceDescription;

  /// Texto del valor de puntos con formato (ej. "-12,500" o "+2,400").
  final String pointsText;

  /// Indica si el movimiento es negativo (canje o deducción).
  final bool isNegative;

  /// Callback de pulsación.
  final VoidCallback? onTap;

  @override
  State<PaseoHistoryCard> createState() => _PaseoHistoryCardState();
}

class _PaseoHistoryCardState extends State<PaseoHistoryCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _isPressed || _isHovered
        ? PaseoColors.goldMetallic.withValues(alpha: 0.35)
        : PaseoColors.surfaceBorder;

    final cardBg = _isPressed || _isHovered
        ? PaseoColors.surfaceCardHover
        : PaseoColors.surfaceCard;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(PaseoSpacing.radiusCard + 2),
              border: Border.all(color: borderColor),
              boxShadow: [
                if (_isHovered || _isPressed)
                  BoxShadow(
                    color: PaseoColors.goldPrimary.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila Superior: Icono circular + Categoría | Fecha/Hora
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Icono en contenedor circular oscuro
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: PaseoColors.surfaceIcon,
                            border: Border.all(
                              color: PaseoColors.surfaceBorder.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                          child: Icon(
                            widget.icon,
                            size: 18,
                            color: PaseoColors.goldMetallic,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Etiqueta de categoría en mayúsculas
                        Text(
                          widget.categoryLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: PaseoColors.textMuted.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),

                    // Timestamp
                    Text(
                      widget.timestamp,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                        color: PaseoColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fila Inferior: Datos del comercio | Puntos en serif
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    // Columna izquierda: Nombre del comercio y servicio
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.storeName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: PaseoColors.textWhite,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.serviceDescription,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: PaseoColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Columna derecha: Puntos destacados en serif oro
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.pointsText,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 25,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                            color: PaseoColors.goldLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'PTS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: PaseoColors.goldMetallic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
