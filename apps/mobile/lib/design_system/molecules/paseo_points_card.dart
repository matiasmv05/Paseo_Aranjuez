import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Molécula de tarjeta de saldo de puntos para la pantalla de
/// Inicio / Dashboard.
class PaseoPointsCard extends StatelessWidget {
  /// Crea la tarjeta institucional de saldo con acceso directo a
  /// "Mostrar mi QR".
  const new({
    required this.points,
    required this.onShowQr,
    super.key,
    this.userName = 'Valentina',
  });

  /// Saldo numérico de puntos a mostrar (ej. 2450).
  final int points;

  /// Callback para el botón "Mostrar mi QR".
  final VoidCallback onShowQr;

  /// Nombre del usuario.
  final String userName;

  String _formatPoints(int value) {
    final str = value.toString();
    if (str.length > 3) {
      final prefix = str.substring(0, str.length - 3);
      final suffix = str.substring(str.length - 3);
      return '$prefix.$suffix';
    }
    return str;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF161B26),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF161B26).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: Logo "Paseo Points" + Estrella de favoribilidad
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Paseo Points',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                      color: Color(0xFF9EACB9),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.star_border_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Saldo numérico grande
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formatPoints(points),
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'puntos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFB0BDC9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Botón píldora "Mostrar mi QR"
              GestureDetector(
                onTap: onShowQr,
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2C498),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_2_rounded,
                        color: Color(0xFF1E170F),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Mostrar mi QR',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E170F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Puntos indicadores del carrusel (• • •)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 14,
              height: 4,
              decoration: BoxDecoration(
                color: PaseoColors.primaryNavy,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D3D9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D3D9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
