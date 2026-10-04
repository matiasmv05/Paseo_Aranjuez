import 'package:flutter/foundation.dart';

import 'package:paseo_mobile/core/api_client.dart';
import 'package:paseo_mobile/features/catalog/data/catalog_api.dart';
import 'package:paseo_mobile/features/catalog/data/catalog_models.dart';

/// Estado de la pantalla Catálogo de beneficios (HU-06).
final class RewardsController extends ChangeNotifier {
  /// Depende del puerto [CatalogApi], no del adaptador HTTP.
  new(this._api);

  final CatalogApi _api;

  List<RewardSummary>? _rewards;
  ApiException? _error;
  bool _loading = false;

  /// Beneficios cargados; `null` mientras no haya carga exitosa.
  List<RewardSummary>? get rewards => _rewards;

  /// Último error de carga; `null` en estado correcto.
  ApiException? get error => _error;

  /// `true` mientras hay una carga en curso.
  bool get isLoading => _loading;

  /// Carga (o recarga) el catálogo.
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _rewards = await _api.getRewards();
    } on ApiException catch (e) {
      _error = e;
    }
    _loading = false;
    notifyListeners();
  }
}
