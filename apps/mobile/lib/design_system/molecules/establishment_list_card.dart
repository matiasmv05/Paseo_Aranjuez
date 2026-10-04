import 'package:flutter/material.dart';
import 'package:paseo_mobile/data/mock/mock_data.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Molécula de tarjeta de establecimiento comercial para listas y directorios.
class EstablishmentListCard extends StatelessWidget {
  /// Crea una tarjeta de establecimiento.
  const new({required this.establishment, required this.onTap, super.key});

  /// Modelo de datos del establecimiento comercial.
  final MockEstablishment establishment;

  /// Callback de pulsación.
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
            // Logo o fotografía del local
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                establishment.imageAsset,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: PaseoColors.bgLight,
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: PaseoColors.textPlaceholder,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Información del establecimiento
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    establishment.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: PaseoColors.textDarkPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    establishment.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: PaseoColors.textDarkSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        establishment.location,
                        style: const TextStyle(
                          fontSize: 11,
                          color: PaseoColors.textPlaceholder,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 11,
                          color: PaseoColors.textPlaceholder,
                        ),
                      ),
                      Text(
                        establishment.hours,
                        style: const TextStyle(
                          fontSize: 11,
                          color: PaseoColors.textPlaceholder,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
