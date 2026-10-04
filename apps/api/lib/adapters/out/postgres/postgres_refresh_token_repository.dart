import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/adapters/out/postgres/pg_errors.dart';
import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:postgres/postgres.dart';

/// `RefreshTokenRepository` sobre `app.refresh_tokens`: solo hash, familia
/// para deteccion de reutilizacion (FR-007). `jti` lo genera la base
/// (`DEFAULT gen_random_uuid()`, V002): el puerto no lo transporta.
final class PostgresRefreshTokenRepository implements RefreshTokenRepository {
  const new(this._db);

  final PgDatabase _db;

  // uuid llega como bytes genericos del driver: se castea a text.
  static const _columns =
      'id::text AS id, family_id::text AS family_id, user_id::text AS user_id, '
      'aud, expires_at, revoked_at';

  @override
  Future<RefreshTokenRecord?> findByTokenHash(String tokenHash) async {
    final result = await _db.session.execute(
      Sql.named(
        'SELECT $_columns FROM app.refresh_tokens '
        'WHERE token_hash = @tokenHash',
      ),
      parameters: {'tokenHash': tokenHash},
    );
    if (result.isEmpty) return null;
    final row = result.first.toColumnMap();
    return RefreshTokenRecord(
      id: row['id'].toString(),
      familyId: row['family_id'].toString(),
      userId: row['user_id'].toString(),
      audience: row['aud']! as String,
      expiresAt: row['expires_at']! as DateTime,
      revokedAt: row['revoked_at'] as DateTime?,
    );
  }

  @override
  Future<void> insert({
    required String id,
    required String familyId,
    required String userId,
    required String audience,
    required String tokenHash,
    required DateTime expiresAt,
  }) async {
    try {
      await _db.session.execute(
        Sql.named(
          'INSERT INTO app.refresh_tokens '
          '(id, family_id, user_id, aud, token_hash, expires_at) VALUES '
          '(@id::uuid, @familyId::uuid, @userId::uuid, @aud, @tokenHash, '
          '@expiresAt)',
        ),
        parameters: <String, Object?>{
          'id': id,
          'familyId': familyId,
          'userId': userId,
          'aud': audience,
          'tokenHash': tokenHash,
          'expiresAt': expiresAt.toUtc(),
        },
      );
    } on ServerException catch (e) {
      throwMappedPgError(e);
    }
  }

  /// Reclamo atomico de la rotacion: un solo ganador en concurrencia
  /// (`affectedRows == 0` → otro proceso gano → reutilizacion).
  @override
  Future<bool> tryClaimRotation({
    required String id,
    required DateTime at,
  }) async {
    final result = await _db.session.execute(
      Sql.named(
        'UPDATE app.refresh_tokens SET revoked_at = @at::timestamptz '
        'WHERE id = @id::uuid AND revoked_at IS NULL',
      ),
      parameters: <String, Object?>{'id': id, 'at': at.toUtc()},
    );
    return result.affectedRows == 1;
  }

  @override
  Future<void> revokeFamily({
    required String familyId,
    required DateTime at,
  }) async {
    await _db.session.execute(
      Sql.named(
        'UPDATE app.refresh_tokens SET revoked_at = @at::timestamptz '
        'WHERE family_id = @familyId::uuid AND revoked_at IS NULL',
      ),
      parameters: <String, Object?>{'familyId': familyId, 'at': at.toUtc()},
    );
  }

  @override
  Future<void> revokeAllForUser({
    required String userId,
    required DateTime at,
  }) async {
    await _db.session.execute(
      Sql.named(
        'UPDATE app.refresh_tokens SET revoked_at = @at::timestamptz '
        'WHERE user_id = @userId::uuid AND revoked_at IS NULL',
      ),
      parameters: <String, Object?>{'userId': userId, 'at': at.toUtc()},
    );
  }

  /// Borra refresh tokens expirados (`expires_at < now`). Devuelve cuántos.
  @override
  Future<int> deleteExpired(DateTime now) async {
    final result = await _db.session.execute(
      Sql.named('DELETE FROM app.refresh_tokens WHERE expires_at < @now'),
      parameters: <String, Object?>{'now': now.toUtc()},
    );
    return result.affectedRows;
  }
}
