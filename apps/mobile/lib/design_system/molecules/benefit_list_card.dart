import 'package:flutter/material.dart';
import 'package:paseo_mobile/data/mock/mock_data.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_points_tag.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Molécula de tarjeta de beneficio para listas y secciones destacadas.
class BenefitListCard extends StatelessWidget {
  /// Crea una tarjeta de beneficio interactiva.
  const new({required this.benefit, required this.onTap, super.key});

  /// Modelo de datos del beneficio a representar.
  final MockBenefit benefit;

  /// Callback al seleccionar la tarjeta.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PaseoColors.borderLight, width: 1.1),
        ),
        child: Row(
          children: [
            // Imagen del beneficio
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                benefit.imageAsset,
                width: 74,
                height: 74,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 74,
                  height: 74,
                  color: PaseoColors.bgLight,
                  child: const Icon(
                    Icons.image_outlined,
                    color: PaseoColors.textPlaceholder,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Textos informativos y puntos requeridos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    benefit.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: PaseoColors.textDarkPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    benefit.establishment,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: PaseoColors.textDarkSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PaseoPointsTag(points: benefit.pointsRequired),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: PaseoColors.textPlaceholder,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
