import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Tarjeta de estado de nodo en la barra lateral del panel administrativo.
class AdminNodeStatusCard extends StatelessWidget {
  /// Crea una tarjeta informativa del nodo actual de Aranjuez.
  const new({
    this.nodeTitle = 'Aranjuez Central',
    this.statusText = 'NFC Terminal Active',
    super.key,
  });

  /// Nombre del nodo o ubicación central del conciergerie.
  final String nodeTitle;

  /// Estado de conectividad o protocolo terminal.
  final String statusText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF13151D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF232533)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'BOUTIQUE NODE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Color(0xFFC5A059),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            nodeTitle,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: PaseoColors.textWhite,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            statusText,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF787B8A),
            ),
          ),
        ],
      ),
    );
  }
}
