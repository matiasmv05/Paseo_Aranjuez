import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/application/points/ports.dart';
import 'package:postgres/postgres.dart';

/// `RewardsRepository` sobre `app.rewards` (V006): catálogo de lectura del
/// cliente (HU-06, FR-003). Solo `ACTIVE` vigentes (la hora la pasa el caso
/// de uso desde el servidor — spec C2); las de `stock = 0` se incluyen con
/// `available=false` (decisión 2026-10-03). Nunca selecciona campos
/// administrativos (`approved_by`, etc.).
final class PostgresRewardsRepository implements RewardsRepository {
  const PostgresRewardsRepository(this._db);

  final PgDatabase _db;

  @override
  Future<List<RewardRecord>> listActive({required DateTime now}) async {
    final result = await _db.session.execute(
      Sql.named(
        'SELECT id::text AS id, name, description, reward_type, cost_points, '
        'stock, valid_from, valid_to, establishment_id::text AS est '
        'FROM app.rewards '
        "WHERE status = 'ACTIVE' "
        'AND (valid_from IS NULL OR valid_from <= @n::timestamptz) '
        'AND (valid_to IS NULL OR valid_to > @n::timestamptz) '
        'ORDER BY cost_points, name',
      ),
      parameters: {'n': now},
    );
    return result.map((r) {
      final row = r.toColumnMap();
      final stock = row['stock'] as int?;
      return RewardRecord(
        id: row['id']! as String,
        name: row['name']! as String,
        description: row['description']! as String,
        rewardType: row['reward_type']! as String,
        costPoints: row['cost_points']! as int,
        stock: stock,
        available: stock == null || stock > 0,
        validFrom: row['valid_from'] as DateTime?,
        validTo: row['valid_to'] as DateTime?,
        establishmentId: row['est']! as String,
      );
    }).toList();
  }
}
