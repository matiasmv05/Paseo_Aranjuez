import 'package:flutter/material.dart';
import 'package:paseo_mobile/data/mock/mock_data.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_tier_badge.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Molécula de tarjeta de nivel de lealtad y gamificación del cliente (HU-22).
class CustomerTierCard extends StatefulWidget {
  /// Crea la tarjeta de nivel de fidelización.
  const new({required this.tierInfo, super.key});

  /// Información del nivel del cliente.
  final MockTierInfo tierInfo;

  @override
  State<CustomerTierCard> createState() => _CustomerTierCardState();
}

class _CustomerTierCardState extends State<CustomerTierCard> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final info = widget.tierInfo;
    final progress = (info.progressPercentage / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PaseoColors.borderLight, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabecera con título e insignia
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nivel de Lealtad',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: PaseoColors.textDarkSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Nivel ${info.displayName}',
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: PaseoColors.textDarkPrimary,
                    ),
                  ),
                ],
              ),
              PaseoTierBadge(tier: info.tier),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Barra de progreso hacia el próximo nivel
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${info.progressPercentage.toStringAsFixed(0)}% completado',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: PaseoColors.textDarkPrimary,
                ),
              ),
              if (info.nextTierName != null)
                Text(
                  'Próximo: ${info.nextTierName}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: PaseoColors.textDarkSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFF0EFEA),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFC79E69),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 3. Texto descriptivo del faltante de puntos
          if (info.pointsToNextTier != null)
            Text(
              'Te faltan ${info.pointsToNextTier} pts para subir a '
              '${info.nextTierName} y desbloquear 1.5x.',
              style: const TextStyle(
                fontSize: 11,
                color: PaseoColors.textDarkSecondary,
              ),
            )
          else
            const Text(
              '¡Has alcanzado el nivel máximo de beneficios en Paseo Aranjuez!',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8C6527),
              ),
            ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: PaseoColors.borderLight),
          const SizedBox(height: 8),

          // 4. Beneficios del nivel actual
          InkWell(
            onTap: () => setState(() => _showDetails = !_showDetails),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F3EA),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${info.multiplier}x PUNTOS',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8C6527),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ver beneficios activos',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: PaseoColors.textDarkPrimary,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _showDetails
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: PaseoColors.textDarkSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_showDetails) ...[
            const SizedBox(height: 8),
            ...info.benefits.map(
              (b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Color(0xFFC79E69),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(
                          fontSize: 11,
                          color: PaseoColors.textDarkSecondary,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
