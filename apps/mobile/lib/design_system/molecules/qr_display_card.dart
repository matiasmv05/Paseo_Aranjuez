import 'package:flutter/material.dart';
import 'package:paseo_mobile/data/mock/mock_data.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_qr_code.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Molécula de tarjeta principal para la visualización del código QR
/// del cliente.
class QrDisplayCard extends StatelessWidget {
  /// Crea la tarjeta del código QR personal.
  const new({required this.user, super.key, this.qrSize = 190.0});

  /// Datos del usuario cuyo código QR se renderiza.
  final MockUser user;

  /// Tamaño en píxeles del código QR.
  final double qrSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PaseoColors.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Código QR nítido
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PaseoQrCode(data: user.qrCodePayload, size: qrSize),
          ),
          const SizedBox(height: 22),

          // Nombre del cliente
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: PaseoColors.textDarkPrimary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),

          // Teléfono boliviano asociado
          Text(
            user.phone,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: PaseoColors.textDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
