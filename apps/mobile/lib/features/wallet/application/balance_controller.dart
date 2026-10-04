import 'package:flutter/foundation.dart';

import 'package:paseo_mobile/core/api_client.dart';
import 'package:paseo_mobile/features/wallet/data/wallet_api.dart';
import 'package:paseo_mobile/features/wallet/data/wallet_models.dart';

/// Estado de la pantalla de saldo (HU-04). Estados: loading / success /
/// error ([balance] + [error] + [isLoading] los definen).
final class BalanceController extends ChangeNotifier {
  /// El controlador depende del puerto, no del adaptador HTTP (testeable con
  /// un falso del mismo contrato).
  new(this._api);

  final WalletApi _api;

  Balance? _balance;
  ApiException? _error;
  bool _loading = false;

  /// Último saldo cargado; `null` mientras no haya carga exitosa.
  Balance? get balance => _balance;

  /// Último error de carga; `null` en estado correcto.
  ApiException? get error => _error;

  /// `true` mientras hay una carga en curso.
  bool get isLoading => _loading;

  /// Carga (o recarga) el saldo desde la API.
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _balance = await _api.getBalance();
    } on ApiException catch (e) {
      _error = e;
    }
    _loading = false;
    notifyListeners();
  }
}
