import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paseo_mobile/features/merchant/application/merchant_session.dart';
import 'package:paseo_mobile/features/merchant/data/merchant_api_client.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;

/// Pantalla de movimientos del comercio (T106, HU-13).
///
/// Lista paginada por cursor con scroll infinito: al llegar al final pide
/// la siguiente pagina. El cajero solo ve sus propias compras (el servidor
/// aplica el aislamiento); la UI no filtra nada.
class MovementsScreen extends ConsumerStatefulWidget {
  /// Crea la pantalla de movimientos.
  const MovementsScreen({super.key});

  @override
  ConsumerState<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends ConsumerState<MovementsScreen> {
  final _scroll = ScrollController();
  final _items = <contract.MerchantMovement>[];

  String? _nextCursor;
  String? _error;
  bool _loading = false;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    if (_loading) return;
    if (_hasLoaded && _nextCursor == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = ref.read(merchantApiProvider);
    try {
      final page = await api.movements(cursor: _nextCursor);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _nextCursor = page.nextCursor;
        _hasLoaded = true;
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

  String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && !_loading) {
      return Center(
        child: _error == null
            ? const Text('Sin movimientos todavia.')
            : Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        _items.clear();
        _nextCursor = null;
        _hasLoaded = false;
        await _load();
      },
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index == _items.length) return _buildFooter();
          final movement = _items[index];
          return Card(
            child: ListTile(
              title: Text(movement.customerName),
              subtitle: Text(
                '${movement.invoiceRef} - ${movement.createdAt.toLocal()}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${movement.pointsCredited} pts',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(_money(movement.netCents)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(
              onPressed: () => unawaited(_load()),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_nextCursor != null) {
      return Center(
        child: TextButton(
          onPressed: () => unawaited(_load()),
          child: const Text('Cargar mas'),
        ),
      );
    }
    return const SizedBox(height: 24);
  }
}
