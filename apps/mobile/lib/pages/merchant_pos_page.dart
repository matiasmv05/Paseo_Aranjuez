import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paseo_mobile/design_system/atoms/pos_status_pill.dart';
import 'package:paseo_mobile/design_system/molecules/pos_header_bar.dart';
import 'package:paseo_mobile/design_system/organisms/pos_activity_feed.dart';
import 'package:paseo_mobile/design_system/organisms/pos_member_lookup.dart';
import 'package:paseo_mobile/design_system/organisms/pos_purchase_form.dart';
import 'package:paseo_mobile/design_system/templates/merchant_pos_template.dart';
import 'package:paseo_mobile/design_system/tokens/paseo_colors.dart';

/// Pantalla principal del portal de caja del comercio (Boutique POS Terminal).
///
/// Reproduce con fidelidad absoluta la captura de pantalla oficial:
/// - Cabecera con breadcrumb, búsqueda de órdenes y perfil de Elena Vance.
/// - Identificación de socio VIP (NFC, QR, Teléfono) y datos
///   de Alejandro Morales.
/// - Formulario de registro ágil de compras con presets y cálculo
///   dinámico de puntos.
/// - Feed contable en vivo (HU-13) y panel de conciliación del turno.
class MerchantPosPage extends StatefulWidget {
  /// Crea la pantalla del terminal de boutique.
  const new({super.key});

  @override
  State<MerchantPosPage> createState() => _MerchantPosPageState();
}

class _MerchantPosPageState extends State<MerchantPosPage> {
  final List<PosTransactionEntry> _feedTransactions = List.of(
    PosActivityFeed.defaultTransactions,
  );

  void _handleRegisterPurchase(double amount, String ticketNumber) {
    setState(() {
      _feedTransactions.insert(
        0,
        PosTransactionEntry(
          time: 'Ahora',
          clientName: 'Alejandro Morales',
          memberCode: '#ARJ-9921',
          ticketNumber: ticketNumber,
          amountEuro: '€${amount.toStringAsFixed(2)}',
          pointsText: '+${(amount * 1.1).floor()}',
        ),
      );
    });
  }

  void _showScanQrModal() {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF141620),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF2A2D3E)),
            ),
            title: const Row(
              children: [
                Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFE5C07B)),
                SizedBox(width: 10),
                Text(
                  'Lector Óptico de Pase',
                  style: TextStyle(
                    fontFamily: 'serif',
                    color: PaseoColors.textWhite,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 140,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Alinea el código QR del Pase VIP del cliente '
                  'frente a la cámara de la terminal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF787B8A)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'CERRAR',
                  style: TextStyle(
                    color: Color(0xFFE5C07B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showIdentifyNfcModal() {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF141620),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF2A2D3E)),
            ),
            title: const Row(
              children: [
                Icon(Icons.contactless_outlined, color: Color(0xFFE5C07B)),
                SizedBox(width: 10),
                Text(
                  'Sensor NFC de Terminal',
                  style: TextStyle(
                    fontFamily: 'serif',
                    color: PaseoColors.textWhite,
                  ),
                ),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors_rounded, size: 64, color: Color(0xFFE5C07B)),
                SizedBox(height: 16),
                Text(
                  'Esperando token de cliente...\n'
                  'Aproxima el dispositivo o tarjeta del socio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF787B8A)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'CANCELAR',
                  style: TextStyle(
                    color: Color(0xFFE5C07B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MerchantPosTemplate(
      headerBar: PosHeaderBar(
        onNotificationTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF141620),
              content: Text(
                'Terminal sincronizada con el nodo central Aranjuez.',
                style: TextStyle(color: Color(0xFFE5C07B)),
              ),
            ),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Título de página e insignias de enlace activo
            const Text(
              'TERMINAL SUITE • PASEO ARANJUEZ CONCIERGE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: Color(0xFF787B8A),
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Store Front & Quick Entry',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: PaseoColors.textWhite,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Boutique Valldemossa • Level 1, Plaza Norte | '
                        'Establishment Node #918-B',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF787B8A),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PosStatusPill(
                      label: 'POS LINK 01 ACTIVE',
                      dotColor: Color(0xFFE5C07B),
                      textColor: Color(0xFFE5C07B),
                    ),
                    SizedBox(width: 10),
                    PosStatusPill(
                      label: 'DAILY SYNC #4102',
                      textColor: Color(0xFF787B8A),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Sección de autenticación e identificación del cliente
            PosMemberLookup(
              onScanQrTap: _showScanQrModal,
              onIdentifyNfcTap: _showIdentifyNfcModal,
            ),
            const SizedBox(height: 24),

            // 3. Área de trabajo en 2 columnas: Registro de Compra y Feed
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Columna Izquierda: Formulario de Despacho
                      Expanded(
                        flex: 6,
                        child: PosPurchaseForm(
                          onRegisterPurchase: _handleRegisterPurchase,
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Columna Derecha: Feed de Transacciones
                      Expanded(
                        flex: 5,
                        child: PosActivityFeed(transactions: _feedTransactions),
                      ),
                    ],
                  );
                }

                // Disposición apilada para pantallas más estrechas
                return Column(
                  children: [
                    PosPurchaseForm(
                      onRegisterPurchase: _handleRegisterPurchase,
                    ),
                    const SizedBox(height: 24),
                    PosActivityFeed(transactions: _feedTransactions),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
