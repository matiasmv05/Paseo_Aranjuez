import 'dart:async';

import 'package:paseo_mobile/features/catalog/data/catalog_api.dart';
import 'package:paseo_mobile/features/catalog/data/catalog_models.dart';
import 'package:paseo_mobile/features/wallet/data/wallet_api.dart';
import 'package:paseo_mobile/features/wallet/data/wallet_models.dart';

/// Falso de [WalletApi] con respuestas programadas: implementa el mismo
/// contrato que el adaptador HTTP, sin tocar red ni base de datos (T019).
final class FakeWalletApi implements WalletApi {
  /// Respuesta de `getBalance`.
  Balance? balanceResult;

  /// Error forzado de `getBalance`.
  Object? balanceError;

  /// Compulsera opcional para dejar `getBalance` pendiente (estado loading).
  Completer<void>? balanceGate;

  /// Páginas en cola que devuelve `getMovements` (una por llamada).
  final List<MovementsPage> movementPages = [];

  /// Error forzado de `getMovements`.
  Object? movementsError;

  /// Llamadas recibidas a `getBalance`.
  int balanceCalls = 0;

  /// Llamadas recibidas a `getMovements`.
  int movementsCalls = 0;

  @override
  Future<Balance> getBalance() async {
    balanceCalls++;
    await balanceGate?.future;
    final error = balanceError;
    if (error != null) throw error;
    return balanceResult!;
  }

  @override
  Future<MovementsPage> getMovements({String? cursor, int limit = 20}) async {
    movementsCalls++;
    final error = movementsError;
    if (error != null) throw error;
    return movementPages.removeAt(0);
  }
}

/// Falso de [CatalogApi] con respuestas programadas (T019).
final class FakeCatalogApi implements CatalogApi {
  /// Respuesta de `getRewards`; `null` equivale a lista vacía.
  List<RewardSummary>? rewardsResult;

  /// Error forzado de `getRewards`.
  Object? rewardsError;

  /// Respuesta de `getEstablishments`; `null` equivale a lista vacía.
  List<EstablishmentSummary>? establishmentsResult;

  /// Error forzado de `getEstablishments`.
  Object? establishmentsError;

  @override
  Future<List<RewardSummary>> getRewards() async {
    final error = rewardsError;
    if (error != null) throw error;
    return rewardsResult ?? const [];
  }

  @override
  Future<List<EstablishmentSummary>> getEstablishments() async {
    final error = establishmentsError;
    if (error != null) throw error;
    return establishmentsResult ?? const [];
  }
}

/// Movimiento de ejemplo del ledger.
Movement movement({
  int n = 1,
  MovementType type = MovementType.credit,
  int delta = 100,
  int balance = 100,
}) => Movement(
  id: 'm-$n',
  type: type,
  deltaPoints: delta,
  occurredAt: DateTime.utc(2026, 10, 3, 12).add(Duration(hours: n)),
  origin: type == MovementType.redeem
      ? MovementOrigin.redemption
      : MovementOrigin.purchase,
  referenceId: 'ref-$n',
  balanceAfter: balance,
);

/// Recompensa de ejemplo del catálogo.
RewardSummary reward({
  String id = 'r-1',
  String name = 'Café gratis',
  RewardType type = RewardType.gift,
  int cost = 150,
  int? stock = 3,
  bool available = true,
}) => RewardSummary(
  id: id,
  name: name,
  description: 'Descripción de $name',
  type: type,
  costPoints: cost,
  stock: stock,
  available: available,
  validFrom: null,
  validTo: DateTime.utc(2026, 12, 31),
  establishmentId: 'est-1',
);

/// Establecimiento de ejemplo con una sucursal.
EstablishmentSummary establishment({
  String id = 'est-1',
  String name = 'Café Plaza Murillo',
  String category = 'Cafetería',
}) => EstablishmentSummary(
  id: id,
  name: name,
  category: category,
  branches: const [
    BranchSummary(id: 'b-1', name: 'Principal', address: 'Calle Comercio 123'),
  ],
);
