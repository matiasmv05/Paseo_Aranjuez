import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paseo_mobile/data/mock/mock_data.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_points_tag.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_primary_button.dart';
import 'package:paseo_mobile/design_system/organisms/redemption_confirm_dialog.dart';
import 'package:paseo_mobile/design_system/organisms/redemption_success_sheet.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Pantalla 6: Detalle de beneficio y flujo de canje interactivo.
class BenefitDetailPage extends StatelessWidget {
  /// Crea la pantalla de detalle de beneficio.
  const new({required this.benefit, super.key});

  /// Beneficio seleccionado.
  final MockBenefit benefit;

  void _showRedemptionFlow(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (dialogContext) {
          return RedemptionConfirmDialog(
            points: benefit.pointsRequired,
            onConfirm: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pushReplacement<void, void>(
                MaterialPageRoute(
                  builder: (successContext) => RedemptionSuccessView(
                    code: 'PA-483921',
                    onBackToBenefits: () => Navigator.of(successContext).pop(),
                  ),
                ),
              );
            },
            onCancel: () => Navigator.of(dialogContext).pop(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaseoColors.bgLight,
      body: Stack(
        children: [
          // Contenido desplazable
          CustomScrollView(
            slivers: [
              // Hero AppBar con fotografía del beneficio
              SliverAppBar(
                expandedHeight: 230,
                pinned: true,
                backgroundColor: PaseoColors.bgLight,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.85),
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: PaseoColors.textDarkPrimary,
                        size: 26,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.85),
                      child: IconButton(
                        icon: const Icon(
                          Icons.share_outlined,
                          color: PaseoColors.textDarkPrimary,
                          size: 20,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Enlace copiado para compartir.'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.asset(
                    benefit.imageAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Cuerpo con información, puntos y condiciones
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título principal
                      Text(
                        benefit.title,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: PaseoColors.textDarkPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Badge de categoría
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECECEC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          benefit.category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: PaseoColors.textDarkSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Establecimiento
                      Text(
                        benefit.establishment,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: PaseoColors.textDarkSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Descripción detallada
                      Text(
                        benefit.description,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: PaseoColors.textDarkSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Insignia de puntos requeridos
                      PaseoPointsTag(points: benefit.pointsRequired),
                      const SizedBox(height: 24),

                      // Sección de condiciones
                      const Text(
                        'Condiciones',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: PaseoColors.textDarkPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...benefit.conditions.map(
                        (cond) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '•  ',
                                style: TextStyle(
                                  color: PaseoColors.textDarkSecondary,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  cond,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: PaseoColors.textDarkSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Botón flotante inferior para canjear
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: PaseoPrimaryButton(
                label: 'Canjear por ${benefit.pointsRequired} puntos',
                onPressed: () => _showRedemptionFlow(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
