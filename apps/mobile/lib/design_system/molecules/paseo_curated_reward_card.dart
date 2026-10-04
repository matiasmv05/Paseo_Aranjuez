import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_gold_button.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_spacing.dart';

/// Molécula de tarjeta de beneficio exclusivo ("Curated Privilèges").
///
/// Presenta la fotografía del atelier o experiencia, la insignia flotante
/// de categoría, título serif, descripción, puntos requeridos y botón RESERVE.
class PaseoCuratedRewardCard extends StatefulWidget {
  /// Crea una tarjeta de beneficio curado.
  const new({
    required this.categoryTag,
    required this.title,
    required this.description,
    required this.requiredPoints,
    required this.imageAssetPath,
    super.key,
    this.onReserve,
  });

  /// Categoría en insignia flotante (ej. "HAUTE HORLOGERIE").
  final String categoryTag;

  /// Título de la experiencia o servicio (ej. "Swiss Automatic Watch Service").
  final String title;

  /// Descripción detallada del beneficio.
  final String description;

  /// Asignación de puntos requerida (ej. "12,500 PTS").
  final String requiredPoints;

  /// Ruta de la imagen local en assets.
  final String imageAssetPath;

  /// Callback emitido al pulsar el botón RESERVE o la tarjeta.
  final VoidCallback? onReserve;

  @override
  State<PaseoCuratedRewardCard> createState() => _PaseoCuratedRewardCardState();
}

class _PaseoCuratedRewardCardState extends State<PaseoCuratedRewardCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _isPressed || _isHovered
        ? PaseoColors.goldMetallic.withValues(alpha: 0.35)
        : PaseoColors.surfaceBorder;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              color: PaseoColors.surfaceCard,
              borderRadius: BorderRadius.circular(PaseoSpacing.radiusCard + 4),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                if (_isHovered)
                  BoxShadow(
                    color: PaseoColors.goldPrimary.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PaseoSpacing.radiusCard + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Imagen del Atelier con degradado inferior e insignia
                  Stack(
                    children: [
                      // Fotografía de cabecera
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.asset(
                          widget.imageAssetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFallbackHeader(),
                        ),
                      ),

                      // Degradado inferior para fundir con el cuerpo oscuro
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                PaseoColors.surfaceCard.withValues(alpha: 0.8),
                                PaseoColors.surfaceCard,
                              ],
                              stops: const [0, 0.5, 0.85, 1],
                            ),
                          ),
                        ),
                      ),

                      // Insignia flotante superior izquierda
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: PaseoColors.goldMetallic.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Text(
                            widget.categoryTag,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: PaseoColors.goldLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 2. Contenido de la tarjeta
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 22,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título de la experiencia en corte serif
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                            color: PaseoColors.textWhite,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Descripción del servicio o cata
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.45,
                            color: PaseoColors.textMuted.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Fila de Asignación de Puntos y Botón RESERVE
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'REQUIRED ALLOCATION',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: PaseoColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.requiredPoints,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: Color(0xFFE5C07B),
                                  ),
                                ),
                              ],
                            ),

                            // Botón RESERVE
                            PaseoGoldButton(
                              label: 'RESERVE',
                              onPressed: widget.onReserve,
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildFallbackHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2B36), Color(0xFF14151C)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: PaseoColors.goldMetallic,
        ),
      ),
    );
  }
}
