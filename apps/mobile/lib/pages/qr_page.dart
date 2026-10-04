import 'package:flutter/material.dart';
import 'package:paseo_mobile/data/mock/mock_data.dart';
import 'package:paseo_mobile/design_system/molecules/qr_display_card.dart';
import 'package:paseo_mobile/design_system/templates/client_scaffold_template.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Pantalla 4: Mi código QR oficial de fidelización.
class QrPage extends StatelessWidget {
  /// Crea la pantalla de visualización del código QR.
  const new({super.key, this.showBackButton = true});

  /// Si muestra el botón de retorno en la barra superior.
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    const user = MockData.currentUser;

    return ClientScaffoldTemplate(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: PaseoColors.textDarkPrimary,
                  size: 28,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Mi código QR',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: PaseoColors.textDarkPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Tarjeta central de visualización del código QR
              const QrDisplayCard(user: user),
              const SizedBox(height: 24),

              // 2. Mensaje informativo 1: Acumulación en comercios
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: PaseoColors.infoCalloutBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: PaseoColors.infoCalloutText,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Muéstralo en los establecimientos participantes para '
                        'acumular puntos.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3748),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Mensaje informativo 2: Alternativa con número de celular
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: PaseoColors.phoneCalloutBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.phone_iphone_rounded,
                      color: PaseoColors.phoneCalloutText,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'También puedes identificarte con tu número de '
                        'celular.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A5568),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
