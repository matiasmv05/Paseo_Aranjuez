import 'dart:convert';

import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:postgres/postgres.dart';

/// `MovementRepository` sobre `app.purchases` + `app.customers` (V006).
///
/// Orden total `created_at DESC, id DESC` (keyset), cursor opaco que codifica
/// `(created_at, id)` en base64url. `limit + 1` distingue "hay mas" sin un
/// segundo conteo. [MovementRecord.customerName] viaja completo: el caso de
/// uso lo enmascara (T044).
final class PostgresMovementRepository implements MovementRepository {
  const PostgresMovementRepository(this._db);

  final PgDatabase _db;

  // uuid llega como bytes genericos del driver: se castea a text.
  static const _columns =
      'p.id::text AS id, p.created_at, p.invoice_ref, p.gross_cents, '
      'p.discount_cents, p.net_cents, p.points_credited, '
      'p.branch_id::text AS branch_id, c.full_name AS customer_name';

  @override
  Future<MovementPageData> list(MovementQuery query) async {
    final where = <String>['p.establishment_id = @est::uuid'];
    final parameters = <String, Object?>{
      'est': query.establishmentId,
      'limit': query.limit + 1,
    };
    if (query.sellerUserId != null) {
      where.add('p.seller_user_id = @seller::uuid');
      parameters['seller'] = query.sellerUserId;
    }
    if (query.cursor != null) {
      final (createdAt, id) = _decodeCursor(query.cursor!);
      where.add('(p.created_at, p.id) < (@curAt::timestamptz, @curId::uuid)');
      parameters['curAt'] = createdAt;
      parameters['curId'] = id;
    }

    final sql =
        'SELECT $_columns FROM app.purchases p '
        'JOIN app.customers c ON c.user_id = p.customer_id '
        'WHERE ${where.join(' AND ')} '
        'ORDER BY p.created_at DESC, p.id DESC '
        'LIMIT @limit';
    final result = await _db.session.execute(
      Sql.named(sql),
      parameters: parameters,
    );
    final rows = [for (final row in result) row.toColumnMap()];
    final hasMore = rows.length > query.limit;
    final page = hasMore ? rows.sublist(0, query.limit) : rows;
    final items = [for (final row in page) _toMovement(row)];
    final last = items.isEmpty ? null : items.last;
    return MovementPageData(
      items: items,
      nextCursor: hasMore && last != null
          ? _encodeCursor(last.createdAt, last.id)
          : null,
    );
  }

  static MovementRecord _toMovement(Map<String, dynamic> row) => MovementRecord(
    id: row['id'].toString(),
    createdAt: row['created_at']! as DateTime,
    invoiceRef: row['invoice_ref']! as String,
    grossCents: row['gross_cents']! as int,
    discountCents: row['discount_cents']! as int,
    netCents: row['net_cents']! as int,
    pointsCredited: row['points_credited']! as int,
    customerName: row['customer_name']! as String,
    branchId: row['branch_id'].toString(),
  );

  static String _encodeCursor(DateTime createdAt, String id) => base64Url
      .encode(utf8.encode('${createdAt.toUtc().toIso8601String()}|$id'))
      .replaceAll('=', '');

  static (DateTime, String) _decodeCursor(String cursor) {
    try {
      final raw = utf8.decode(base64Url.decode(base64Url.normalize(cursor)));
      final separator = raw.indexOf('|');
      if (separator < 0) {
        throw const FormatException('cursor invalido');
      }
      return (
        DateTime.parse(raw.substring(0, separator)),
        raw.substring(separator + 1),
      );
    } on FormatException {
      throw LoyaltyException.validation('cursor invalido');
    }
  }
}
