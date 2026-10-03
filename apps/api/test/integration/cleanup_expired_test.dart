import 'package:paseo_api/adapters/out/clock/system_clock.dart';
import 'package:paseo_api/adapters/out/postgres/postgres.dart';
import 'package:paseo_api/application/identity/use_cases/cleanup_expired_credentials.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'support.dart';

// Requiere la base dev en loopback:5433 (AGENTS.md §11). Solo corre
// en el job integration de CI y en local con BD levantada:
//   docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d --wait db

/// Ejecuta SQL arbitrario sin parámetros (solo para cleanup de filas
/// semilla; los tests no limpian la base dev, AGENTS.md §11).
Future<void> _dbExecute(PgDatabase db, String sql) async {
  await db.session.execute(Sql(sql));
}

/// Inserta un usuario mínimo y devuelve su id como texto.
Future<String> _insertUser(PgDatabase db) async {
  final id = newId();
  await db.session.execute(
    Sql.named(
      'INSERT INTO app.users (id, email, password_hash, role) '
      "VALUES (@id::uuid, @email, 'x', 'customer')",
    ),
    parameters: <String, Object?>{'id': id, 'email': uniqueEmail()},
  );
  return id;
}

void main() {
  late PgDatabase db;
  late PostgresVerificationCodeRepository codes;
  late PostgresPasswordResetRepository resets;
  late PostgresRefreshTokenRepository refreshTokens;
  late CleanupExpiredCredentials job;

  setUpAll(() async {
    db = await PgDatabase.open(integrationConfig());
    codes = PostgresVerificationCodeRepository(db);
    resets = PostgresPasswordResetRepository(db);
    refreshTokens = PostgresRefreshTokenRepository(db);
    job = CleanupExpiredCredentials(
      verificationCodes: codes,
      passwordResets: resets,
      refreshTokens: refreshTokens,
      clock: const SystemClock(),
    );
  });

  tearDownAll(() async => db.close());

  group('CleanupExpiredCredentials', () {
    test('borra verification_codes expirados y no toca los vigentes', () async {
      final past = DateTime.now().toUtc().subtract(const Duration(minutes: 10));
      final future = DateTime.now().toUtc().add(const Duration(minutes: 10));

      // Código expirado: debe ser eliminado por el job.
      await db.session.execute(
        Sql.named(
          'INSERT INTO app.verification_codes '
          '(phone, code_hash, purpose, expires_at) '
          "VALUES (@phone, 'hash-exp-vc', 'phone_verify', @exp)",
        ),
        parameters: <String, Object?>{'phone': '+59179000001', 'exp': past},
      );

      // Código vigente: no debe ser eliminado.
      await db.session.execute(
        Sql.named(
          'INSERT INTO app.verification_codes '
          '(phone, code_hash, purpose, expires_at) '
          "VALUES (@phone, 'hash-ok-vc', 'phone_verify', @exp)",
        ),
        parameters: <String, Object?>{'phone': '+59179000001', 'exp': future},
      );

      final result = await job();

      expect(result['verification_codes'], greaterThanOrEqualTo(1));

      final remaining = await db.session.execute(
        Sql(
          "SELECT count(*)::int AS n FROM app.verification_codes "
          "WHERE code_hash = 'hash-ok-vc'",
        ),
      );
      expect(remaining.first.toColumnMap()['n'], equals(1));
    });

    test('borra password_resets expirados y no toca los vigentes', () async {
      final userId = await _insertUser(db);
      final past = DateTime.now().toUtc().subtract(const Duration(minutes: 10));
      final future = DateTime.now().toUtc().add(const Duration(minutes: 30));

      // Reset expirado.
      await db.session.execute(
        Sql.named(
          'INSERT INTO app.password_resets (user_id, token_hash, expires_at) '
          "VALUES (@uid::uuid, 'hash-exp-pr', @exp)",
        ),
        parameters: <String, Object?>{'uid': userId, 'exp': past},
      );

      // Reset vigente.
      await db.session.execute(
        Sql.named(
          'INSERT INTO app.password_resets (user_id, token_hash, expires_at) '
          "VALUES (@uid::uuid, 'hash-ok-pr', @exp)",
        ),
        parameters: <String, Object?>{'uid': userId, 'exp': future},
      );

      final result = await job();

      expect(result['password_resets'], greaterThanOrEqualTo(1));

      final remaining = await db.session.execute(
        Sql(
          "SELECT count(*)::int AS n FROM app.password_resets "
          "WHERE token_hash = 'hash-ok-pr'",
        ),
      );
      expect(remaining.first.toColumnMap()['n'], equals(1));
    });

    test('borra refresh_tokens expirados y no toca los vigentes', () async {
      final userId = await _insertUser(db);
      final familyId = newId();
      final past = DateTime.now().toUtc().subtract(const Duration(minutes: 10));
      final future = DateTime.now().toUtc().add(const Duration(hours: 24));

      const insertSql =
          'INSERT INTO app.refresh_tokens '
          '(user_id, aud, token_hash, family_id, expires_at) '
          "VALUES (@uid::uuid, 'paseo-mobile', @hash, @fid::uuid, @exp)";

      // Token expirado.
      await db.session.execute(
        Sql.named(insertSql),
        parameters: <String, Object?>{
          'uid': userId,
          'hash': 'hash-exp-rt',
          'fid': familyId,
          'exp': past,
        },
      );

      // Token vigente.
      await db.session.execute(
        Sql.named(insertSql),
        parameters: <String, Object?>{
          'uid': userId,
          'hash': 'hash-ok-rt',
          'fid': familyId,
          'exp': future,
        },
      );

      final result = await job();

      expect(result['refresh_tokens'], greaterThanOrEqualTo(1));

      final remaining = await db.session.execute(
        Sql(
          "SELECT count(*)::int AS n FROM app.refresh_tokens "
          "WHERE token_hash = 'hash-ok-rt'",
        ),
      );
      expect(remaining.first.toColumnMap()['n'], equals(1));
    });

    test(
      'devuelve mapa con las tres claves aunque no haya más expirados',
      () async {
        // Los tests anteriores ya borraron sus filas expiradas.
        // El conteo puede ser 0, pero las tres claves siempre deben existir.
        final result = await job();

        expect(result, containsPair('verification_codes', isA<int>()));
        expect(result, containsPair('password_resets', isA<int>()));
        expect(result, containsPair('refresh_tokens', isA<int>()));
      },
    );
  }, timeout: const Timeout(Duration(seconds: 60)));
}
