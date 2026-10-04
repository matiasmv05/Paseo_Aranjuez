import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/pos_preset_button.dart';
import 'package:paseo_mobile/design_system/molecules/pos_computation_summary.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Organismo de formulario de registro rápido de compras y cálculo de puntos.
class PosPurchaseForm extends StatefulWidget {
  /// Crea el formulario de despacho rápido de compras.
  const new({super.key, this.initialAmount = 450.0, this.onRegisterPurchase});

  /// Monto inicial en euros.
  final double initialAmount;

  /// Callback al registrar la compra con el monto final y ticket.
  final void Function(double amount, String ticketNumber)? onRegisterPurchase;

  @override
  State<PosPurchaseForm> createState() => _PosPurchaseFormState();
}

class _PosPurchaseFormState extends State<PosPurchaseForm> {
  late double _amount;
  late final TextEditingController _ticketController;

  @override
  void initState() {
    super.initState();
    _amount = widget.initialAmount;
    _ticketController = TextEditingController(text: 'TCK-88204');
  }

  @override
  void dispose() {
    _ticketController.dispose();
    super.dispose();
  }

  void _addPreset(double delta) {
    setState(() => _amount += delta);
  }

  void _resetAmount() {
    setState(() => _amount = 0.0);
  }

  int get _basePoints => _amount.floor();
  int get _bonusPoints => (_basePoints * 0.10).floor();
  int get _totalPoints => _basePoints + _bonusPoints;

  @override
  Widget build(BuildContext context) {
    final amountFormatted = _amount.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF10121A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF202332)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabecera
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RAPID DISPATCH • <3S FLOW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: Color(0xFFE5C07B),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Store Purchase Registration',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: PaseoColors.textWhite,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF161822),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2D3E)),
                ),
                child: const Text(
                  'EURO (EUR • €)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Color(0xFF8A8D9E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Monitor de monto total (Gross Total Display)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF141620),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF232534)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TICKET PURCHASE GROSS TOTAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xFF787B8A),
                      ),
                    ),
                    Text(
                      'NET VALUE IN-STORE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: Color(0xFF787B8A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          '€',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          amountFormatted,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: PaseoColors.textWhite,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_amount >= 10) {
                            _amount -= 10;
                          } else {
                            _amount = 0;
                          }
                        });
                      },
                      tooltip: 'Deshacer / Restar',
                      icon: const Icon(
                        Icons.backspace_outlined,
                        size: 20,
                        color: Color(0xFF787B8A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Fila de botones de incremento rápido (Presets)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'PRESETS:',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0xFF787B8A),
                  ),
                ),
                const SizedBox(width: 12),
                PosPresetButton(label: '+€50', onTap: () => _addPreset(50)),
                const SizedBox(width: 8),
                PosPresetButton(label: '+€100', onTap: () => _addPreset(100)),
                const SizedBox(width: 8),
                PosPresetButton(label: '+€250', onTap: () => _addPreset(250)),
                const SizedBox(width: 8),
                PosPresetButton(label: '+€500', onTap: () => _addPreset(500)),
                const SizedBox(width: 8),
                PosPresetButton(
                  label: 'RESET',
                  isReset: true,
                  onTap: _resetAmount,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Campos: Número de Ticket y Sección/Departamento
          Row(
            children: [
              // Ticket #
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'POS TICKET / RECEIPT #',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xFF787B8A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141620),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF232534)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 18,
                            color: Color(0xFF787B8A),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _ticketController,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: PaseoColors.textWhite,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Departamento
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DEPARTMENT / SECTION',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xFF787B8A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141620),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF232534)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.checkroom_outlined,
                            size: 18,
                            color: Color(0xFFE5C07B),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Haute Couture &\nAccessories',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: PaseoColors.textWhite,
                                height: 1.15,
                              ),
                            ),
                          ),
                          Text(
                            'SEC -\n04',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: Color(0xFF787B8A),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 5. Cuadro de cómputo instantáneo de puntos
          PosComputationSummary(
            basePoints: _basePoints,
            bonusPoints: _bonusPoints,
            totalPoints: _totalPoints,
          ),
          const SizedBox(height: 22),

          // 6. Botón CTA de Registro y Asignación de Puntos
          InkWell(
            onTap: () {
              widget.onRegisterPurchase?.call(_amount, _ticketController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF141620),
                  content: Text(
                    'Compra registrada: €$amountFormatted • '
                    '$_totalPoints PTS acreditados exitosamente.',
                    style: const TextStyle(color: Color(0xFFE5C07B)),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFE5C07B),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33E5C07B),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card_rounded,
                    size: 18,
                    color: PaseoColors.obsidianBlack,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'REGISTER PURCHASE & AWARD POINTS  →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: PaseoColors.obsidianBlack,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 7. Notas al pie: Auditoría e informe push instantáneo
          const Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_done_outlined,
                    size: 13,
                    color: Color(0xFF787B8A),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'AUTO-SYNCED TO PRIVATE LEDGER',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                      color: Color(0xFF787B8A),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 13,
                    color: Color(0xFF787B8A),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'INSTANT PUSH NOTIFICATION SENT TO CLIENT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                      color: Color(0xFF787B8A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
