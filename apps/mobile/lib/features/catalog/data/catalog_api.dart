import 'package:paseo_mobile/core/api_client.dart';
import 'package:paseo_mobile/features/catalog/data/catalog_models.dart';

/// Puerto de datos del catálogo del cliente (solo lectura).
///
/// `data` solo habla HTTP contra el contrato (AGENTS.md §3, regla 2.1).
abstract interface class CatalogApi {
  /// `GET /rewards`: beneficios `ACTIVE` y vigentes; las agotadas llegan con
  /// `available=false` (decisión de la spec 002).
  Future<List<RewardSummary>> getRewards();

  /// `GET /establishments`: comercios adheridos con sus sucursales activas.
  Future<List<EstablishmentSummary>> getEstablishments();
}

/// Implementación HTTP del [CatalogApi] contra la API Paseo.
final class HttpCatalogApi implements CatalogApi {
  /// Crea el adaptador sobre el [ApiClient] compartido.
  const new(this._client);

  final ApiClient _client;

  @override
  Future<List<RewardSummary>> getRewards() async {
    final json = await _client.getJson('/rewards');
    final items = json['items'] as List<Object?>? ?? const [];
    return [
      for (final item in items)
        RewardSummary.fromJson(Map<String, Object?>.from(item! as Map)),
    ];
  }

  @override
  Future<List<EstablishmentSummary>> getEstablishments() async {
    final json = await _client.getJson('/establishments');
    final items = json['items'] as List<Object?>? ?? const [];
    return [
      for (final item in items)
        EstablishmentSummary.fromJson(Map<String, Object?>.from(item! as Map)),
    ];
  }
}
