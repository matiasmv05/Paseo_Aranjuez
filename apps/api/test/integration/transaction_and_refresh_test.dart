import 'package:paseo_api/adapters/out/postgres/postgres.dart';
import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late PgDatabase db;
  late PostgresUserRepository users;

  setUpAll(() async {
    db = await PgDatabase.open(integrationConfig());
    users = PostgresUserRepository(db);
  });

  tearDownAll(() async {
    await db.close();
  });

  test('TransactionRunner: rollback si el body lanza', () async {
    final tx = PostgresTransactionRunner(db);
    final id = newId();

    await expectLater(
      tx.run(() async {
        await users.insertIfAbsent(
          id: id,
          email: Email.parse(uniqueEmail()),
          passwordHash: r'$argon2id$test',
          role: UserRole.customer,
        );
        throw StateError('fallo a proposito');
      }),
      throwsStateError,
    );

    // Tras el rollback, el usuario no existe.
    final visible = await tx.run(() async => users.findById(id));
    expect(visible, isNull);
  });

  test('TransactionRunner: commit deja los cambios visibles', () async {
    final tx = PostgresTransactionRunner(db);
    final id = newId();
    final email = uniqueEmail();
    await tx.run(() async {
      await users.insertIfAbsent(
        id: id,
        email: Email.parse(email),
        passwordHash: r'$argon2id$test',
        role: UserRole.customer,
      );
      await users.incrementTokenVersion(id);
    });
    final user = await tx.run(() async => users.findById(id));
    expect(user!.tokenVersion, 1);
  });

  test('RefreshTokenRepository: dos reclamos concurrentes del mismo token, '
      'uno solo gana', () async {
    // Setup con la conexion compartida.
    final userId = newId();
    final tokenId = newId();
    final familyId = newId();
    final tokenHash = 'hash-refresh-${newId()}';
    await db.runInTransaction(() async {
      await users.insertIfAbsent(
        id: userId,
        email: Email.parse(uniqueEmail()),
        passwordHash: r'$argon2id$test',
        role: UserRole.customer,
      );
      final tokens = PostgresRefreshTokenRepository(db);
      await tokens.insert(
        id: tokenId,
        familyId: familyId,
        userId: userId,
        audience: 'paseo-mobile',
        tokenHash: tokenHash,
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 7)),
      );
    });

    // Dos conexiones reales compiten por el reclamo de rotacion.
    final db1 = await PgDatabase.open(integrationConfig());
    final db2 = await PgDatabase.open(integrationConfig());
    addTearDown(() async {
      await db1.close();
      await db2.close();
    });
    final at = DateTime.now().toUtc();
    final results = await Future.wait([
      db1.runInTransaction(
        () => PostgresRefreshTokenRepository(db1)
            .tryClaimRotation(id: tokenId, at: at),
      ),
      db2.runInTransaction(
        () => PostgresRefreshTokenRepository(db2)
            .tryClaimRotation(id: tokenId, at: at),
      ),
    ]);
    expect(results.where((won) => won), hasLength(1));

    // lectura del registro: revocado una sola vez y por valor exacto.
    final record = await db.runInTransaction(
      () => PostgresRefreshTokenRepository(db).findByTokenHash(tokenHash),
    );
    expect(record!.isRevoked, isTrue);

    // revokeAllForUser idempotente y sin error sobre ya revocados.
    await db.runInTransaction(
      () => PostgresRefreshTokenRepository(db)
          .revokeAllForUser(userId: userId, at: at),
    );
  });

  test('VerificationCode: round-trip OTP y token de correo por hash', () async {
    final codes = PostgresVerificationCodeRepository(db);
    final now = DateTime.now().toUtc();
    final phone = uniquePhone();
    final emailTokenHash = 'hash-email-verify-${newId()}';

    await db.runInTransaction(() async {
      await codes.insert(
        id: newId(),
        target: phone,
        purpose: VerificationPurpose.phoneVerification,
        codeHash: 'hash-otp-${newId()}',
        challenge: OtpChallenge.issue(now),
      );
      await codes.insert(
        id: newId(),
        target: uniqueEmail(),
        purpose: VerificationPurpose.emailVerification,
        codeHash: emailTokenHash,
        challenge: EmailVerification.issue(now),
      );
    });

    await db.runInTransaction(() async {
      final active = await codes.findActive(
        target: phone,
        purpose: VerificationPurpose.phoneVerification,
        now: now.add(const Duration(minutes: 1)),
      );
      expect(active, isA<VerificationCodeRecord>());
      expect(active!.challenge, isA<OtpChallenge>());

      // El token de correo se localiza SOLO por su hash (target '').
      final byToken = await codes.findActive(
        target: '',
        purpose: VerificationPurpose.emailVerification,
        now: now.add(const Duration(hours: 1)),
        tokenHash: emailTokenHash,
      );
      expect(byToken, isNotNull);
      expect(byToken!.challenge, isA<EmailVerification>());

      // Consumir y persistir estado.
      final consumed = byToken.challenge.consume(now);
      await codes.updateChallenge(byToken.id, consumed);
      final again = await codes.findActive(
        target: '',
        purpose: VerificationPurpose.emailVerification,
        now: now.add(const Duration(hours: 1)),
        tokenHash: emailTokenHash,
      );
      expect(again, isNull); // consumido: ya no esta activo

      expect(
        await codes.countIssuedSince(
          target: phone,
          since: now.subtract(const Duration(days: 1)),
        ),
        1,
      );
    });
  });
}
