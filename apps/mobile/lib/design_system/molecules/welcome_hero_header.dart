import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_brand_crest.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Molécula de cabecera para la pantalla de bienvenida.
///
/// Compone el emblema heráldico dorado de Paseo Aranjuez, el título solemne
/// "Paseo Points" y el subtítulo de propuesta de valor con animaciones
/// escalonadas (staggered animations) de entrada fluida a 60fps.
class WelcomeHeroHeader extends StatelessWidget {
  /// Crea la cabecera heroica animada.
  const new({required this.animation, super.key, this.crestSize = 64.0});

  /// Animación base que coordina el escalonamiento de la entrada.
  final Animation<double> animation;

  /// Tamaño del escudo del emblema.
  final double crestSize;

  @override
  Widget build(BuildContext context) {
    // 1. Escalonamiento del emblema (0.0 a 0.55)
    final crestFade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
    );
    final crestSlide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(crestFade);

    // 2. Escalonamiento del título "Paseo Points" (0.2 a 0.75)
    final titleFade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 0.75, curve: Curves.easeOutCubic),
    );
    final titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(titleFade);

    // 3. Escalonamiento del subtítulo (0.4 to 0.95)
    final subtitleFade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.4, 0.95, curve: Curves.easeOutCubic),
    );
    final subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(subtitleFade);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emblema superior
        SlideTransition(
          position: crestSlide,
          child: FadeTransition(
            opacity: crestFade,
            child: PaseoBrandCrest(size: crestSize),
          ),
        ),
        const SizedBox(height: 36),

        // Título de prestigio
        SlideTransition(
          position: titleSlide,
          child: FadeTransition(
            opacity: titleFade,
            child: const Text(
              'Paseo Points',
              style: PaseoTypography.welcomeTitle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Subtítulo con sombra sutil para contraste cinemático
        SlideTransition(
          position: subtitleSlide,
          child: FadeTransition(
            opacity: subtitleFade,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tu experiencia en Paseo Aranjuez,\nahora con más beneficios.',
                style: PaseoTypography.welcomeSubtitle.copyWith(
                  shadows: const [
                    Shadow(
                      color: Color(0x99000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
