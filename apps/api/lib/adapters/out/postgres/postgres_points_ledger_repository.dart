import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/application/points/ports.dart';
import 'package:paseo_api/domain/points/points.dart';
import 'package:paseo_shared/paseo_shared.dart';
import 'package:postgres/postgres.dart';

/// `PointsLedgerRepository` sobre `app.points_ledger` (V005), único punto de
/// escritura de puntos (regla 2.2). El saldo y `balance_after` los rellena
/// el trigger `SECURITY DEFINER` durante el INSERT; aquí solo se leen con
/// `RETURNING`.
///
/// Mapeo de errores físicos (sin copiar mensajes del servidor: pueden
/// contener datos de la fila):
/// - `23514` (CHECK `balance >= 0`) → [PointsException.insufficientPoints]
///   (AGENTS.md §9).
/// - `23505` (idempotency_key / reverses únicos) → `CONFLICT`.
/// - `23503` (FK inexistente) → `VALIDATION_FAILED`.
///
/// Nota: la `reference` del puerto no tiene columna en el ledger (V005);
/// la referencia de negocio viaja por `purchase_id` / `reverses_ledger_id`
/// y por la respuesta guardada en `points_idempotency`.
final class PostgresPointsLedgerRepository implements PointsLedgerRepository {
  const PostgresPointsLedgerRepository(this._db);

  final PgDatabase _db;

  static const _returning =
      'RETURNING id::text AS id, balance_after, occurred_at';

  @override
  Future<LedgerInsertResult> insertCredit({
    required String customerId,
    required int points,
    required String reference,
    String? purchaseId,
    required DateTime occurredAt,
    String? idempotencyKey,
  }) => _insert(
    customerId: customerId,
    delta: points,
    type: MovementType.credit.wire,
    purchaseId: purchaseId,
    occurredAt: occurredAt,
    idempotencyKey: idempotencyKey,
  );

  @override
  Future<LedgerInsertResult> insertDebit({
    required String customerId,
    required int points,
    required String reference,
    required DateTime occurredAt,
    String? idempotencyKey,
  }) => _insert(
    customerId: customerId,
    delta: -points,
    type: MovementType.redeem.wire,
    occurredAt: occurredAt,
    idempotencyKey: idempotencyKey,
  );

  Future<LedgerInsertResult> _insert({
    required String customerId,
    required int delta,
    required String type,
    String? purchaseId,
    required DateTime occurredAt,
    String? idempotencyKey,
  }) async {
    try {
      final result = await _db.session.execute(
        Sql.named(
          'INSERT INTO app.points_ledger '
          '(customer_id, delta, type, purchase_id, idempotency_key, occurred_at) '
          'VALUES (@c::uuid, @d, @t, @p::uuid, @k, @at::timestamptz) '
          '$_returning',
        ),
        parameters: <String, Object?>{
          'c': customerId,
          'd': delta,
          't': type,
          'p': purchaseId,
          'k': idempotencyKey,
          'at': occurredAt,
        },
      );
      final row = result.first.toColumnMap();
      return LedgerInsertResult(
        id: row['id']! as String,
        balanceAfter: row['balance_after']! as int,
        occurredAt: row['occurred_at']! as DateTime,
      );
    } on ServerException catch (e) {
      throw switch (e.code) {
        '23514' => PointsException.insufficientPoints(),
        '23505' => PointsException.conflict('movimiento duplicado'),
        '23503' => const PointsException(
          ApiErrorCode.validationFailed,
          'referencia inexistente',
        ),
        _ => e,
      };
    }
  }
}
