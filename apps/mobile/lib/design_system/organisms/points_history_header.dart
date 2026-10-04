import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_section_tag.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Organismo de cabecera de la pantalla de historial de puntos.
///
/// Muestra la etiqueta "● MEMBER ACTIVITY", el título principal en serif
/// "Points History" y la descripción de privilegios del socio.
class PointsHistoryHeader extends StatefulWidget {
  /// Crea la cabecera de la pantalla de actividad.
  const new({super.key});

  @override
  State<PointsHistoryHeader> createState() => _PointsHistoryHeaderState();
}

class _PointsHistoryHeaderState extends State<PointsHistoryHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Etiqueta superior
            PaseoSectionTag(label: 'MEMBER ACTIVITY'),
            SizedBox(height: 12),

            // Título principal en corte serif de alta gama
            Text(
              'Points History',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 34,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
                color: PaseoColors.textWhite,
              ),
            ),
            SizedBox(height: 8),

            // Subtítulo elegante
            Text(
              'A curated record of your Paseo Aranjuez privileges.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.1,
                color: PaseoColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
