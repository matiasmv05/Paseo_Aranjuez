import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/organisms/merchant_sidebar.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Plantilla arquitectónica de pantalla para el portal POS del comercio.
class MerchantPosTemplate extends StatelessWidget {
  /// Crea el armazón visual del terminal de boutique.
  const new({required this.headerBar, required this.body, super.key});

  /// Barra superior de búsqueda y perfil.
  final Widget headerBar;

  /// Contenido principal del terminal.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0B10),
          drawer: isDesktop ? null : const Drawer(child: MerchantSidebar()),
          appBar: isDesktop
              ? null
              : AppBar(
                  backgroundColor: const Color(0xFF0C0D13),
                  title: const Text(
                    'Paseo Concierge POS',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16,
                      color: PaseoColors.goldLight,
                    ),
                  ),
                ),
          body: Row(
            children: [
              if (isDesktop) const MerchantSidebar(),
              Expanded(
                child: Column(
                  children: [
                    headerBar,
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF090A0E),
                        ),
                        child: body,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
