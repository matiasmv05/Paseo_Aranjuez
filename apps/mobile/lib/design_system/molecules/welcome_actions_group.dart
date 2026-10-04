import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_text_link.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_welcome_button.dart';

/// Molécula de grupo de acciones para la pantalla de bienvenida.
///
/// Compone el botón principal píldora "Comenzar" y el enlace "Iniciar sesión",
/// con transición animada escalonada y espaciado consistente.
class WelcomeActionsGroup extends StatelessWidget {
  /// Crea el grupo de acciones inferior.
  const new({
    required this.onStartPressed,
    required this.onLoginPressed,
    super.key,
    this.animation,
    this.isLoading = false,
  });

  /// Acción al pulsar "Comenzar".
  final VoidCallback onStartPressed;

  /// Acción al pulsar "Iniciar sesión".
  final VoidCallback onLoginPressed;

  /// Animación opcional para escalonar la entrada.
  final Animation<double>? animation;

  /// Si el botón principal se encuentra en estado de procesamiento.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaseoWelcomeButton(
          label: 'Comenzar',
          isLoading: isLoading,
          onPressed: onStartPressed,
        ),
        const SizedBox(height: 14),
        Center(
          child: PaseoTextLink(
            text: 'Iniciar sesión',
            onPressed: onLoginPressed,
          ),
        ),
      ],
    );

    if (animation != null) {
      final actionsFade = CurvedAnimation(
        parent: animation!,
        curve: const Interval(0.55, 1, curve: Curves.easeOutCubic),
      );
      final actionsSlide = Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(actionsFade);

      content = SlideTransition(
        position: actionsSlide,
        child: FadeTransition(opacity: actionsFade, child: content),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: content,
    );
  }
}
