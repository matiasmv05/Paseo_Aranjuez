import 'package:paseo_api/adapters/out/postgres/pg.dart';
import 'package:paseo_api/adapters/out/postgres/pg_errors.dart';
import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:postgres/postgres.dart';

/// `VerificationCodeRepository` sobre `app.verification_codes`. La columna
/// `phone` guarda el `target` del puerto: telefono E.164 para OTP
/// (`phone_verify`) y correo para verificacion de correo (`email_verify`);
/// solo hashes (FR-004). Los tokens de correo se buscan por `code_hash`
/// (indice V002) porque el cliente no conoce el target.
final class PostgresVerificationCodeRepository
    implements VerificationCodeRepository {
  const new(this._db);

  final PgDatabase _db;

  // uuid llega como bytes genericos del driver: se castea a text.
  static const _columns =
      'id::text AS id, phone, code_hash, purpose, expires_at, attempts, '
      'consumed_at, created_at';

  @override
  Future<VerificationCodeRecord?> findActive({
    required String target,
    required VerificationPurpose purpose,
    required DateTime now,
    String? tokenHash,
  }) async {
    final byToken = tokenHash != null;
    final where = byToken
        ? 'code_hash = @key AND purpose = @purpose'
        : 'phone = @key AND purpose = @purpose';
    final result = await _db.session.execute(
      Sql.named(
        'SELECT $_columns FROM app.verification_codes '
        'WHERE $where AND consumed_at IS NULL AND expires_at > @now '
        'ORDER BY created_at DESC LIMIT 1',
      ),
      parameters: <String, Object?>{
        'key': byToken ? tokenHash : target,
        'purpose': _purposeToSql(purpose),
        'now': now.toUtc(),
      },
    );
    return result.isEmpty ? null : _toRecord(result.first.toColumnMap());
  }

  @override
  Future<VerificationCodeRecord?> findLatest({
    required String target,
    required VerificationPurpose purpose,
  }) async {
    final result = await _db.session.execute(
      Sql.named(
        'SELECT $_columns FROM app.verification_codes '
        'WHERE phone = @target AND purpose = @purpose '
        'ORDER BY created_at DESC LIMIT 1',
      ),
      parameters: <String, Object?>{
        'target': target,
        'purpose': _purposeToSql(purpose),
      },
    );
    return result.isEmpty ? null : _toRecord(result.first.toColumnMap());
  }

  @override
  Future<int> countIssuedSince({
    required String target,
    required DateTime since,
  }) async {
    final result = await _db.session.execute(
      Sql.named(
        'SELECT count(*)::int AS n FROM app.verification_codes '
        'WHERE phone = @target AND created_at >= @since',
      ),
      parameters: <String, Object?>{'target': target, 'since': since.toUtc()},
    );
    return result.first.toColumnMap()['n']! as int;
  }

  @override
  Future<void> insert({
    required String id,
    required String target,
    required VerificationPurpose purpose,
    required String codeHash,
    required VerificationState challenge,
  }) async {
    try {
      await _db.session.execute(
        Sql.named(
          'INSERT INTO app.verification_codes '
          '(id, phone, code_hash, purpose, expires_at, attempts, '
          'consumed_at, created_at) VALUES '
          '(@id::uuid, @target, @codeHash, @purpose, @expiresAt, @attempts, '
          '@consumedAt, @createdAt)',
        ),
        parameters: <String, Object?>{
          'id': id,
          'target': target,
          'codeHash': codeHash,
          'purpose': _purposeToSql(purpose),
          'expiresAt': _expiresAt(challenge).toUtc(),
          'attempts': challenge is OtpChallenge ? challenge.attempts : 0,
          'consumedAt': challenge.isConsumed ? _consumedAt(challenge) : null,
          'createdAt': challenge.createdAt.toUtc(),
        },
      );
    } on ServerException catch (e) {
      throwMappedPgError(e);
    }
  }

  @override
  Future<void> updateChallenge(String id, VerificationState challenge) async {
    await _db.session.execute(
      Sql.named(
        'UPDATE app.verification_codes '
        'SET attempts = @attempts, consumed_at = @consumedAt '
        'WHERE id = @id::uuid',
      ),
      parameters: <String, Object?>{
        'id': id,
        'attempts': challenge is OtpChallenge ? challenge.attempts : 0,
        'consumedAt': challenge.isConsumed ? _consumedAt(challenge) : null,
      },
    );
  }

  static VerificationCodeRecord _toRecord(Map<String, dynamic> row) {
    final purpose = row['purpose']! as String;
    final createdAt = row['created_at']! as DateTime;
    final expiresAt = row['expires_at']! as DateTime;
    final consumedAt = row['consumed_at'] as DateTime?;
    final challenge = purpose == 'email_verify'
        ? EmailVerification.restore(
            createdAt: createdAt,
            expiresAt: expiresAt,
            consumedAt: consumedAt,
          )
        : OtpChallenge.restore(
            createdAt: createdAt,
            expiresAt: expiresAt,
            attempts: row['attempts']! as int,
            consumedAt: consumedAt,
          );
    return VerificationCodeRecord(
      id: row['id'].toString(),
      target: row['phone']! as String,
      purpose: purpose == 'email_verify'
          ? VerificationPurpose.emailVerification
          : VerificationPurpose.phoneVerification,
      codeHash: row['code_hash']! as String,
      challenge: challenge,
    );
  }

  static String _purposeToSql(VerificationPurpose purpose) => switch (purpose) {
    VerificationPurpose.phoneVerification => 'phone_verify',
    VerificationPurpose.emailVerification => 'email_verify',
  };

  static DateTime _expiresAt(VerificationState challenge) =>
      switch (challenge) {
        OtpChallenge(:final expiresAt) => expiresAt,
        EmailVerification(:final expiresAt) => expiresAt,
        _ => throw ArgumentError('VerificationState desconocido'),
      };

  static DateTime? _consumedAt(VerificationState challenge) =>
      switch (challenge) {
        OtpChallenge(:final consumedAt) => consumedAt,
        EmailVerification(:final consumedAt) => consumedAt,
        _ => throw ArgumentError('VerificationState desconocido'),
      };

  /// Borra códigos expirados (`expires_at < now`). Devuelve cuántos.
  @override
  Future<int> deleteExpired(DateTime now) async {
    final result = await _db.session.execute(
      Sql.named('DELETE FROM app.verification_codes WHERE expires_at < @now'),
      parameters: <String, Object?>{'now': now.toUtc()},
    );
    return result.affectedRows;
  }
}
