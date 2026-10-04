import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paseo_mobile/features/merchant/application/merchant_session.dart';
import 'package:paseo_mobile/features/merchant/data/merchant_api_client.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;

/// Pantalla de registro de compra (T105, HU-11).
///
/// Ingresa montos en centavos e `invoice_ref`; calcula los puntos con
/// `preview` (nunca localmente) y confirma con `register` usando una
/// `Idempotency-Key` unica. El servidor es la fuente de verdad (§2).
class PurchaseScreen extends ConsumerStatefulWidget {
  /// Crea la pantalla con el ticket de identificacion y el nombre visible.
  const PurchaseScreen({
    required this.ticket,
    required this.customerName,
    super.key,
  });

  /// Ticket firmado de `identify`.
  final String ticket;

  /// Nombre enmascarado del cliente.
  final String customerName;

  @override
  ConsumerState<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends ConsumerState<PurchaseScreen> {
  final _gross = TextEditingController();
  final _discount = TextEditingController(text: '0');
  final _net = TextEditingController();
  final _invoice = TextEditingController();

  contract.PreviewPurchaseResult? _preview;
  contract.Purchase? _purchase;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _gross.addListener(_recomputeNet);
    _discount.addListener(_recomputeNet);
  }

  @override
  void dispose() {
    _gross.dispose();
    _discount.dispose();
    _net.dispose();
    _invoice.dispose();
    super.dispose();
  }

  void _recomputeNet() {
    final gross = int.tryParse(_gross.text.trim()) ?? 0;
    final discount = int.tryParse(_discount.text.trim()) ?? 0;
    _net.text = '${gross - discount < 0 ? 0 : gross - discount}';
  }

  contract.RegisterPurchaseRequest? _buildRequest() {
    final gross = int.tryParse(_gross.text.trim());
    final discount = int.tryParse(_discount.text.trim());
    final net = int.tryParse(_net.text.trim());
    final invoice = _invoice.text.trim();
    if (gross == null || discount == null || net == null || invoice.isEmpty) {
      setState(() {
        _error = 'Completa monto bruto, descuento, neto y numero de factura.';
      });
      return null;
    }
    return contract.RegisterPurchaseRequest(
      ticket: widget.ticket,
      grossCents: gross,
      discountCents: discount,
      netCents: net,
      invoiceRef: invoice,
    );
  }

  Future<void> _runPreview() async {
    final request = _buildRequest();
    if (request == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _purchase = null;
    });
    final api = ref.read(merchantApiProvider);
    try {
      final preview = await api.preview(
        contract.PreviewPurchaseRequest(
          ticket: request.ticket,
          grossCents: request.grossCents,
          discountCents: request.discountCents,
          netCents: request.netCents,
        ),
      );
      if (!mounted) return;
      setState(() {
        _preview = preview;
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

  Future<void> _register() async {
    final request = _buildRequest();
    if (request == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = ref.read(merchantApiProvider);
    final idempotencyKey = MerchantApiClient.newIdempotencyKey();
    try {
      final purchase = await api.registerPurchase(
        request,
        idempotencyKey: idempotencyKey,
      );
      if (!mounted) return;
      setState(() {
        _purchase = purchase;
        _preview = null;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compra registrada: ${purchase.pointsCredited} pts'),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final purchase = _purchase;
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar compra')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Cliente: ${widget.customerName}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _gross,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto bruto (centavos)',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _discount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Descuento (centavos)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _net,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Monto neto (centavos)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _invoice,
            decoration: const InputDecoration(labelText: 'Numero de factura'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : () => unawaited(_runPreview()),
                  child: const Text('Previsualizar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : () => unawaited(_register()),
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Registrar'),
                ),
              ),
            ],
          ),
          if (preview != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Puntos a otorgar: ${preview.points}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (preview.breakdown.belowMinPurchase)
                      const Text('Compra bajo el minimo: no otorga puntos.'),
                    if (preview.breakdown.capApplied)
                      const Text('Se aplico el tope de puntos.'),
                  ],
                ),
              ),
            ),
          ],
          if (purchase != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compra registrada: ${purchase.pointsCredited} pts',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('Factura: ${purchase.invoiceRef}'),
                    Text('Neto: ${purchase.netCents} centavos'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
