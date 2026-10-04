import 'package:flutter/material.dart';
import 'package:paseo_mobile/data/mock/mock_data.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_primary_button.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Organismo para la validación y consumo de cupones de canje en caja (HU-12).
class MerchantRedemptionValidator extends StatefulWidget {
  /// Crea el validador de cupones de canje.
  const new({
    super.key,
    this.establishmentName = 'Café Aranjuez',
    this.onRedeemed,
  });

  /// Nombre del establecimiento en el que opera el cajero actual.
  final String establishmentName;

  /// Callback opcional tras completar una entrega.
  final ValueChanged<MockRedemptionCoupon>? onRedeemed;

  @override
  State<MerchantRedemptionValidator> createState() =>
      _MerchantRedemptionValidatorState();
}

class _MerchantRedemptionValidatorState
    extends State<MerchantRedemptionValidator> {
  final _codeController = TextEditingController(text: 'PA-483921');
  MockRedemptionCoupon? _verifiedCoupon;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verifyCode() {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _errorMessage = null;
      _isSuccess = false;
      final coupon = MockData.findCoupon(code);
      if (coupon == null) {
        _verifiedCoupon = null;
        _errorMessage = 'Código de cupón no encontrado o inválido.';
      } else {
        _verifiedCoupon = coupon;
        if (coupon.status == RedemptionStatus.used) {
          _errorMessage =
              'Este cupón ya fue utilizado y entregado previamente.';
        }
      }
    });
  }

  void _completeRedemption() {
    if (_verifiedCoupon == null) return;
    final success = MockData.completeCoupon(_verifiedCoupon!.code);
    if (success) {
      setState(() {
        _verifiedCoupon = MockData.findCoupon(_verifiedCoupon!.code);
        _isSuccess = true;
        _errorMessage = null;
      });
      widget.onRedeemed?.call(_verifiedCoupon!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cabecera del diálogo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFF8C6527),
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Validar Cupón de Canje',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: PaseoColors.textDarkPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: PaseoColors.textPlaceholder,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Campo de ingreso del código alfanumérico
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PaseoColors.borderLight),
                ),
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: PaseoColors.textDarkPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ingresa código ej. PA-483921',
                    hintStyle: const TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 13,
                      letterSpacing: 0,
                      color: PaseoColors.textPlaceholder,
                    ),
                    prefixIcon: const Icon(
                      Icons.confirmation_number_outlined,
                      size: 20,
                      color: PaseoColors.textDarkSecondary,
                    ),
                    suffixIcon: TextButton(
                      onPressed: () =>
                          setState(() => _codeController.text = 'PA-483921'),
                      child: const Text(
                        'Pegar demo',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8C6527),
                        ),
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              PaseoPrimaryButton(
                label: 'Verificar código',
                onPressed: _verifyCode,
              ),

              // 3. Mensaje de error / advertencia
              if (_errorMessage != null && !_isSuccess) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFEB2B2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFE53E3E),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFC53030),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 4. Detalle del cupón verificado
              if (_verifiedCoupon != null && !_isSuccess) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F6F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8DFD0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _verifiedCoupon!.rewardTitle,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: PaseoColors.textDarkPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _verifiedCoupon!.status ==
                                      RedemptionStatus.issued
                                  ? const Color(0xFFDEF7EC)
                                  : const Color(0xFFEDF2F7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _verifiedCoupon!.status == RedemptionStatus.issued
                                  ? 'VÁLIDO'
                                  : 'YA USADO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color:
                                    _verifiedCoupon!.status ==
                                        RedemptionStatus.issued
                                    ? const Color(0xFF03543F)
                                    : const Color(0xFF718096),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Cliente: ${_verifiedCoupon!.customerName} '
                        '(${_verifiedCoupon!.customerPhone})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: PaseoColors.textDarkSecondary,
                        ),
                      ),
                      Text(
                        'Puntos deducidos: ${_verifiedCoupon!.pointsSpent} pts',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8C6527),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (_verifiedCoupon!.status == RedemptionStatus.issued)
                  ElevatedButton.icon(
                    onPressed: _completeRedemption,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Entregar Recompensa en Caja'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF19202E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],

              // 5. Estado de éxito consumado
              if (_isSuccess) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEF7EC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF84E1BC)),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF03543F),
                        size: 36,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '¡Canje Entregado con Éxito!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF03543F),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'El cupón ha sido marcado como USADO e invalidado '
                        'para futuros canjes en cualquier caja.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF046C4E),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
