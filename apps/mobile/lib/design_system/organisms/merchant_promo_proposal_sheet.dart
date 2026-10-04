import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_primary_button.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Hoja modal para que el comercio proponga una nueva promoción (HU-14).
///
/// La propuesta queda en estado PENDIENTE de aprobación por el administrador,
/// conforme a la regla constitucional §7 de Paseo Points.
class MerchantPromoProposalSheet extends StatefulWidget {
  /// Crea la hoja de propuesta de promoción.
  const new({
    super.key,
    this.establishmentName = 'Café Aranjuez',
    this.onProposed,
  });

  /// Nombre del establecimiento proponente.
  final String establishmentName;

  /// Callback ejecutado cuando se envía la propuesta.
  final ValueChanged<String>? onProposed;

  @override
  State<MerchantPromoProposalSheet> createState() =>
      _MerchantPromoProposalSheetState();
}

class _MerchantPromoProposalSheetState
    extends State<MerchantPromoProposalSheet> {
  final _titleController = TextEditingController(
    text: '2x1 en Café Helado los Jueves',
  );
  final _descriptionController = TextEditingController(
    text: 'Por la compra de cualquier bebida grande, recibe la segunda gratis.',
  );
  String _selectedCategory = 'Gastronomía';
  bool _isSubmitted = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSubmitted = true);
    widget.onProposed?.call(title);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de arrastre superior
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: PaseoColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Encabezado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proponer Promoción',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: PaseoColors.textDarkPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sujeta a aprobación por administración (HU-14)',
                        style: TextStyle(
                          fontSize: 11,
                          color: PaseoColors.textDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F6F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE8DFD0),
                      width: 1.1,
                    ),
                  ),
                  child: Text(
                    widget.establishmentName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8C6527),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isSubmitted) ...[
              // Estado de propuesta enviada
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6FBF7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBEAD2)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 48,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '¡Propuesta Registrada!',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tu promoción "${_titleController.text.trim()}" ha '
                      'sido enviada a revisión con el Administrador '
                      'de Paseo Aranjuez.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PaseoColors.textDarkSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: Color(0xFFB78103),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'ESTADO: PENDIENTE DE REVISIÓN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Color(0xFFB78103),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PaseoPrimaryButton(
                label: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ] else ...[
              // Formulario de propuesta
              const Text(
                'Título de la promoción',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: PaseoColors.textDarkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 13,
                  color: PaseoColors.textDarkPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  hintText: 'Ej. 20% descuento en combo familiar',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: PaseoColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: PaseoColors.borderLight,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Categoría',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: PaseoColors.textDarkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children:
                    ['Gastronomía', 'Moda', 'Entretenimiento', 'Cafetería'].map(
                      (cat) {
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF8C6527)
                                  : PaseoColors.textDarkSecondary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFF9F6F0),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFD4AF37)
                                : PaseoColors.borderLight,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategory = cat);
                          },
                        );
                      },
                    ).toList(),
              ),
              const SizedBox(height: 14),

              const Text(
                'Detalle / Condiciones',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: PaseoColors.textDarkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 13,
                  color: PaseoColors.textDarkPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  hintText: 'Describe las condiciones de la promoción...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: PaseoColors.borderLight,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: PaseoColors.borderLight,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botón de envío
              PaseoPrimaryButton(
                label: 'Enviar Propuesta al Administrador',
                onPressed: _handleSubmit,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
