import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/application/points/ports.dart';
import 'package:paseo_api/domain/points/points.dart';
import 'package:paseo_shared/paseo_shared.dart';
import 'package:postgres/postgres.dart';

/// `PurchaseRepository` sobre `app.purchases` (V005): soporte del `CREDIT`
/// del ledger. El endpoint de registro de compras es de la feature 003;
/// aquí solo la inserción mínima que el motor necesita en la misma
/// transacción. Montos en centavos enteros (regla 2.9).
///
/// `23505` (idempotency_key UNIQUE o `(establishment_id, invoice_ref)`
/// único parcial) → `CONFLICT` determinista (spec US3.3).
final class PostgresPurchaseRepository implements PurchaseRepository {
  const PostgresPurchaseRepository(this._db);

  final PgDatabase _db;

  @override
  Future<String> insert(PurchaseInput input) async {
    try {
      final result = await _db.session.execute(
        Sql.named(
          'INSERT INTO app.purchases '
          '(establishment_id, branch_id, customer_id, gross_cents, '
          'discount_cents, net_cents, invoice_ref, idempotency_key) '
          'VALUES (@e::uuid, @b::uuid, @c::uuid, @g, @d, @n, @i, @k) '
          'RETURNING id::text AS id',
        ),
        parameters: <String, Object?>{
          'e': input.establishmentId,
          'b': input.branchId,
          'c': input.customerId,
          'g': input.grossCents,
          'd': input.discountCents,
          'n': input.netCents,
          'i': input.invoiceRef,
          'k': input.idempotencyKey,
        },
      );
      return result.first.toColumnMap()['id']! as String;
    } on ServerException catch (e) {
      throw switch (e.code) {
        '23505' => PointsException.conflict('compra duplicada'),
        '23503' => const PointsException(
          ApiErrorCode.validationFailed,
          'referencia inexistente',
        ),
        _ => e,
      };
    }
  }
}
