import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/application/points/ports.dart';
import 'package:paseo_api/domain/points/points.dart';
import 'package:postgres/postgres.dart';

/// `MovementsRepository` sobre `app.points_ledger` (HU-05, FR-002).
///
/// Cursor opaco `(occurred_at, ledger_id)` (spec C7) resuelto con la
/// comparación de tuplas `(occurred_at, id) < (@at, @id)` descendente:
/// orden estable sin repetidos ni omitidos aunque dos filas compartan
/// `occurred_at`. Sondea `limit + 1` filas para saber si hay siguiente
/// página. Solo lee el ledger del `customerId` pedido (SEC-001: viene del
/// JWT en la ruta).
final class PostgresMovementsRepository implements MovementsRepository {
  const PostgresMovementsRepository(this._db);

  final PgDatabase _db;

  static const _columns =
      'id::text AS id, type, delta, occurred_at, balance_after, '
      'purchase_id::text AS purchase_id, reverses_ledger_id::text AS rev';

  @override
  Future<MovementsPage> getPage({
    required String customerId,
    String? cursor,
    int limit = 20,
  }) async {
    final after = cursor == null ? null : PointsCursor.decode(cursor);
    final result = await _db.session.execute(
      Sql.named(
        'SELECT $_columns FROM app.points_ledger '
        'WHERE customer_id = @c::uuid '
        '${after == null ? '' : 'AND (occurred_at, id) < (@at::timestamptz, @l::uuid) '}'
        'ORDER BY occurred_at DESC, id DESC LIMIT @lim',
      ),
      parameters: <String, Object?>{
        'c': customerId,
        if (after != null) 'at': after.occurredAt,
        if (after != null) 'l': after.ledgerId,
        'lim': limit + 1,
      },
    );

    final rows = result.map((r) => r.toColumnMap()).toList();
    final hasMore = rows.length > limit;
    final items = rows.take(limit).map(_toMovement).toList();
    final nextCursor = hasMore
        ? PointsCursor.encode(
            occurredAt: items.last.occurredAt,
            ledgerId: items.last.id,
          )
        : null;
    return MovementsPage(items: items, nextCursor: nextCursor);
  }

  LedgerMovement _toMovement(Map<String, dynamic> row) {
    final type = MovementType.parseWire(row['type']! as String);
    final purchaseId = row['purchase_id'] as String?;
    final reversingId = row['rev'] as String?;
    final id = row['id']! as String;
    // La referencia de la operación se deriva del vínculo existente
    // (compra o reversión); sin vínculo, el propio ledger_id (p. ej. un
    // REDEEM de 002, cuya tabla `redemptions` llega con 005).
    final (origin, referenceId) = purchaseId != null
        ? ('purchase', purchaseId)
        : reversingId != null
        ? ('reversal', reversingId)
        : (type.origin, id);
    return LedgerMovement(
      id: id,
      type: type,
      deltaPoints: row['delta']! as int,
      occurredAt: row['occurred_at']! as DateTime,
      origin: origin,
      referenceId: referenceId,
      balanceAfter: row['balance_after']! as int,
    );
  }
}
