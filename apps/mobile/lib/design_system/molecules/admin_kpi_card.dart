import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Tarjeta de indicador clave de desempeño (KPI) para el panel ejecutivo.
class AdminKpiCard extends StatelessWidget {
  /// Crea una tarjeta KPI ejecutiva con formato de lujo obsidiana.
  const new({
    required this.title,
    required this.icon,
    required this.value,
    this.valueSuffix,
    this.valueColor,
    this.highlightWidget,
    this.metaLabel,
    this.metaValue,
    super.key,
  });

  /// Título de la métrica en mayúsculas (e.g. 'TOTAL USERS').
  final String title;

  /// Icono temático representativo.
  final IconData icon;

  /// Valor cuantitativo principal (e.g. '18,420', '48,290', '54').
  final String value;

  /// Sufijo textual del valor (e.g. 'PTS', 'STORES').
  final String? valueSuffix;

  /// Color para el valor principal (por defecto blanco, dorado para puntos).
  final Color? valueColor;

  /// Widget personalizado para la fila de tendencia o valoración.
  final Widget? highlightWidget;

  /// Etiqueta del metadato inferior (e.g. 'TIER BREAKDOWN').
  final String? metaLabel;

  /// Valor del metadato inferior (e.g. '2,140 Black Tier • 16,280 Gold').
  final String? metaValue;

  @override
  Widget build(BuildContext context) {
    final effectiveValueColor = valueColor ?? PaseoColors.textWhite;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF10121A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF202230)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Fila de Título y Contenedor de Icono
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                    color: Color(0xFF787B8A),
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF161822),
                  border: Border.all(color: const Color(0xFF282B3A)),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFFE5C07B)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Valor Numérico Principal
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: effectiveValueColor,
                ),
              ),
              if (valueSuffix != null) ...[
                const SizedBox(width: 8),
                Text(
                  valueSuffix!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: effectiveValueColor,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // 3. Fila de Destacado / Tendencia
          ?highlightWidget,
          const SizedBox(height: 20),

          // Divisor sutil
          const Divider(color: Color(0xFF1B1D28), thickness: 0.8, height: 1),
          const SizedBox(height: 14),

          // 4. Metadatos de Cierre
          if (metaLabel != null && metaValue != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    metaLabel!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: Color(0xFF5B5D6D),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: Text(
                    metaValue!,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC7CBD8),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
