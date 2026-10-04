import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Átomo de campo de texto para formularios de la aplicación.
class PaseoInputField extends StatelessWidget {
  /// Crea un campo de texto con etiqueta opcional y personalización de iconos.
  const new({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.readOnly = false,
  });

  /// Etiqueta superior sobre el campo.
  final String? label;

  /// Texto de sugerencia interior.
  final String? hintText;

  /// Controlador de edición de texto.
  final TextEditingController? controller;

  /// Tipo de teclado.
  final TextInputType? keyboardType;

  /// Si oculta el texto introducido (para contraseñas).
  final bool obscureText;

  /// Widget de icono prefijo.
  final Widget? prefixIcon;

  /// Widget de icono sufijo (ej. conmutador de visibilidad).
  final Widget? suffixIcon;

  /// Callback al cambiar el contenido.
  final ValueChanged<String>? onChanged;

  /// Si el campo es solo de lectura.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: PaseoColors.textDarkPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PaseoColors.borderLight, width: 1.2),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            readOnly: readOnly,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: PaseoColors.textDarkPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: PaseoColors.textPlaceholder,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
