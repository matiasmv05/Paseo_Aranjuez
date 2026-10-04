import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo de chip selector de categorías y filtros.
class PaseoFilterChip extends StatelessWidget {
  /// Crea un chip interactivo para filtros de listas.
  const new({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  /// Texto del chip (ej. "Todos", "Gastronomía", "Moda").
  final String label;

  /// Si el chip se encuentra actualmente seleccionado.
  final bool isSelected;

  /// Callback al pulsar el chip.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? PaseoColors.primaryNavy
              : PaseoColors.chipInactiveBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : PaseoColors.chipInactiveText,
            ),
          ),
        ),
      ),
    );
  }
}
