import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/molecules/welcome_actions_group.dart';
import 'package:paseo_mobile/design_system/molecules/welcome_hero_header.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Organismo que compone la sección cinemática completa de bienvenida.
///
/// Integra la fotografía arquitectónica nocturna de Paseo Aranjuez, degradados
/// obsidianos de protección de contraste, la cabecera heroica animada y
/// el grupo de botones de acción "Comenzar" e "Iniciar sesión".
class WelcomeHeroOrganism extends StatelessWidget {
  /// Crea el organismo de bienvenida.
  const new({
    required this.animation,
    required this.onStartPressed,
    required this.onLoginPressed,
    super.key,
    this.backgroundImagePath = 'assets/images/paseo_aranjuez_night.jpg',
  });

  /// Controlador de animación para la entrada escalonada.
  final Animation<double> animation;

  /// Callback para el botón "Comenzar".
  final VoidCallback onStartPressed;

  /// Callback para el enlace "Iniciar sesión".
  final VoidCallback onLoginPressed;

  /// Ruta al asset de la imagen de fondo.
  final String backgroundImagePath;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Imagen de fondo cinemática con fallback
        Image.asset(
          backgroundImagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: const BoxDecoration(
                gradient: PaseoColors.obsidianGradient,
              ),
            );
          },
        ),

        // 2. Degradado superior oscuro para legibilidad del escudo y título
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: mediaQuery.size.height * 0.45,
          child: const DecoratedBox(
            decoration: BoxDecoration(gradient: PaseoColors.welcomeTopGradient),
          ),
        ),

        // 3. Degradado inferior para asentar los botones sobre el suelo
        // adoquinado.
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: mediaQuery.size.height * 0.50,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: PaseoColors.welcomeBottomGradient,
            ),
          ),
        ),

        // 4. Capa de contenido estructurado
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  SizedBox(
                    height: (constraints.maxHeight * 0.08).clamp(16.0, 60.0),
                  ),

                  // Cabecera con Emblema, "Paseo Points" y Subtítulo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: WelcomeHeroHeader(
                      animation: animation,
                      crestSize: 62,
                    ),
                  ),

                  const Spacer(),

                  // Botones de acción inferior
                  WelcomeActionsGroup(
                    animation: animation,
                    onStartPressed: onStartPressed,
                    onLoginPressed: onLoginPressed,
                  ),

                  SizedBox(height: (bottomPadding > 0 ? 12.0 : 28.0)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
