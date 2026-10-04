import 'package:flutter/foundation.dart';

import 'package:paseo_mobile/core/api_client.dart';
import 'package:paseo_mobile/features/catalog/data/catalog_api.dart';
import 'package:paseo_mobile/features/catalog/data/catalog_models.dart';

/// Estado de la pantalla de Establecimientos (HU-09).
final class EstablishmentsController extends ChangeNotifier {
  /// Depende del puerto [CatalogApi], no del adaptador HTTP.
  new(this._api);

  final CatalogApi _api;

  List<EstablishmentSummary>? _establishments;
  ApiException? _error;
  bool _loading = false;

  /// Comercios cargados; `null` mientras no haya carga exitosa.
  List<EstablishmentSummary>? get establishments => _establishments;

  /// Último error de carga; `null` en estado correcto.
  ApiException? get error => _error;

  /// `true` mientras hay una carga en curso.
  bool get isLoading => _loading;

  /// Carga (o recarga) el listado de comercios.
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _establishments = await _api.getEstablishments();
    } on ApiException catch (e) {
      _error = e;
    }
    _loading = false;
    notifyListeners();
  }
}
