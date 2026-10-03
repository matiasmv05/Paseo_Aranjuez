import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/adapters/out/postgres/pg_errors.dart';
import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:postgres/postgres.dart';

/// `CustomerRepository` sobre `app.customers`. `full_name` en base es
/// NOT NULL: se persiste la cadena vacia cuando el registro no lo trae
/// (columna informativa; nunca viaja al JWT).
final class PostgresCustomerRepository implements CustomerRepository {
  const PostgresCustomerRepository(this._db);

  final PgDatabase _db;

  // uuid llega como bytes genericos del driver: se castea a text.
  static const _columns =
      'user_id::text AS user_id, phone, full_name, phone_verified_at';

  @override
  Future<CustomerProfile?> findByUserId(String userId) async {
    final result = await _db.session.execute(
      Sql.named(
        'SELECT $_columns FROM app.customers WHERE user_id = @id::uuid',
      ),
      parameters: {'id': userId},
    );
    return result.isEmpty ? null : _toProfile(result.first.toColumnMap());
  }

  @override
  Future<CustomerProfile?> findByPhone(PhoneBO phone) async {
    final result = await _db.session.execute(
      Sql.named('SELECT $_columns FROM app.customers WHERE phone = @phone'),
      parameters: {'phone': phone.value},
    );
    return result.isEmpty ? null : _toProfile(result.first.toColumnMap());
  }

  /// `null` si el telefono ya existe (via `ON CONFLICT DO NOTHING`: un
  /// 23505 capturado abortaria la transaccion entera, 25P02).
  @override
  Future<CustomerProfile?> insertIfAbsent(CustomerProfile profile) async {
    try {
      final result = await _db.session.execute(
        Sql.named(
          'INSERT INTO app.customers (user_id, phone, full_name) '
          'VALUES (@userId::uuid, @phone, @fullName) '
          'ON CONFLICT (phone) DO NOTHING RETURNING $_columns',
        ),
        parameters: <String, Object?>{
          'userId': profile.userId,
          'phone': profile.phone,
          'fullName': profile.fullName ?? '',
        },
      );
      return result.isEmpty ? null : _toProfile(result.first.toColumnMap());
    } on ServerException catch (e) {
      throwMappedPgError(e);
    }
  }

  @override
  Future<void> markPhoneVerified({
    required String userId,
    required DateTime at,
  }) async {
    await _db.session.execute(
      Sql.named(
        'UPDATE app.customers SET phone_verified_at = @at::timestamptz '
        'WHERE user_id = @id::uuid',
      ),
      parameters: <String, Object?>{'id': userId, 'at': at.toUtc()},
    );
  }

  static CustomerProfile _toProfile(Map<String, dynamic> row) =>
      CustomerProfile(
        userId: row['user_id'].toString(),
        phone: row['phone']! as String,
        fullName: (row['full_name']! as String).isEmpty
            ? null
            : row['full_name']! as String,
        phoneVerifiedAt: row['phone_verified_at'] as DateTime?,
      );
}
