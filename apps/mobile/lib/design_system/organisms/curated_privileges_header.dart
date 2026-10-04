import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_points_pill.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Organismo de cabecera para la sección de beneficios exclusivos curados.
///
/// Aloja la etiqueta "ATELIER ALLOCATIONS", el título "Curated Privilèges",
/// la píldora de saldo "● 3,450 PTS" y la leyenda de exclusividad.
class CuratedPrivilegesHeader extends StatefulWidget {
  /// Crea la cabecera de beneficios curados.
  const new({super.key, this.pointsText = '3,450 PTS'});

  /// Saldo de puntos del socio a desplegar en la píldora.
  final String pointsText;

  @override
  State<CuratedPrivilegesHeader> createState() =>
      _CuratedPrivilegesHeaderState();
}

class _CuratedPrivilegesHeaderState extends State<CuratedPrivilegesHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Etiqueta superior
            const Text(
              'ATELIER ALLOCATIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: PaseoColors.goldMetallic,
              ),
            ),
            const SizedBox(height: 10),

            // Título "Curated Privilèges" y píldora de puntos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Curated Privilèges',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                      color: PaseoColors.textWhite,
                    ),
                  ),
                ),
                PaseoPointsPill(pointsText: widget.pointsText),
              ],
            ),
            const SizedBox(height: 12),

            // Leyenda de acceso exclusivo y token NFC
            Text(
              'Exclusively reserved for Paseo Circle members. '
              'Present in-boutique NFC token upon arrival.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.45,
                color: PaseoColors.textMuted.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
