import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/adapters/out/postgres/pg_errors.dart';
import 'package:paseo_api/application/identity/ports.dart';
import 'package:postgres/postgres.dart';

/// `PasswordResetRepository` sobre `app.password_resets`: solo hash del
/// token, 30 min (lo fija el caso de uso), un solo uso (`tryMarkUsed`
/// atomico).
final class PostgresPasswordResetRepository implements PasswordResetRepository {
  const new(this._db);

  final PgDatabase _db;

  @override
  Future<PasswordResetRecord?> findByTokenHash(String tokenHash) async {
    final result = await _db.session.execute(
      Sql.named(
        // uuid llega como bytes genericos del driver: se castea a text.
        'SELECT id::text AS id, user_id::text AS user_id, expires_at, '
        'used_at FROM app.password_resets WHERE token_hash = @tokenHash',
      ),
      parameters: {'tokenHash': tokenHash},
    );
    if (result.isEmpty) return null;
    final row = result.first.toColumnMap();
    return PasswordResetRecord(
      id: row['id'].toString(),
      userId: row['user_id'].toString(),
      expiresAt: row['expires_at']! as DateTime,
      usedAt: row['used_at'] as DateTime?,
    );
  }

  @override
  Future<void> insert({
    required String id,
    required String userId,
    required String tokenHash,
    required DateTime expiresAt,
  }) async {
    try {
      await _db.session.execute(
        Sql.named(
          'INSERT INTO app.password_resets '
          '(id, user_id, token_hash, expires_at) VALUES '
          '(@id::uuid, @userId::uuid, @tokenHash, @expiresAt)',
        ),
        parameters: <String, Object?>{
          'id': id,
          'userId': userId,
          'tokenHash': tokenHash,
          'expiresAt': expiresAt.toUtc(),
        },
      );
    } on ServerException catch (e) {
      throwMappedPgError(e);
    }
  }

  @override
  Future<bool> tryMarkUsed({required String id, required DateTime at}) async {
    final result = await _db.session.execute(
      Sql.named(
        'UPDATE app.password_resets SET used_at = @at::timestamptz '
        'WHERE id = @id::uuid AND used_at IS NULL',
      ),
      parameters: <String, Object?>{'id': id, 'at': at.toUtc()},
    );
    return result.affectedRows == 1;
  }

  /// Borra resets expirados (`expires_at < now`). Devuelve cuántos.
  @override
  Future<int> deleteExpired(DateTime now) async {
    final result = await _db.session.execute(
      Sql.named('DELETE FROM app.password_resets WHERE expires_at < @now'),
      parameters: <String, Object?>{'now': now.toUtc()},
    );
    return result.affectedRows;
  }
}
