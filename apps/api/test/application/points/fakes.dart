import 'package:paseo_api/application/identity/ports.dart' show AuditLogWriter;
import 'package:paseo_api/application/points/ports.dart';
import 'package:paseo_api/domain/points/points.dart';

/// Fakes en memoria para los puertos del módulo de puntos (T010). Sin
/// `mocktail`: `class implements` con registro de llamadas, como pide la
/// tarea. Los de infraestructura genérica (`FakeTransactionRunner`,
/// `FixedClock`, `SequentialIds`, `MockAuditLogWriter`) se reutilizan
/// desde `test/application/identity/fakes.dart`.

/// Ledger en memoria. `failNextInsert` inyecta un error en el siguiente
/// `insertCredit`/`insertDebit` (para probar rollback y saldo
/// insuficiente). El `balance_after` lo calcula el fake (en la base lo
/// rellena el trigger).
final class FakeLedgerRepository implements PointsLedgerRepository {
  final creditInserts = <Map<String, Object?>>[];
  final debitInserts = <Map<String, Object?>>[];
  Object? failNextInsert;
  int _balance = 0;
  var _seq = 0;

  void seedBalance(int balance) => _balance = balance;

  @override
  Future<LedgerInsertResult> insertCredit({
    required String customerId,
    required int points,
    required String reference,
    required DateTime occurredAt,
    String? purchaseId,
    String? idempotencyKey,
  }) async {
    final failure = failNextInsert;
    if (failure != null) {
      failNextInsert = null;
      throw failure;
    }
    _balance += points;
    final id = 'ledger-${++_seq}';
    creditInserts.add({
      'customerId': customerId,
      'points': points,
      'reference': reference,
      'purchaseId': purchaseId,
      'idempotencyKey': idempotencyKey,
    });
    return LedgerInsertResult(
      id: id,
      balanceAfter: _balance,
      occurredAt: occurredAt,
    );
  }

  @override
  Future<LedgerInsertResult> insertDebit({
    required String customerId,
    required int points,
    required String reference,
    required DateTime occurredAt,
    String? idempotencyKey,
  }) async {
    final failure = failNextInsert;
    if (failure != null) {
      failNextInsert = null;
      throw failure;
    }
    // El CHECK (balance >= 0) aborta con 23514 si queda negativo. En el
    // fake lo simulamos antes de tocar el saldo.
    if (_balance - points < 0) {
      throw PointsException.insufficientPoints();
    }
    _balance -= points;
    final id = 'ledger-${++_seq}';
    debitInserts.add({
      'customerId': customerId,
      'points': points,
      'reference': reference,
      'idempotencyKey': idempotencyKey,
    });
    return LedgerInsertResult(
      id: id,
      balanceAfter: _balance,
      occurredAt: occurredAt,
    );
  }
}

/// Compras en memoria; devuelve el `id` generado.
final class FakePurchaseRepository implements PurchaseRepository {
  final inserted = <PurchaseInput>[];
  var _seq = 0;

  @override
  Future<String> insert(PurchaseInput input) async {
    inserted.add(input);
    return 'purchase-${++_seq}';
  }
}

/// Idempotencia (scope, key) en memoria: `reserveOrReplay` lee; `confirm`
/// inserta la entrada completa (response + ledgerId). Si ya existe una
/// entrada confirmada, `reserveOrReplay` la devuelve para replay/conflict.
final class FakePointsIdempotencyRepository
    implements PointsIdempotencyRepository {
  static String _k(String scope, String key) => '$scope|$key';
  final entries = <String, _IdemEntry>{};

  @override
  Future<IdempotencyReserveResult> reserveOrReplay({
    required String scope,
    required String key,
    required String requestHash,
  }) async {
    final existing = entries[_k(scope, key)];
    if (existing == null) {
      return const IdempotencyReserveResult(foundExisting: false);
    }
    return IdempotencyReserveResult(
      foundExisting: true,
      storedRequestHash: existing.requestHash,
      storedLedgerId: existing.ledgerId,
      storedResponse: existing.response,
    );
  }

  @override
  Future<void> confirm({
    required String scope,
    required String key,
    required String requestHash,
    required String ledgerId,
    required Map<String, Object?> response,
  }) async {
    entries[_k(scope, key)] = _IdemEntry(
      requestHash: requestHash,
      ledgerId: ledgerId,
      response: response,
    );
  }
}

final class _IdemEntry {
  const new({
    required this.requestHash,
    required this.ledgerId,
    required this.response,
  });
  final String requestHash;
  final String ledgerId;
  final Map<String, Object?> response;
}

/// Balance en memoria (T011).
final class FakeBalanceRepository implements BalanceRepository {
  final balances = <String, BalanceView>{};

  @override
  Future<BalanceView?> findByCustomerId(String customerId) async =>
      balances[customerId];
}

/// Movimientos en memoria (T011).
final class FakeMovementsRepository implements MovementsRepository {
  List<LedgerMovement> rows = <LedgerMovement>[];

  @override
  Future<MovementsPage> getPage({
    required String customerId,
    String? cursor,
    int limit = 20,
  }) async {
    var slice = rows.toList();
    if (cursor != null) {
      final data = PointsCursor.decode(cursor);
      slice = slice
          .where(
            (m) =>
                m.occurredAt.isBefore(data.occurredAt) ||
                (m.occurredAt == data.occurredAt &&
                    m.id.compareTo(data.ledgerId) < 0),
          )
          .toList();
    }
    slice = slice.take(limit).toList();
    final hasNext = rows.isNotEmpty && slice.length == limit;
    final nextCursor = hasNext && slice.isNotEmpty
        ? PointsCursor.encode(
            occurredAt: slice.last.occurredAt,
            ledgerId: slice.last.id,
          )
        : null;
    return MovementsPage(items: slice, nextCursor: nextCursor);
  }
}

/// Recompensas en memoria (T011).
final class FakeRewardsRepository implements RewardsRepository {
  List<RewardRecord> rows = <RewardRecord>[];

  @override
  Future<List<RewardRecord>> listActive({required DateTime now}) async => rows;
}

/// Establecimientos en memoria (T011).
final class FakeEstablishmentsRepository implements EstablishmentsRepository {
  List<EstablishmentRecord> rows = <EstablishmentRecord>[];

  @override
  Future<List<EstablishmentRecord>> listActive() async => rows;
}

/// `AuditLogWriter` que registra cada `write` para aserciones (sin PII:
/// los campos son `action`/`entityType`/`entityId`/`userId`/`role`).
final class RecordingAuditLogWriter implements AuditLogWriter {
  final calls = <Map<String, Object?>>[];

  @override
  Future<void> write({
    required String action,
    required String entityType,
    String? entityId,
    String? userId,
    String role = 'system',
  }) async {
    calls.add({
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'userId': userId,
      'role': role,
    });
  }

  Map<String, Object?>? lastWhere(String action) {
    for (final c in calls.reversed) {
      if (c['action'] == action) return c;
    }
    return null;
  }
}
