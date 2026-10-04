import 'package:flutter/foundation.dart';

import 'package:paseo_mobile/core/api_client.dart';
import 'package:paseo_mobile/features/wallet/application/balance_controller.dart'
    show BalanceController;
import 'package:paseo_mobile/features/wallet/data/wallet_api.dart';
import 'package:paseo_mobile/features/wallet/data/wallet_models.dart';

/// Estado de la pantalla de historial (HU-05), con paginación por cursor
/// (`next_cursor` del contrato `CursorPage<Movement>`).
final class MovementsController extends ChangeNotifier {
  /// Igual que [BalanceController]: depende del puerto, no de HTTP.
  new(this._api);

  final WalletApi _api;

  final List<Movement> _items = [];
  String? _nextCursor;
  bool _hasMore = true;
  bool _loading = false;
  bool _loadingMore = false;
  ApiException? _error;

  /// Movimientos acumulados de todas las páginas cargadas.
  List<Movement> get items => List.unmodifiable(_items);

  /// `true` si la API indicó que queda otra página.
  bool get hasMore => _hasMore;

  /// `true` mientras carga la primera página (o refresca desde cero).
  bool get isLoading => _loading;

  /// `true` mientras carga una página adicional.
  bool get isLoadingMore => _loadingMore;

  /// Último error; `null` en estado correcto.
  ApiException? get error => _error;

  /// Primera página (o recarga completa: pull-to-refresh).
  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final page = await _api.getMovements();
      _items
        ..clear()
        ..addAll(page.items);
      _nextCursor = page.nextCursor;
      _hasMore = page.nextCursor != null;
    } on ApiException catch (e) {
      _error = e;
    }
    _loading = false;
    notifyListeners();
  }

  /// Página siguiente del historial. No hace nada si no hay más páginas o
  /// ya hay una carga en curso.
  Future<void> loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _api.getMovements(cursor: _nextCursor);
      _items.addAll(page.items);
      _nextCursor = page.nextCursor;
      _hasMore = page.nextCursor != null;
      _error = null;
    } on ApiException catch (e) {
      // Los ítems ya cargados se conservan; el pie ofrece reintento.
      _error = e;
    }
    _loadingMore = false;
    notifyListeners();
  }
}
