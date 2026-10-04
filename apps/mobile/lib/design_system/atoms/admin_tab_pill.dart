import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Botón conmutador de rango temporal para el gráfico ejecutivo (Atomo).
class AdminTabPill extends StatelessWidget {
  /// Crea un selector de rango temporal con estilo de alta gama.
  const new({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  /// Etiqueta de la opción (e.g. 'LAST 7 DAYS', 'LAST 30 DAYS').
  final String label;

  /// Si este rango está actualmente seleccionado.
  final bool isSelected;

  /// Callback de selección.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE5C07B) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: isSelected
                    ? PaseoColors.obsidianBlack
                    : const Color(0xFF8A8D9E),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
