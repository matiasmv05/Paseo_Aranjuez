import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/molecules/pos_member_card.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Organismo de autenticación e identificación del cliente en caja (NFC/QR/Tel).
class PosMemberLookup extends StatefulWidget {
  /// Crea la sección de identificación de socio.
  const new({
    super.key,
    this.initialPhone = '+34691882109',
    this.onScanQrTap,
    this.onIdentifyNfcTap,
  });

  /// Teléfono inicial precargado o ingresado.
  final String initialPhone;

  /// Callback al solicitar escaneo óptico de QR.
  final VoidCallback? onScanQrTap;

  /// Callback al solicitar identificación por NFC.
  final VoidCallback? onIdentifyNfcTap;

  @override
  State<PosMemberLookup> createState() => _PosMemberLookupState();
}

class _PosMemberLookupState extends State<PosMemberLookup> {
  late final TextEditingController _phoneController;
  bool _isMemberIdentified = true;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10121A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF202332)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabecera de la sección
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MEMBER AUTHENTICATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Color(0xFF787B8A),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Client Identification',
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
              SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.security_rounded,
                    size: 14,
                    color: Color(0xFFE5C07B),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'CRYPTOGRAPHIC NFC & OPTICAL TERMINAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: Color(0xFFE5C07B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Fila de búsqueda y botones rápidos
          Row(
            children: [
              // Campo de teléfono y botón Query
              Expanded(
                flex: 4,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161822),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF262838)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_search_outlined,
                        size: 20,
                        color: Color(0xFF787B8A),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: PaseoColors.textWhite,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Ingresa teléfono boliviano (+591...)',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5B5D6D),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() => _isMemberIdentified = true);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF242636),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF373A4F)),
                          ),
                          child: const Text(
                            'QUERY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: PaseoColors.textWhite,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Botón 1: SCAN OPTICAL PASS / QR (Oro)
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: widget.onScanQrTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5C07B),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33E5C07B),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 18,
                          color: PaseoColors.obsidianBlack,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'SCAN OPTICAL\nPASS / QR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            height: 1.1,
                            color: PaseoColors.obsidianBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Botón 2: IDENTIFY PHONE / NFC (Oscuro)
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: widget.onIdentifyNfcTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161822),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: PaseoColors.goldMetallic.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.contactless_outlined,
                          size: 18,
                          color: Color(0xFFE5C07B),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'IDENTIFY PHONE /\nNFC',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            height: 1.1,
                            color: PaseoColors.textWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Tarjeta del cliente identificado (Alejandro Morales)
          if (_isMemberIdentified)
            PosMemberCard(
              onSwitchClient: () {
                setState(() => _isMemberIdentified = !_isMemberIdentified);
              },
            ),
        ],
      ),
    );
  }
}
