import 'package:paseo_api/application/identity/ports.dart' show Clock;
import 'package:paseo_api/application/points/ports.dart';

/// Casos de uso de lectura del módulo de puntos (HU-04, HU-05, HU-06,
/// HU-09). Las rutas son finas: validan, llaman uno de estos casos de uso
/// y mapean a RFC 9457 (AGENTS.md §3). El `customerId` siempre viene del
/// JWT verificado (SEC-001); nunca del cuerpo ni de la query.

/// Saldo del cliente (HU-04, FR-001). El cliente sin movimientos tiene
/// saldo `0` y **no** se crea fila vacía en `customer_balances` (spec
/// US1.1); por eso [updatedAt] es `null` en ese caso.
final class GetBalance {
  const GetBalance({required BalanceRepository balances})
    : _balances = balances;

  final BalanceRepository _balances;

  Future<BalanceResult> call({required String customerId}) async {
    final view = await _balances.findByCustomerId(customerId);
    if (view == null) {
      return const BalanceResult(balance: 0);
    }
    return BalanceResult(balance: view.balance, updatedAt: view.updatedAt);
  }
}

/// Resultado de [GetBalance].
final class BalanceResult {
  const BalanceResult({required this.balance, this.updatedAt});

  final int balance;

  /// `null` cuando el cliente no tiene movimientos.
  final DateTime? updatedAt;
}

/// Historial de movimientos (HU-05, FR-002). Cursor opaco
/// `(occurred_at, ledger_id)` (spec C7); `limit` por defecto 20 y acotado
/// al máximo 50 del contrato. Un cursor inválido propaga
/// [FormatException]; la ruta lo mapea a 422 `VALIDATION`.
final class GetMovements {
  const GetMovements({required MovementsRepository movements})
    : _movements = movements;

  static const int defaultLimit = 20;
  static const int maxLimit = 50;

  final MovementsRepository _movements;

  Future<MovementsPage> call({
    required String customerId,
    String? cursor,
    int? limit,
  }) {
    final effectiveLimit = (limit ?? defaultLimit).clamp(1, maxLimit);
    return _movements.getPage(
      customerId: customerId,
      cursor: cursor,
      limit: effectiveLimit,
    );
  }
}

/// Catálogo de recompensas para el cliente (HU-06, FR-003): solo `ACTIVE`
/// vigentes; las de `stock = 0` llegan marcadas `available=false`
/// (decisión 2026-10-03). La vigencia se evalúa con la hora del servidor
/// (spec C2), nunca con la del cliente.
final class ListRewards {
  const ListRewards({required RewardsRepository rewards, required Clock clock})
    : _rewards = rewards,
      _clock = clock;

  final RewardsRepository _rewards;
  final Clock _clock;

  Future<List<RewardRecord>> call() =>
      _rewards.listActive(now: _clock.nowUtc());
}

/// Establecimientos participantes para el cliente (HU-09, FR-004): solo
/// activos, sin baja lógica y sin campos administrativos.
final class ListEstablishments {
  const ListEstablishments({required EstablishmentsRepository establishments})
    : _establishments = establishments;

  final EstablishmentsRepository _establishments;

  Future<List<EstablishmentRecord>> call() => _establishments.listActive();
}
