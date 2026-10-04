import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Plantilla arquitectónica de Atomic Design para las pantallas claras
/// del cliente.
///
/// Define los slots estructurales (AppBar, Body, BottomBar) con fondo marfil
/// arquitectónico uniforme sin incluir estado mutable ni llamadas de negocio.
class ClientScaffoldTemplate extends StatelessWidget {
  /// Crea la plantilla de pantalla del cliente.
  const new({
    required this.body,
    super.key,
    this.appBar,
    this.bottomNavigationBar,
    this.backgroundColor = PaseoColors.bgLight,
  });

  /// Barra superior opcional.
  final PreferredSizeWidget? appBar;

  /// Contenido principal del cuerpo.
  final Widget body;

  /// Barra de navegación inferior opcional.
  final Widget? bottomNavigationBar;

  /// Color de fondo del scaffold.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
