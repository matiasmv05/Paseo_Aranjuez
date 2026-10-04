import 'package:mocktail/mocktail.dart';
import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/application/identity/use_cases/register_customer.dart';
import 'package:paseo_api/application/identity/use_cases/reset_password.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:paseo_shared/paseo_shared.dart';
import 'package:test/test.dart';

import 'fakes.dart';

class InMemoryUsers implements RollbackStore<Object?>, UserRepository {
  Map<String, User> byId = <String, User>{};
  bool failOnSetPassword = false;

  @override
  Object? snapshot() => Map.of(byId);

  @override
  void restore(Object? state) => byId = Map.of(state! as Map<String, User>);

  @override
  Future<User?> findByEmail(Email email) async =>
      byId.values.where((u) => u.email == email.value).firstOrNull;

  @override
  Future<User?> findById(String id) async => byId[id];

  @override
  Future<User?> insertIfAbsent({
    required String id,
    required Email email,
    required String passwordHash,
    required UserRole role,
  }) async {
    if (byId.values.any((u) => u.email == email.value)) return null;
    return byId[id] = User(
      id: id,
      email: email.value,
      passwordHash: passwordHash,
      role: role,
      status: UserStatus.active,
      tokenVersion: 0,
      emailVerified: false,
    );
  }

  @override
  Future<void> incrementTokenVersion(String userId) async {
    final u = byId[userId]!;
    byId[userId] = _copy(u, tokenVersion: u.tokenVersion + 1);
  }

  @override
  Future<void> setPassword({
    required String userId,
    required String passwordHash,
  }) async {
    if (failOnSetPassword) throw StateError('falla simulada de BD');
    byId[userId] = _copy(byId[userId]!, passwordHash: passwordHash);
  }

  @override
  Future<void> markEmailVerified(String userId) async =>
      byId[userId] = _copy(byId[userId]!, emailVerified: true);

  User _copy(
    User u, {
    String? passwordHash,
    int? tokenVersion,
    bool? emailVerified,
  }) => User(
    id: u.id,
    email: u.email,
    passwordHash: passwordHash ?? u.passwordHash,
    role: u.role,
    status: u.status,
    tokenVersion: tokenVersion ?? u.tokenVersion,
    emailVerified: emailVerified ?? u.emailVerified,
  );
}

class InMemoryCustomers implements RollbackStore<Object?>, CustomerRepository {
  Map<String, CustomerProfile> byUserId = <String, CustomerProfile>{};

  @override
  Object? snapshot() => Map.of(byUserId);

  @override
  void restore(Object? state) =>
      byUserId = Map.of(state! as Map<String, CustomerProfile>);

  @override
  Future<CustomerProfile?> findByUserId(String userId) async =>
      byUserId[userId];

  @override
  Future<CustomerProfile?> findByPhone(PhoneBO phone) async =>
      byUserId.values.where((c) => c.phone == phone.value).firstOrNull;

  @override
  Future<CustomerProfile?> insertIfAbsent(CustomerProfile profile) async {
    if (byUserId.values.any((c) => c.phone == profile.phone)) return null;
    return byUserId[profile.userId] = profile;
  }

  @override
  Future<void> markPhoneVerified({
    required String userId,
    required DateTime at,
  }) async => byUserId[userId] = byUserId[userId]!.verifiedPhone(at);
}

class InMemoryResets
    implements RollbackStore<Object?>, PasswordResetRepository {
  Map<String, PasswordResetRecord> byHash = <String, PasswordResetRecord>{};

  @override
  Object? snapshot() => Map.of(byHash);

  @override
  void restore(Object? state) =>
      byHash = Map.of(state! as Map<String, PasswordResetRecord>);

  @override
  Future<PasswordResetRecord?> findByTokenHash(String tokenHash) async =>
      byHash[tokenHash];

  @override
  Future<void> insert({
    required String id,
    required String userId,
    required String tokenHash,
    required DateTime expiresAt,
  }) async => byHash[tokenHash] = PasswordResetRecord(
    id: id,
    userId: userId,
    expiresAt: expiresAt,
  );

  @override
  Future<bool> tryMarkUsed({required String id, required DateTime at}) async {
    final r = byHash.values.where((r) => r.id == id).firstOrNull;
    if (r == null || r.usedAt != null) return false;
    byHash.updateAll(
      (_, v) => v.id == id
          ? PasswordResetRecord(
              id: v.id,
              userId: v.userId,
              expiresAt: v.expiresAt,
              usedAt: at,
            )
          : v,
    );
    return true;
  }

  @override
  Future<int> deleteExpired(DateTime now) async {
    final expired = byHash.keys
        .where((k) => byHash[k]!.expiresAt.isBefore(now))
        .toList();
    for (final k in expired) {
      byHash.remove(k);
    }
    return expired.length;
  }
}

class InMemoryRefreshTokens
    implements RollbackStore<Object?>, RefreshTokenRepository {
  Map<String, RefreshTokenRecord> byHash = <String, RefreshTokenRecord>{};

  @override
  Object? snapshot() => Map.of(byHash);

  @override
  void restore(Object? state) =>
      byHash = Map.of(state! as Map<String, RefreshTokenRecord>);

  @override
  Future<RefreshTokenRecord?> findByTokenHash(String tokenHash) async =>
      byHash[tokenHash];

  @override
  Future<void> insert({
    required String id,
    required String familyId,
    required String userId,
    required String audience,
    required String tokenHash,
    required DateTime expiresAt,
  }) async => byHash[tokenHash] = RefreshTokenRecord(
    id: id,
    familyId: familyId,
    userId: userId,
    audience: audience,
    expiresAt: expiresAt,
  );

  @override
  Future<bool> tryClaimRotation({
    required String id,
    required DateTime at,
  }) async {
    final r = byHash.values.where((r) => r.id == id).firstOrNull;
    if (r == null || r.isRevoked) return false;
    byHash.updateAll((_, v) => v.id == id ? v.revoked(at) : v);
    return true;
  }

  @override
  Future<void> revokeFamily({
    required String familyId,
    required DateTime at,
  }) async =>
      byHash.updateAll((_, v) => v.familyId == familyId ? v.revoked(at) : v);

  @override
  Future<void> revokeAllForUser({
    required String userId,
    required DateTime at,
  }) async =>
      byHash.updateAll((_, v) => v.userId == userId ? v.revoked(at) : v);

  @override
  Future<int> deleteExpired(DateTime now) async {
    final expired = byHash.keys
        .where((k) => byHash[k]!.expiresAt.isBefore(now))
        .toList();
    for (final k in expired) {
      byHash.remove(k);
    }
    return expired.length;
  }
}

void main() {
  final now = DateTime.utc(2026, 10, 3, 12);

  setUpAll(() {
    registerFallbackValue(Email.parse('fallback@example.com'));
    registerFallbackValue(VerificationPurpose.phoneVerification);
    registerFallbackValue(OtpChallenge.issue(now));
    registerFallbackValue(DateTime.utc(2026));
    registerFallbackValue(PhoneBO.parse('+59160000000'));
  });

  group('RegisterCustomer dentro de TransactionRunner (R1)', () {
    late InMemoryUsers users;
    late InMemoryCustomers customers;
    late FakeTransactionRunner tx;
    late MockAuditLogWriter audit;
    late RegisterCustomer useCase;

    setUp(() {
      users = InMemoryUsers();
      customers = InMemoryCustomers();
      tx = FakeTransactionRunner()
        ..register(users)
        ..register(customers);
      audit = MockAuditLogWriter();
      when(
        () => audit.write(
          action: any(named: 'action'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async {});
      final codes = MockVerificationCodeRepository();
      final otpSender = MockOtpSender();
      final emailSender = MockEmailSender();
      when(
        () => codes.insert(
          id: any(named: 'id'),
          target: any(named: 'target'),
          purpose: any(named: 'purpose'),
          codeHash: any(named: 'codeHash'),
          challenge: any(named: 'challenge'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => otpSender.sendOtp(
          phone: any(named: 'phone'),
          code: any(named: 'code'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => emailSender.sendEmailVerification(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async {});
      useCase = RegisterCustomer(
        users: users,
        customers: customers,
        codes: codes,
        hasher: FakeHasher(),
        otpSender: otpSender,
        emailSender: emailSender,
        tokens: FakeTokenGenerator(),
        ids: SequentialIds(),
        clock: FixedClock(now),
        audit: audit,
        tx: tx,
      );
    });

    test('exito: confirma users + customers', () async {
      final id = await useCase.call(
        email: 'ana@example.com',
        phone: '+59170000000',
        password: 'secreto123',
      );
      expect(tx.committed, isTrue);
      expect(users.byId.keys, contains(id));
      expect(customers.byUserId.keys, contains(id));
    });

    test('telefono duplicado: rollback, NO queda users huerfano', () async {
      // Precarga un cliente con ese telefono (de otro usuario).
      await customers.insertIfAbsent(
        const CustomerProfile(userId: 'otro', phone: '+59170000000'),
      );
      await expectLater(
        useCase.call(
          email: 'ana@example.com',
          phone: '+59170000000',
          password: 'secreto123',
        ),
        throwsA(
          isA<IdentityException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.conflict,
          ),
        ),
      );
      expect(tx.rolledBack, isTrue);
      expect(users.byId, isEmpty, reason: 'no debe quedar huerfano');
      // y el reintento con el mismo correo funciona
      final id = await useCase.call(
        email: 'ana@example.com',
        phone: '+59171111111',
        password: 'secreto123',
      );
      expect(users.byId.keys, contains(id));
    });
  });

  group('ResetPassword dentro de TransactionRunner (R1)', () {
    late InMemoryUsers users;
    late InMemoryResets resets;
    late InMemoryRefreshTokens refresh;
    late FakeTransactionRunner tx;
    late MockAuditLogWriter audit;
    late ResetPassword useCase;

    setUp(() {
      users = InMemoryUsers()
        ..byId['u-1'] = const User(
          id: 'u-1',
          email: 'ana@example.com',
          passwordHash: 'phc:vieja-clave',
          role: UserRole.customer,
          status: UserStatus.active,
          tokenVersion: 1,
          emailVerified: true,
        );
      resets = InMemoryResets()
        ..byHash['sha:tok-1'] = PasswordResetRecord(
          id: 'pr-1',
          userId: 'u-1',
          expiresAt: now.add(const Duration(minutes: 30)),
        );
      refresh = InMemoryRefreshTokens()
        ..byHash['sha:rt-1'] = RefreshTokenRecord(
          id: 'rt-1',
          familyId: 'fam-1',
          userId: 'u-1',
          audience: 'paseo-mobile',
          expiresAt: now.add(const Duration(days: 30)),
        );
      tx = FakeTransactionRunner()
        ..register(users)
        ..register(resets)
        ..register(refresh);
      audit = MockAuditLogWriter();
      when(
        () => audit.write(
          action: any(named: 'action'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async {});
      useCase = ResetPassword(
        users: users,
        resets: resets,
        refreshTokens: refresh,
        hasher: FakeHasher(),
        tokens: FakeTokenGenerator(),
        clock: FixedClock(now),
        audit: audit,
        tx: tx,
      );
    });

    test('exito: token usado + token_version++ + refresh revocado', () async {
      await useCase.call(token: 'tok-1', newPassword: 'nueva-clave-9');
      expect(tx.committed, isTrue);
      expect(resets.byHash['sha:tok-1']!.usedAt, isNotNull);
      expect(users.byId['u-1']!.tokenVersion, 2);
      expect(users.byId['u-1']!.passwordHash, 'phc:nueva-clave-9');
      expect(refresh.byHash['sha:rt-1']!.isRevoked, isTrue);
    });

    test(
      'fallo intermedio: rollback total, el token NO queda gastado',
      () async {
        users.failOnSetPassword = true;
        await expectLater(
          useCase.call(token: 'tok-1', newPassword: 'nueva-clave-9'),
          throwsStateError,
        );
        expect(tx.rolledBack, isTrue);
        expect(resets.byHash['sha:tok-1']!.usedAt, isNull);
        expect(users.byId['u-1']!.tokenVersion, 1);
        expect(users.byId['u-1']!.passwordHash, 'phc:vieja-clave');
        expect(refresh.byHash['sha:rt-1']!.isRevoked, isFalse);
      },
    );
  });
}

extension<T> on Iterable<T> {
  T? get firstOrNull => this.isEmpty ? null : first;
}
