import 'dart:convert';

import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:postgres/postgres.dart';

/// `PurchaseRepository` sobre `app.purchases` + `app.points_ledger` (V006).
///
/// `insert` corre en una sola transaccion: la compra, el `CREDIT` del ledger
/// (si hubo puntos) y el `audit_log` (regla 2.4). Nunca escribe
/// `customer_balances`: lo mantiene el trigger (regla 2.3).
final class PostgresPurchaseRepository implements PurchaseRepository {
  const PostgresPurchaseRepository(this._db);

  final PgDatabase _db;

  // uuid llega como bytes genericos del driver: se castea a text.
  static const _columns =
      'id::text AS id, establishment_id::text AS establishment_id, '
      'branch_id::text AS branch_id, customer_id::text AS customer_id, '
      'seller_user_id::text AS seller_user_id, gross_cents, discount_cents, '
      'net_cents, invoice_ref, rule_id::text AS rule_id, '
      'campaign_rule_id::text AS campaign_rule_id, rule_snapshot, '
      'idempotency_key, points_credited, created_at';

  @override
  Future<Purchase?> findByIdempotencyKey({
    required String establishmentId,
    required String idempotencyKey,
  }) async {
    final result = await _db.session.execute(
      Sql.named(
        'SELECT $_columns FROM app.purchases '
        'WHERE establishment_id = @est::uuid AND idempotency_key = @key',
      ),
      parameters: {'est': establishmentId, 'key': idempotencyKey},
    );
    return result.isEmpty ? null : _toPurchase(result.first.toColumnMap());
  }

  @override
  Future<Purchase?> findByInvoiceRef({
    required String establishmentId,
    required String invoiceRef,
  }) async {
    final result = await _db.session.execute(
      Sql.named(
        'SELECT $_columns FROM app.purchases '
        'WHERE establishment_id = @est::uuid AND invoice_ref = @ref',
      ),
      parameters: {'est': establishmentId, 'ref': invoiceRef},
    );
    return result.isEmpty ? null : _toPurchase(result.first.toColumnMap());
  }

  @override
  Future<Purchase> insert(
    PurchaseDraft draft,
  ) => _db.runInTransaction(() async {
    final ResultRow row;
    try {
      final result = await _db.session.execute(
        Sql.named(
          'INSERT INTO app.purchases ( '
          'establishment_id, branch_id, customer_id, seller_user_id, '
          'gross_cents, discount_cents, net_cents, invoice_ref, '
          'rule_id, campaign_rule_id, rule_snapshot, idempotency_key, '
          'points_credited) VALUES ( '
          '@est::uuid, @branch::uuid, @customer::uuid, @seller::uuid, '
          '@gross, @discount, @net, @invoice, @rule::uuid, '
          '@campaign::uuid, @snapshot::jsonb, @key, @points) '
          'RETURNING $_columns',
        ),
        parameters: <String, Object?>{
          'est': draft.establishmentId,
          'branch': draft.branchId,
          'customer': draft.customerId,
          'seller': draft.sellerUserId,
          'gross': draft.grossCents,
          'discount': draft.discountCents,
          'net': draft.netCents,
          'invoice': draft.invoiceRef,
          'rule': draft.ruleId,
          'campaign': draft.campaignRuleId,
          'snapshot': jsonEncode(draft.ruleSnapshot),
          'key': draft.idempotencyKey,
          'points': draft.pointsCredited,
        },
      );
      row = result.first;
    } on ServerException catch (e) {
      final field = _uniqueField(e);
      if (field != null) {
        // Rollback automatico: el use case reintenta y devuelve el ganador.
        throw PurchaseUniqueViolation(field);
      }
      rethrow;
    }

    final purchase = _toPurchase(row.toColumnMap());
    if (draft.pointsCredited > 0) {
      await _db.session.execute(
        Sql.named(
          'INSERT INTO app.points_ledger '
          '(customer_id, establishment_id, type, delta, purchase_id, reason) '
          'VALUES (@customer::uuid, @est::uuid, @type, @delta, '
          '@purchase::uuid, @reason)',
        ),
        parameters: <String, Object?>{
          'customer': draft.customerId,
          'est': draft.establishmentId,
          'type': 'CREDIT',
          'delta': draft.pointsCredited,
          'purchase': purchase.id,
          'reason': 'compra',
        },
      );
    }
    await _db.session.execute(
      Sql.named(
        'INSERT INTO app.audit_log (actor_user_id, action, entity, entity_id) '
        'VALUES (@userId::uuid, @action, @entity, @entityId)',
      ),
      parameters: <String, Object?>{
        'userId': draft.sellerUserId,
        'action': 'purchase.register',
        'entity': 'purchase',
        'entityId': purchase.id,
      },
    );
    return purchase;
  });

  static PurchaseUniqueField? _uniqueField(ServerException e) =>
      switch (e.constraintName) {
        'purchases_idempotency_uk' => PurchaseUniqueField.idempotencyKey,
        'purchases_establishment_invoice_uk' => PurchaseUniqueField.invoiceRef,
        _ => null,
      };

  static Purchase _toPurchase(Map<String, dynamic> row) => Purchase(
    id: row['id'].toString(),
    establishmentId: row['establishment_id'].toString(),
    branchId: row['branch_id'].toString(),
    customerId: row['customer_id'].toString(),
    sellerUserId: row['seller_user_id'].toString(),
    grossCents: row['gross_cents']! as int,
    discountCents: row['discount_cents']! as int,
    netCents: row['net_cents']! as int,
    invoiceRef: row['invoice_ref']! as String,
    ruleId: row['rule_id'].toString(),
    campaignRuleId: row['campaign_rule_id']?.toString(),
    ruleSnapshot: _snapshot(row['rule_snapshot']),
    idempotencyKey: row['idempotency_key']! as String,
    pointsCredited: row['points_credited']! as int,
    createdAt: row['created_at']! as DateTime,
  );

  static Map<String, Object?> _snapshot(Object? raw) {
    if (raw is Map) {
      return Map<String, Object?>.from(raw);
    }
    return Map<String, Object?>.from(jsonDecode(raw! as String) as Map);
  }
}
