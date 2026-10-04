import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo de botón de incremento rápido para el monto de compra en caja.
class PosPresetButton extends StatelessWidget {
  /// Crea un botón de incremento de monto o reinicio.
  const new({
    required this.label,
    required this.onTap,
    super.key,
    this.isReset = false,
  });

  /// Texto mostrado en el botón (ej. "+€50", "RESET").
  final String label;

  /// Acción ejecutada al pulsar el botón.
  final VoidCallback onTap;

  /// Indica si es el botón de reinicio/borrado.
  final bool isReset;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isReset ? const Color(0xFF1E1F2A) : const Color(0xFF181A24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isReset
                ? PaseoColors.surfaceBorder
                : PaseoColors.goldMetallic.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: isReset ? PaseoColors.textMuted : const Color(0xFFD4AF37),
          ),
        ),
      ),
    );
  }
}
