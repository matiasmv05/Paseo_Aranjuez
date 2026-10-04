import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Molécula de tarjeta para el programa de referidos y bonos (HU-25).
class ReferralCard extends StatelessWidget {
  /// Crea la tarjeta del programa de referidos.
  const new({super.key, this.referralCode = 'VALE-ARJ25'});

  /// Código de referido personal del cliente.
  final String referralCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD0), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF8C6527),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invita amigos y gana puntos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: PaseoColors.textDarkPrimary,
                      ),
                    ),
                    Text(
                      'Gana +150 pts por cada amigo que se una',
                      style: TextStyle(
                        fontSize: 11,
                        color: PaseoColors.textDarkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Comparte tu código personal. Cuando tu invitado acumule su '
            'primera compra en Paseo Aranjuez, ambos recibirán una '
            'bonificación de 150 puntos.',
            style: TextStyle(
              fontSize: 11,
              color: PaseoColors.textDarkSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),

          // Caja de código y botón de copiado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: PaseoColors.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  referralCode,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: PaseoColors.textDarkPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    unawaited(
                      Clipboard.setData(ClipboardData(text: referralCode)),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Código de referido copiado!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: Color(0xFF8C6527),
                  ),
                  label: const Text(
                    'Copiar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8C6527),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
