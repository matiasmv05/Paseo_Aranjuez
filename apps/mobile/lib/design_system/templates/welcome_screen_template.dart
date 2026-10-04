import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Plantilla arquitectónica de Atomic Design para la pantalla de bienvenida.
///
/// Define los slots estructurales (fondo cinemático y contenido superpuesto)
/// sin vincular lógica de negocio ni estado mutable.
class WelcomeScreenTemplate extends StatelessWidget {
  /// Crea la plantilla de pantalla de bienvenida.
  const new({required this.body, super.key});

  /// Widget que contiene la composición de la sección de bienvenida.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: PaseoColors.obsidianBlack, body: body);
  }
}
