import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Molécula de tarjeta de cliente VIP autenticado en el terminal POS.
class PosMemberCard extends StatelessWidget {
  /// Crea la tarjeta del cliente identificado.
  const new({
    super.key,
    this.name = 'Alejandro Morales',
    this.tier = 'VIP OBSIDIAN',
    this.memberCode = '#ARJ-9921',
    this.clientSince = '2021',
    this.shopperName = 'Elena V.',
    this.vaultPoints = '3,450',
    this.multiplier = '+10%',
    this.onSwitchClient,
  });

  /// Nombre del socio.
  final String name;

  /// Nivel VIP.
  final String tier;

  /// Código de membresía.
  final String memberCode;

  /// Año desde que es cliente privado.
  final String clientSince;

  /// Mayordomo o personal shopper asignado.
  final String shopperName;

  /// Saldo de puntos acumulados.
  final String vaultPoints;

  /// Multiplicador de acumulación asignado por el club.
  final String multiplier;

  /// Callback para cambiar de socio o resetear.
  final VoidCallback? onSwitchClient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141620),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF262838)),
      ),
      child: Row(
        children: [
          // 1. Icono de distinción VIP en círculo oscuro
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1C1E2A),
              border: Border.all(
                color: PaseoColors.goldMetallic.withValues(alpha: 0.35),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.military_tech_outlined,
                size: 22,
                color: Color(0xFFE5C07B),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // 2. Información del socio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: PaseoColors.textWhite,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2312),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF7A5F20)),
                      ),
                      child: Text(
                        tier,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: Color(0xFFE5C07B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      memberCode,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: Color(0xFF787B8A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Private Client Since $clientSince • '
                  'Concierge Personal Shopper: $shopperName',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF787B8A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // 3. Saldo en bóveda (Accumulated Vault)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ACCUMULATED\nVAULT',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Color(0xFF787B8A),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    vaultPoints,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE5C07B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'PTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Color(0xFFE5C07B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),

          // 4. Beneficio de categoría (+10% Multiplier)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'OBSIDIAN BENEFIT',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Color(0xFF787B8A),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    size: 16,
                    color: Color(0xFFE5C07B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$multiplier\nMultiplier',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE5C07B),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 14),

          // 5. Botón de alternancia o acción
          IconButton(
            onPressed: onSwitchClient,
            tooltip: 'Cambiar de cliente',
            icon: const Icon(
              Icons.swap_horiz_rounded,
              size: 20,
              color: Color(0xFF787B8A),
            ),
          ),
        ],
      ),
    );
  }
}
