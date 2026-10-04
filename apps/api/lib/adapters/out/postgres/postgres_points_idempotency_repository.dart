import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/application/points/ports.dart';
import 'package:paseo_api/domain/points/points.dart';
import 'package:postgres/postgres.dart';

/// `PointsIdempotencyRepository` sobre `app.points_idempotency` (V005),
/// clave `(scope, key)` (FR-006; spec C5).
///
/// `reserveOrReplay` solo lee (fuera de la transacción del motor); `confirm`
/// inserta la entrada completa **dentro** de la transacción, tras el ledger:
/// si dos peticiones idénticas corren en paralelo, el `UNIQUE` de
/// `points_ledger.idempotency_key` (o este PK) aborta a la segunda y su
/// transacción revierte limpia; al reintentar, replay de la respuesta.
final class PostgresPointsIdempotencyRepository
    implements PointsIdempotencyRepository {
  const PostgresPointsIdempotencyRepository(this._db);

  final PgDatabase _db;

  @override
  Future<IdempotencyReserveResult> reserveOrReplay({
    required String scope,
    required String key,
    required String requestHash,
  }) async {
    final result = await _db.session.execute(
      Sql.named(
        'SELECT request_hash, ledger_id::text AS ledger_id, response '
        'FROM app.points_idempotency WHERE scope = @s AND key = @k',
      ),
      parameters: {'s': scope, 'k': key},
    );
    if (result.isEmpty) {
      return const IdempotencyReserveResult(foundExisting: false);
    }
    final row = result.first.toColumnMap();
    return IdempotencyReserveResult(
      foundExisting: true,
      storedRequestHash: row['request_hash']! as String,
      storedLedgerId: row['ledger_id'] as String?,
      storedResponse: (row['response'] as Map).cast<String, Object?>(),
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
    try {
      await _db.session.execute(
        Sql.named(
          'INSERT INTO app.points_idempotency '
          '(scope, key, request_hash, response, ledger_id) '
          'VALUES (@s, @k, @h, @r::jsonb, @l::uuid)',
        ),
        parameters: <String, Object?>{
          's': scope,
          'k': key,
          'h': requestHash,
          'r': response,
          'l': ledgerId,
        },
      );
    } on ServerException catch (e) {
      if (e.code == '23505') {
        throw PointsException.conflict('idempotency key duplicada');
      }
      rethrow;
    }
  }
}
