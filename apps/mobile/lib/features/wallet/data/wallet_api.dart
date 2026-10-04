import 'package:paseo_mobile/core/api_client.dart';
import 'package:paseo_mobile/features/wallet/data/wallet_models.dart';

/// Puerto de datos del monedero del cliente (solo lectura).
///
/// `data` solo habla HTTP contra el contrato (AGENTS.md §3, regla 2.1).
abstract interface class WalletApi {
  /// `GET /me/balance`: saldo actual del cliente autenticado.
  Future<Balance> getBalance();

  /// `GET /me/movements`: página del historial. [cursor] es el
  /// `next_cursor` de la página anterior; la API limita [limit] a 50.
  Future<MovementsPage> getMovements({String? cursor, int limit = 20});
}

/// Implementación HTTP del [WalletApi] contra la API Paseo.
final class HttpWalletApi implements WalletApi {
  /// Crea el adaptador sobre el [ApiClient] compartido.
  const new(this._client);

  final ApiClient _client;

  @override
  Future<Balance> getBalance() async {
    final json = await _client.getJson('/me/balance');
    return Balance.fromJson(json);
  }

  @override
  Future<MovementsPage> getMovements({String? cursor, int limit = 20}) async {
    final json = await _client.getJson(
      '/me/movements',
      queryParameters: {'cursor': ?cursor, 'limit': '$limit'},
    );
    return MovementsPage.fromJson(json);
  }
}
