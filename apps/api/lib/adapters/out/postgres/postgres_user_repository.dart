import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/adapters/out/postgres/pg_errors.dart';
import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:postgres/postgres.dart';

/// `UserRepository` sobre `app.users` (V002). Requiere contexto RLS activo
/// (rol `system` en identidad); sin el, RLS oculta las filas.
final class PostgresUserRepository implements UserRepository {
  const PostgresUserRepository(this._db);

  final PgDatabase _db;

  // citext/uuid llegan como bytes genericos del driver: se castean a text.
  static const _columns =
      'id::text AS id, email::text AS email, password_hash, role, status, '
      'token_version, email_verified_at';

  @override
  Future<User?> findByEmail(Email email) async {
    final result = await _db.session.execute(
      Sql.named('SELECT $_columns FROM app.users WHERE email = @email'),
      parameters: {'email': email.value},
    );
    return result.isEmpty ? null : _toUser(result.first.toColumnMap());
  }

  @override
  Future<User?> findById(String id) async {
    final result = await _db.session.execute(
      Sql.named('SELECT $_columns FROM app.users WHERE id = @id::uuid'),
      parameters: {'id': id},
    );
    return result.isEmpty ? null : _toUser(result.first.toColumnMap());
  }

  /// `ON CONFLICT DO NOTHING RETURNING`: el duplicado devuelve `null` sin
  /// lanzar (un 23505 capturado abortaria la transaccion entera, 25P02).
  @override
  Future<User?> insertIfAbsent({
    required String id,
    required Email email,
    required String passwordHash,
    required UserRole role,
  }) async {
    try {
      final result = await _db.session.execute(
        Sql.named(
          'INSERT INTO app.users (id, email, password_hash, role) '
          'VALUES (@id::uuid, @email, @passwordHash, @role) '
          'ON CONFLICT (email) DO NOTHING RETURNING $_columns',
        ),
        parameters: <String, Object?>{
          'id': id,
          'email': email.value,
          'passwordHash': passwordHash,
          'role': _roleToSql(role),
        },
      );
      return result.isEmpty ? null : _toUser(result.first.toColumnMap());
    } on ServerException catch (e) {
      throwMappedPgError(e);
    }
  }

  @override
  Future<void> incrementTokenVersion(String userId) async {
    await _db.session.execute(
      Sql.named(
        'UPDATE app.users SET token_version = token_version + 1 '
        'WHERE id = @id::uuid',
      ),
      parameters: {'id': userId},
    );
  }

  @override
  Future<void> setPassword({
    required String userId,
    required String passwordHash,
  }) async {
    await _db.session.execute(
      Sql.named(
        'UPDATE app.users SET password_hash = @passwordHash '
        'WHERE id = @id::uuid',
      ),
      parameters: <String, Object?>{'id': userId, 'passwordHash': passwordHash},
    );
  }

  @override
  Future<void> markEmailVerified(String userId) async {
    await _db.session.execute(
      Sql.named(
        'UPDATE app.users SET email_verified_at = now() '
        'WHERE id = @id::uuid AND email_verified_at IS NULL',
      ),
      parameters: {'id': userId},
    );
  }

  static User _toUser(Map<String, dynamic> row) {
    // V002 aun no tiene establishment_id/branch_id (llegan con comercios);
    // para identidad se persisten ausentes.
    final status = row['status']! as String;
    final emailVerifiedAt = row['email_verified_at'] as DateTime?;
    return User(
      id: row['id'].toString(),
      email: row['email']! as String,
      passwordHash: row['password_hash']! as String,
      role: _roleFromSql(row['role']! as String),
      // Dominio solo distingue active/blocked: BLOCKED → blocked;
      // OBSERVED y POINTS_SUSPENDED no bloquean el login (antifraude MVP).
      status: status == 'BLOCKED' ? UserStatus.blocked : UserStatus.active,
      tokenVersion: row['token_version']! as int,
      emailVerified: emailVerifiedAt != null,
    );
  }

  static String _roleToSql(UserRole role) => switch (role) {
    UserRole.customer => 'customer',
    UserRole.merchantOwner => 'merchant_owner',
    UserRole.merchantCashier => 'merchant_cashier',
    UserRole.admin => 'admin',
  };

  static UserRole _roleFromSql(String role) => switch (role) {
    'merchant_owner' => UserRole.merchantOwner,
    'merchant_cashier' => UserRole.merchantCashier,
    'admin' => UserRole.admin,
    _ => UserRole.customer,
  };
}
