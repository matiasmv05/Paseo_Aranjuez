import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Plantilla arquitectónica de pantalla para clientes de Paseo Points.
///
/// Define la estructura visual de slots (AppBar superior, cuerpo animado y
/// barra de navegación inferior) sobre el degradado obsidiana oficial.
class CustomerScaffoldTemplate extends StatelessWidget {
  /// Crea la plantilla de pantalla para clientes.
  const new({required this.body, super.key, this.topBar, this.bottomBar});

  /// Widget de barra superior inyectado en el slot.
  final PreferredSizeWidget? topBar;

  /// Contenido principal de la pantalla inyectado en el slot.
  final Widget body;

  /// Barra de navegación inferior inyectada en el slot.
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: topBar,
      bottomNavigationBar: bottomBar,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: PaseoColors.obsidianGradient),
        child: body,
      ),
    );
  }
}
