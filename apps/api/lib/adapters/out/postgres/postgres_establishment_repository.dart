import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:postgres/postgres.dart';

/// `EstablishmentRepository` sobre las tablas de comercios (V004).
///
/// Solo lectura: esta feature lee el contexto del personal y los clientes,
/// pero no crea comercios ni sucursales (eso es de Persona 4).
final class PostgresEstablishmentRepository implements EstablishmentRepository {
  const PostgresEstablishmentRepository(this._db);

  final PgDatabase _db;

  // uuid llega como bytes genericos del driver: se castea a text.
  static const _contextColumns =
      'es.establishment_id::text AS establishment_id, '
      'e.name AS establishment_name, es.staff_role, '
      'es.branch_id::text AS branch_id, b.name AS branch_name';

  static const _customerColumns =
      'c.user_id::text AS user_id, c.full_name, c.phone, '
      '(c.phone_verified_at IS NOT NULL) AS phone_verified';

  @override
  Future<MerchantContext?> findContext(String userId) async {
    final result = await _db.session.execute(
      Sql.named(
        'SELECT $_contextColumns '
        'FROM app.establishment_staff es '
        'JOIN app.establishments e ON e.id = es.establishment_id '
        'LEFT JOIN app.branches b ON b.id = es.branch_id '
        'WHERE es.user_id = @id::uuid '
        'ORDER BY es.created_at ASC '
        'LIMIT 1',
      ),
      parameters: {'id': userId},
    );
    if (result.isEmpty) {
      return null;
    }
    final row = result.first.toColumnMap();
    final role = switch (row['staff_role']! as String) {
      'OWNER' => MerchantRole.owner,
      'CASHIER' => MerchantRole.cashier,
      _ => null,
    };
    if (role == null) {
      return null;
    }
    return MerchantContext(
      establishmentId: row['establishment_id'].toString(),
      establishmentName: row['establishment_name']! as String,
      userId: userId,
      role: role,
      branchId: row['branch_id'] as String?,
      branchName: row['branch_name'] as String?,
    );
  }

  @override
  Future<CustomerRecord?> findCustomerByPhone(String phone) async {
    final result = await _db.session.execute(
      Sql.named(
        'SELECT $_customerColumns FROM app.customers c '
        'WHERE c.phone = @phone',
      ),
      parameters: {'phone': phone},
    );
    return result.isEmpty ? null : _toCustomer(result.first.toColumnMap());
  }

  @override
  Future<CustomerRecord?> findCustomerByUserId(String userId) async {
    final result = await _db.session.execute(
      Sql.named(
        'SELECT $_customerColumns FROM app.customers c '
        'WHERE c.user_id = @id::uuid',
      ),
      parameters: {'id': userId},
    );
    return result.isEmpty ? null : _toCustomer(result.first.toColumnMap());
  }

  static CustomerRecord _toCustomer(Map<String, dynamic> row) => CustomerRecord(
    userId: row['user_id'].toString(),
    fullName: row['full_name']! as String,
    phone: row['phone']! as String,
    phoneVerified: row['phone_verified']! as bool,
  );
}
