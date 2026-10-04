import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Cuadro emergente de información (Tooltip) para el nodo activo del gráfico.
class AdminChartTooltip extends StatelessWidget {
  /// Crea un tooltip con diseño de alta relojería e insignias doradas.
  const new({
    required this.dateLabel,
    required this.pointsValue,
    this.badgeText = 'PEAK RECORD',
    super.key,
  });

  /// Etiqueta de fecha (e.g. 'OCT 22').
  final String dateLabel;

  /// Valor de puntos emitidos formateado (e.g. '56,800 PTS issued').
  final String pointsValue;

  /// Texto de la insignia de récord (e.g. 'PEAK RECORD').
  final String badgeText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161822),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$dateLabel • $badgeText',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Color(0xFFE5C07B),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            pointsValue,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: PaseoColors.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}
