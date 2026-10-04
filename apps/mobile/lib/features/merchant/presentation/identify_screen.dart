import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paseo_mobile/features/merchant/application/merchant_session.dart';
import 'package:paseo_mobile/features/merchant/data/merchant_api_client.dart';
import 'package:paseo_mobile/features/merchant/presentation/purchase_screen.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;

/// Formas de identificar al cliente en el mostrador.
enum IdentifyMethod {
  /// Identificacion por telefono (`+591` + 8 digitos).
  phone,

  /// Identificacion por token de QR.
  qr,
}

/// Pantalla de identificacion del cliente (T104, HU-10).
///
/// Permite identificar por telefono boliviano (`+591` + 8 digitos) o por
/// token de QR; muestra el nombre enmascarado y abre la compra con el
/// ticket firmado.
class IdentifyScreen extends ConsumerStatefulWidget {
  /// Crea la pantalla de identificacion.
  const IdentifyScreen({super.key});

  @override
  ConsumerState<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends ConsumerState<IdentifyScreen> {
  static final _phonePattern = RegExp(r'^\+591[0-9]{8}$');

  final _phone = TextEditingController();
  final _qr = TextEditingController();

  IdentifyMethod _method = IdentifyMethod.phone;
  contract.IdentifyResult? _result;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    _qr.dispose();
    super.dispose();
  }

  Future<void> _identify() async {
    final phone = _phone.text.trim();
    if (_method == IdentifyMethod.phone && !_phonePattern.hasMatch(phone)) {
      setState(() {
        _error = 'Ingresa un telefono boliviano (+591 y 8 digitos).';
        _result = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    final api = ref.read(merchantApiProvider);
    try {
      final request = _method == IdentifyMethod.phone
          ? contract.IdentifyByPhoneRequest(phone: phone)
          : contract.IdentifyByQrRequest(qrToken: _qr.text.trim());
      final result = await api.identify(request);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } on MerchantApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = describeMerchantError(error);
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo conectar con el servidor.';
        _loading = false;
      });
    }
  }

  void _openPurchase() {
    final result = _result;
    if (result == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PurchaseScreen(
          ticket: result.ticket,
          customerName: result.customerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Identificar cliente',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        SegmentedButton<IdentifyMethod>(
          segments: const [
            ButtonSegment(value: IdentifyMethod.phone, label: Text('Telefono')),
            ButtonSegment(value: IdentifyMethod.qr, label: Text('QR')),
          ],
          selected: {_method},
          onSelectionChanged: (selection) => setState(() {
            _method = selection.first;
            _error = null;
            _result = null;
          }),
        ),
        const SizedBox(height: 16),
        if (_method == IdentifyMethod.phone)
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefono (+591...)',
              hintText: '+59170000001',
            ),
          )
        else
          TextField(
            controller: _qr,
            decoration: const InputDecoration(labelText: 'Token de QR'),
          ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _loading ? null : () => unawaited(_identify()),
          child: _loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Identificar'),
        ),
        if (result != null) ...[
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cliente identificado'),
                  const SizedBox(height: 8),
                  Text(
                    result.customerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _openPurchase,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Registrar compra'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
