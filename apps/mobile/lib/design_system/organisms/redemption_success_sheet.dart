import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_primary_button.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Organismo de pantalla de éxito de canje realizado (Pantalla 8).
class RedemptionSuccessView extends StatelessWidget {
  /// Crea la vista de canje realizado exitosamente.
  const new({required this.code, required this.onBackToBenefits, super.key});

  /// Código de canje generado de un solo uso (ej. "PA-483921").
  final String code;

  /// Callback para volver a la pantalla de beneficios.
  final VoidCallback onBackToBenefits;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaseoColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: PaseoColors.textDarkPrimary,
            size: 28,
          ),
          onPressed: onBackToBenefits,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Icono circular de verificación
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAEBED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: PaseoColors.textDarkPrimary,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Título serif
              const Text(
                '¡Canje realizado!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: PaseoColors.textDarkPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Subtítulo
              const Text(
                'Tu recompensa ha sido canjeada\ncorrectamente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: PaseoColors.textDarkSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 32),

              // Tarjeta contenedora del código de canje
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F5F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE8E4DA),
                    width: 1.1,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Código de canje',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: PaseoColors.textDarkSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          code,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: PaseoColors.textDarkPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(
                            Icons.copy_rounded,
                            color: PaseoColors.textDarkSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Código copiado al portapapeles.',
                                ),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Indicación para el usuario
              const Text(
                'Muéstralo en el establecimiento\npara validar tu beneficio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: PaseoColors.textDarkSecondary,
                  height: 1.35,
                ),
              ),

              const Spacer(),

              // Botón inferior "Volver a beneficios"
              PaseoPrimaryButton(
                label: 'Volver a beneficios',
                onPressed: onBackToBenefits,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
