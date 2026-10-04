import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_typography.dart';

/// Modal interactivo de autenticación NFC por balizamiento ("Tap to Pay").
class NfcPaymentSheet extends StatefulWidget {
  /// Crea el modal de pago NFC.
  const new({super.key});

  /// Muestra el modal de pago NFC en la parte inferior.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: PaseoColors.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const NfcPaymentSheet(),
    );
  }

  @override
  State<NfcPaymentSheet> createState() => _NfcPaymentSheetState();
}

class _NfcPaymentSheetState extends State<NfcPaymentSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tirador superior del modal
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: PaseoColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'CONCIERGE NFC READY',
              style: PaseoTypography.brandLabel,
            ),
            const SizedBox(height: 8),

            const Text(
              'Aproxima tu dispositivo',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: PaseoColors.textWhite,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Mantén la parte superior del teléfono cerca del '
              'terminal de la boutique para aplicar tu saldo de puntos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: PaseoColors.textMuted,
              ),
            ),
            const SizedBox(height: 32),

            // Icono pulsante de ondas NFC con halo áurico
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PaseoColors.surfaceIcon,
                      border: Border.all(
                        color: PaseoColors.goldMetallic.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: PaseoColors.goldPrimary.withValues(
                            alpha: 0.25 * _pulseAnimation.value,
                          ),
                          blurRadius: 28,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.contactless_outlined,
                        size: 46,
                        color: Color(0xFFE5C07B),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Tarjeta de estado de autenticación en terminal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161822),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: PaseoColors.goldMetallic.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Color(0xFF68D391),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Enlace seguro verificado • Terminal #ARJ-B04',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC7CBD8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botón para cerrar o cancelar
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: PaseoColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
