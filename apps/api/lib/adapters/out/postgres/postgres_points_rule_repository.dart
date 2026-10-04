import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:postgres/postgres.dart';

/// `PointsRuleRepository` sobre `app.points_rules` (V005).
///
/// Devuelve las reglas candidatas (comercio + categoria + globales) vigentes
/// en la fecha pedida, sin resolver: la precedencia y la campana unica las
/// decide `RuleResolver` en dominio (§7).
final class PostgresPointsRuleRepository implements PointsRuleRepository {
  const PostgresPointsRuleRepository(this._db);

  final PgDatabase _db;

  // uuid llega como bytes genericos del driver: se castea a text.
  static const _columns =
      'id::text AS id, scope, type, priority, points_awarded, '
      'amount_per_tier_cents, multiplier_bp, max_points_per_purchase, '
      'min_purchase_cents, rounding, valid_from, valid_to, '
      'establishment_id::text AS establishment_id, '
      'category_id::text AS category_id';

  static const _query =
      'SELECT $_columns FROM app.points_rules '
      'WHERE valid_from <= @now::timestamptz '
      'AND (valid_to IS NULL OR valid_to > @now::timestamptz) AND ( '
      '(scope = @stScope AND establishment_id = @est::uuid) OR '
      '(scope = @catScope AND category_id = @cat::uuid) OR '
      '(scope = @globScope))';

  @override
  Future<List<PointsRule>> findApplicableRules({
    required String establishmentId,
    String? categoryId,
    required DateTime now,
  }) async {
    final result = await _db.session.execute(
      Sql.named(_query),
      parameters: <String, Object?>{
        'now': now.toUtc(),
        'est': establishmentId,
        'cat': categoryId,
        'stScope': PointsRuleScope.establishment.wire,
        'catScope': PointsRuleScope.category.wire,
        'globScope': PointsRuleScope.global.wire,
      },
    );
    return [for (final row in result) _toRule(row.toColumnMap())];
  }

  static PointsRule _toRule(Map<String, dynamic> row) => PointsRule(
    id: row['id'].toString(),
    scope: PointsRuleScope.fromWire(row['scope']! as String),
    type: PointsRuleType.fromWire(row['type']! as String),
    priority: row['priority']! as int,
    pointsAwarded: row['points_awarded']! as int,
    amountPerTierCents: row['amount_per_tier_cents']! as int,
    multiplierBp: row['multiplier_bp']! as int,
    maxPointsPerPurchase: row['max_points_per_purchase'] as int?,
    minPurchaseCents: row['min_purchase_cents']! as int,
    rounding: Rounding.fromWire(row['rounding']! as String),
    validFrom: row['valid_from']! as DateTime,
    validTo: row['valid_to'] as DateTime?,
    establishmentId: row['establishment_id'] as String?,
    categoryId: row['category_id'] as String?,
  );
}
