import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Elemento de perspectiva analítica inferior del gráfico ejecutivo (Molécula).
class AdminInsightItem extends StatelessWidget {
  /// Crea un indicador de perspectiva con icono temático, subtítulo y valor.
  const new({
    required this.icon,
    required this.subtitle,
    required this.title,
    this.dotColor,
    this.highlightText,
    super.key,
  });

  /// Icono circular representativo.
  final IconData icon;

  /// Subtítulo explicativo en mayúsculas (e.g. 'HIGHEST VOLUME BOUTIQUE').
  final String subtitle;

  /// Valor destacado (e.g. 'Haute Horlogerie', '18:00 – 21:00 CEST').
  final String title;

  /// Indicador luminoso opcional (e.g. punto amarillo para 'All POS Synced').
  final Color? dotColor;

  /// Texto complementario en tono dorado (e.g. '(32%)').
  final String? highlightText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icono circular
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF13151D),
            border: Border.all(color: const Color(0xFF262838)),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFFE5C07B)),
        ),
        const SizedBox(width: 10),

        // Textos descriptivos
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: Color(0xFF787B8A),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: PaseoColors.textWhite,
                  ),
                ),
                if (highlightText != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    highlightText!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE5C07B),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}
