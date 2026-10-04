import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/organisms/welcome_hero_organism.dart';
import 'package:paseo_mobile/design_system/templates/welcome_screen_template.dart';
import 'package:paseo_mobile/pages/client_shell_page.dart';
import 'package:paseo_mobile/pages/login_page.dart';

/// Página de bienvenida y onboarding de Paseo Points.
///
/// Implementa la pantalla inicial de alto lujo con animación orquestada,
/// acceso inmediato a la experiencia móvil VIP de clientes e inicio de sesión.
class WelcomePage extends StatefulWidget {
  /// Crea la página de bienvenida.
  const new({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToCustomer() {
    Navigator.of(context).push<void>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ClientShellPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context)
        .push<void>(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    // Soporte para usuarios con preferencia de movimiento reducido
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final effectiveAnimation = reduceMotion
        ? const AlwaysStoppedAnimation<double>(1)
        : _controller.view;

    return WelcomeScreenTemplate(
      body: WelcomeHeroOrganism(
        animation: effectiveAnimation,
        onStartPressed: _navigateToCustomer,
        onLoginPressed: _navigateToLogin,
      ),
    );
  }
}
