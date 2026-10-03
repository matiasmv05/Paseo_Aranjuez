import 'package:paseo_api/adapters/out/postgres/postgres.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late PgDatabase db;
  late PostgresUserRepository users;
  late PostgresCustomerRepository customers;

  Future<T> runSystem<T>(Future<T> Function() body) =>
      db.runInTransaction(body);

  setUpAll(() async {
    db = await PgDatabase.open(integrationConfig());
    users = PostgresUserRepository(db);
    customers = PostgresCustomerRepository(db);
  });

  tearDownAll(() async {
    await db.close();
  });

  test('registrar user+customer con contexto system los persiste', () async {
    final id = newId();
    final email = uniqueEmail();
    final phone = uniquePhone();

    await runSystem(() async {
      final user = await users.insertIfAbsent(
        id: id,
        email: Email.parse(email),
        passwordHash: r'$argon2id$test',
        role: UserRole.customer,
      );
      expect(user, isNotNull);
      expect(user!.role, UserRole.customer);
      expect(user.status, UserStatus.active);
      expect(user.tokenVersion, 0);
      expect(user.emailVerified, isFalse);

      final profile = await customers.insertIfAbsent(
        CustomerProfile(userId: id, phone: phone, fullName: 'Test Uno'),
      );
      expect(profile, isNotNull);
      expect(profile!.phoneVerified, isFalse);
    });

    await runSystem(() async {
      expect((await users.findByEmail(Email.parse(email)))!.id, id);
      expect((await users.findById(id))!.email, email);
      expect((await customers.findByUserId(id))!.phone, phone);
      expect((await customers.findByPhone(PhoneBO.parse(phone)))!.userId, id);
    });
  });

  test('duplicado de correo y de telefono devuelven null (CONFLICT)', () async {
    final email = uniqueEmail();
    final phone = uniquePhone();
    await runSystem(() async {
      final userA = await users.insertIfAbsent(
        id: newId(),
        email: Email.parse(email),
        passwordHash: r'$argon2id$test',
        role: UserRole.customer,
      );
      final userB = await users.insertIfAbsent(
        id: newId(),
        email: Email.parse(uniqueEmail()),
        passwordHash: r'$argon2id$test',
        role: UserRole.customer,
      );
      await customers.insertIfAbsent(
        CustomerProfile(userId: userA!.id, phone: phone, fullName: 'A'),
      );

      // correo citext: el duplicado en otra caja tambien colisiona.
      final dupEmail = await users.insertIfAbsent(
        id: newId(),
        email: Email.parse(email.toUpperCase()),
        passwordHash: r'$argon2id$test',
        role: UserRole.customer,
      );
      expect(dupEmail, isNull);

      final dupPhone = await customers.insertIfAbsent(
        CustomerProfile(userId: userB!.id, phone: phone, fullName: 'B'),
      );
      expect(dupPhone, isNull);
    });
  });

  test('audit_log: insert posible con system; UPDATE prohibido', () async {
    final audit = PostgresAuditLogWriter(db);
    final id = newId();
    await runSystem(() async {
      await audit.write(
        action: 'auth.register',
        entityType: 'user',
        entityId: id,
        userId: id,
      );
    });

    await expectLater(
      db.connection.execute(
        Sql.named('UPDATE app.audit_log SET action = @a'),
        parameters: {'a': 'x'},
      ),
      throwsA(isA<ServerException>()),
    );
  });

  test('password_resets: tryMarkUsed es atomico (una sola vez)', () async {
    final resets = PostgresPasswordResetRepository(db);
    final id = newId();
    final userId = newId();
    final tokenHash = 'hash-${newId()}';
    await runSystem(() async {
      await users.insertIfAbsent(
        id: userId,
        email: Email.parse(uniqueEmail()),
        passwordHash: r'$argon2id$test',
        role: UserRole.customer,
      );
      await resets.insert(
        id: id,
        userId: userId,
        tokenHash: tokenHash,
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 30)),
      );
    });

    await runSystem(() async {
      final found = await resets.findByTokenHash(tokenHash);
      expect(found!.isUsable(DateTime.now().toUtc()), isTrue);
      final now = DateTime.now().toUtc();
      expect(await resets.tryMarkUsed(id: id, at: now), isTrue);
      expect(await resets.tryMarkUsed(id: id, at: now), isFalse);
      expect((await resets.findByTokenHash(tokenHash))!.usedAt, isNotNull);
    });
  });
}
