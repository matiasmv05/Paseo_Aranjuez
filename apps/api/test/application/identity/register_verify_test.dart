import 'package:mocktail/mocktail.dart';
import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/application/identity/use_cases/register_customer.dart';
import 'package:paseo_api/application/identity/use_cases/resend_phone_otp.dart';
import 'package:paseo_api/application/identity/use_cases/verify_email.dart';
import 'package:paseo_api/application/identity/use_cases/verify_phone_otp.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:paseo_shared/paseo_shared.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  final now = DateTime.utc(2026, 10, 3, 12);

  setUpAll(() {
    registerFallbackValue(Email.parse('fallback@example.com'));
    registerFallbackValue(PhoneBO.parse('+59160000000'));
    registerFallbackValue(
      CustomerProfile(userId: 'u-0', phone: '+59160000000'),
    );
    registerFallbackValue(OtpChallenge.issue(now));
    registerFallbackValue(UserRole.customer);
    registerFallbackValue(VerificationPurpose.phoneVerification);
    registerFallbackValue(now);
  });

  User user({int tv = 0, String id = 'u-1'}) => User(
    id: id,
    email: 'ana@example.com',
    passwordHash: 'phc:secreto123',
    role: UserRole.customer,
    status: UserStatus.active,
    tokenVersion: tv,
    emailVerified: false,
  );

  group('RegisterCustomer (FR-001/FR-002)', () {
    late MockUserRepository users;
    late MockCustomerRepository customers;
    late MockVerificationCodeRepository codes;
    late MockOtpSender otpSender;
    late MockEmailSender emailSender;
    late MockAuditLogWriter audit;
    late FakeTokenGenerator tokens;
    late RegisterCustomer useCase;

    setUp(() {
      users = MockUserRepository();
      customers = MockCustomerRepository();
      codes = MockVerificationCodeRepository();
      otpSender = MockOtpSender();
      emailSender = MockEmailSender();
      audit = MockAuditLogWriter();
      tokens = FakeTokenGenerator();
      useCase = RegisterCustomer(
        users: users,
        customers: customers,
        codes: codes,
        hasher: FakeHasher(),
        otpSender: otpSender,
        emailSender: emailSender,
        tokens: tokens,
        ids: SequentialIds(),
        clock: FixedClock(now),
        audit: audit,
        tx: PassThroughTx(),
      );
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
      when(
        () => audit.write(
          action: any(named: 'action'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async {});
    });

    test(
      'crea con pv=false y dispara OtpSender + EmailSender + audit',
      () async {
        when(
          () => users.insertIfAbsent(
            id: any(named: 'id'),
            email: any(named: 'email'),
            passwordHash: any(named: 'passwordHash'),
            role: any(named: 'role'),
          ),
        ).thenAnswer((_) async => user());
        when(
          () => customers.insertIfAbsent(any()),
        ).thenAnswer((i) async => i.positionalArguments[0] as CustomerProfile);

        final id = await useCase.call(
          email: 'Ana@Example.com',
          phone: '+59170000000',
          password: 'secreto123',
          fullName: 'Ana',
        );

        expect(id, isNotEmpty);
        // OTP enviado con el hash (nunca en claro) persistido.
        final insertados = verify(
          () => codes.insert(
            id: any(named: 'id'),
            target: any(named: 'target'),
            purpose: any(named: 'purpose'),
            codeHash: any(named: 'codeHash'),
            challenge: any(named: 'challenge'),
          ),
        );
        insertados.called(2);
        verify(
          () => otpSender.sendOtp(
            phone: PhoneBO.parse('+59170000000'),
            code: '123456',
          ),
        ).called(1);
        verify(
          () => emailSender.sendEmailVerification(
            email: any(named: 'email'),
            token: any(named: 'token'),
          ),
        ).called(1);
        verify(
          () => audit.write(
            action: 'auth.register',
            entityType: any(named: 'entityType'),
            entityId: any(named: 'entityId'),
            userId: any(named: 'userId'),
          ),
        ).called(1);
        // pv=false: el perfil insertado no tiene phoneVerifiedAt.
        final perfil =
            verify(() => customers.insertIfAbsent(captureAny())).captured.single
                as CustomerProfile;
        expect(perfil.phoneVerified, isFalse);
      },
    );

    test('prefijo no boliviano -> PHONE_NOT_SUPPORTED', () async {
      expect(
        () => useCase.call(
          email: 'a@b.com',
          phone: '+34600000000',
          password: 'secreto123',
        ),
        throwsA(
          isA<IdentityException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.phoneNotSupported,
          ),
        ),
      );
      verifyNever(
        () => otpSender.sendOtp(
          phone: any(named: 'phone'),
          code: any(named: 'code'),
        ),
      );
    });

    test('correo duplicado -> 409 CONFLICT', () async {
      when(
        () => users.insertIfAbsent(
          id: any(named: 'id'),
          email: any(named: 'email'),
          passwordHash: any(named: 'passwordHash'),
          role: any(named: 'role'),
        ),
      ).thenAnswer((_) async => null);
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
    });

    test('telefono duplicado -> 409 CONFLICT', () async {
      when(
        () => users.insertIfAbsent(
          id: any(named: 'id'),
          email: any(named: 'email'),
          passwordHash: any(named: 'passwordHash'),
          role: any(named: 'role'),
        ),
      ).thenAnswer((_) async => user());
      when(() => customers.insertIfAbsent(any())).thenAnswer((_) async => null);
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
    });
  });

  group('VerifyPhoneOtp', () {
    late MockCustomerRepository customers;
    late MockVerificationCodeRepository codes;
    late MockAuditLogWriter audit;
    late VerifyPhoneOtp useCase;

    VerificationCodeRecord record({DateTime? expiresAt, int attempts = 0}) =>
        VerificationCodeRecord(
          id: 'vc-1',
          target: '+59170000000',
          purpose: VerificationPurpose.phoneVerification,
          codeHash: FakeHasher().hashSyncFake('123456'),
          challenge: OtpChallenge.restore(
            createdAt: now,
            expiresAt: expiresAt ?? now.add(const Duration(minutes: 5)),
            attempts: attempts,
            consumedAt: null,
          ),
        );

    setUp(() {
      customers = MockCustomerRepository();
      codes = MockVerificationCodeRepository();
      audit = MockAuditLogWriter();
      useCase = VerifyPhoneOtp(
        customers: customers,
        codes: codes,
        hasher: FakeHasher(),
        clock: FixedClock(now),
        audit: audit,
      );
      when(() => codes.updateChallenge(any(), any())).thenAnswer((_) async {});
      when(
        () => customers.markPhoneVerified(
          userId: any(named: 'userId'),
          at: any(named: 'at'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => audit.write(
          action: any(named: 'action'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async {});
    });

    test('exito -> pv=true en base + audit', () async {
      when(
        () => codes.findActive(
          target: any(named: 'target'),
          purpose: any(named: 'purpose'),
          now: any(named: 'now'),
        ),
      ).thenAnswer((_) async => record());
      when(() => customers.findByPhone(any())).thenAnswer(
        (_) async => CustomerProfile(userId: 'u-1', phone: '+59170000000'),
      );

      await useCase.call(phone: '+59170000000', code: '123456');

      verify(
        () => customers.markPhoneVerified(userId: 'u-1', at: now),
      ).called(1);
      verify(
        () => audit.write(
          action: 'auth.phone.verify',
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          userId: any(named: 'userId'),
        ),
      ).called(1);
    });

    test('codigo incorrecto -> OTP_INVALID e incrementa intentos', () async {
      when(
        () => codes.findActive(
          target: any(named: 'target'),
          purpose: any(named: 'purpose'),
          now: any(named: 'now'),
        ),
      ).thenAnswer((_) async => record());

      await expectLater(
        useCase.call(phone: '+59170000000', code: '000000'),
        throwsA(
          isA<IdentityException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.otpInvalid,
          ),
        ),
      );
      final updated =
          verify(
                () => codes.updateChallenge('vc-1', captureAny()),
              ).captured.single
              as OtpChallenge;
      expect(updated.attempts, 1);
      verifyNever(
        () => customers.markPhoneVerified(
          userId: any(named: 'userId'),
          at: any(named: 'at'),
        ),
      );
    });

    test('sin codigo activo -> OTP_INVALID (no revela)', () async {
      when(
        () => codes.findActive(
          target: any(named: 'target'),
          purpose: any(named: 'purpose'),
          now: any(named: 'now'),
        ),
      ).thenAnswer((_) async => null);
      await expectLater(
        useCase.call(phone: '+59170000000', code: '123456'),
        throwsA(
          isA<IdentityException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.otpInvalid,
          ),
        ),
      );
    });
  });

  group('ResendPhoneOtp (cooldown 60 s y tope diario)', () {
    late MockCustomerRepository customers;
    late MockVerificationCodeRepository codes;
    late MockOtpSender otpSender;
    late MockAuditLogWriter audit;
    late ResendPhoneOtp useCase;

    setUp(() {
      customers = MockCustomerRepository();
      codes = MockVerificationCodeRepository();
      otpSender = MockOtpSender();
      audit = MockAuditLogWriter();
      useCase = ResendPhoneOtp(
        codes: codes,
        customers: customers,
        hasher: FakeHasher(),
        otpSender: otpSender,
        tokens: FakeTokenGenerator(),
        ids: SequentialIds(),
        clock: FixedClock(now),
        audit: audit,
      );
      when(() => customers.findByPhone(any())).thenAnswer(
        (_) async =>
            const CustomerProfile(userId: 'u-1', phone: '+59170000000'),
      );
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
        () => audit.write(
          action: any(named: 'action'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async {});
    });

    test('reenvio antes de 60 s -> OTP_RATE_LIMITED', () async {
      when(
        () => codes.findLatest(
          target: any(named: 'target'),
          purpose: any(named: 'purpose'),
        ),
      ).thenAnswer(
        (_) async => VerificationCodeRecord(
          id: 'vc-1',
          target: '+59170000000',
          purpose: VerificationPurpose.phoneVerification,
          codeHash: 'x',
          challenge: OtpChallenge.restore(
            createdAt: now.subtract(const Duration(seconds: 30)),
            expiresAt: now.add(const Duration(minutes: 4, seconds: 30)),
            attempts: 0,
            consumedAt: null,
          ),
        ),
      );
      await expectLater(
        useCase.call(phone: '+59170000000'),
        throwsA(
          isA<IdentityException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.otpRateLimited,
          ),
        ),
      );
      verifyNever(
        () => otpSender.sendOtp(
          phone: any(named: 'phone'),
          code: any(named: 'code'),
        ),
      );
    });

    test('tope diario -> OTP_RATE_LIMITED', () async {
      when(
        () => codes.findLatest(
          target: any(named: 'target'),
          purpose: any(named: 'purpose'),
        ),
      ).thenAnswer((_) async => null);
      when(
        () => codes.countIssuedSince(
          target: any(named: 'target'),
          since: any(named: 'since'),
        ),
      ).thenAnswer((_) async => 10);
      await expectLater(
        useCase.call(phone: '+59170000000'),
        throwsA(
          isA<IdentityException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.otpRateLimited,
          ),
        ),
      );
    });

    test('tras 60 s y bajo el tope -> reenvia y audita', () async {
      when(
        () => codes.findLatest(
          target: any(named: 'target'),
          purpose: any(named: 'purpose'),
        ),
      ).thenAnswer(
        (_) async => VerificationCodeRecord(
          id: 'vc-1',
          target: '+59170000000',
          purpose: VerificationPurpose.phoneVerification,
          codeHash: 'x',
          challenge: OtpChallenge.restore(
            createdAt: now.subtract(const Duration(seconds: 60)),
            expiresAt: now.add(const Duration(minutes: 4)),
            attempts: 0,
            consumedAt: null,
          ),
        ),
      );
      when(
        () => codes.countIssuedSince(
          target: any(named: 'target'),
          since: any(named: 'since'),
        ),
      ).thenAnswer((_) async => 3);
      await useCase.call(phone: '+59170000000');
      verify(
        () => otpSender.sendOtp(
          phone: any(named: 'phone'),
          code: any(named: 'code'),
        ),
      ).called(1);
    });
  });

  group('VerifyEmail', () {
    late MockUserRepository users;
    late MockVerificationCodeRepository codes;
    late MockAuditLogWriter audit;
    late VerifyEmail useCase;

    setUp(() {
      users = MockUserRepository();
      codes = MockVerificationCodeRepository();
      audit = MockAuditLogWriter();
      useCase = VerifyEmail(
        users: users,
        codes: codes,
        tokens: FakeTokenGenerator(),
        clock: FixedClock(now),
        audit: audit,
      );
      when(() => codes.updateChallenge(any(), any())).thenAnswer((_) async {});
      when(() => users.markEmailVerified(any())).thenAnswer((_) async {});
      when(
        () => audit.write(
          action: any(named: 'action'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async {});
    });

    test('token valido -> correo verificado', () async {
      when(
        () => codes.findActive(
          target: any(named: 'target'),
          purpose: any(named: 'purpose'),
          now: any(named: 'now'),
          tokenHash: any(named: 'tokenHash'),
        ),
      ).thenAnswer(
        (_) async => VerificationCodeRecord(
          id: 'vc-9',
          target: 'ana@example.com',
          purpose: VerificationPurpose.emailVerification,
          codeHash: 'sha:tok-1',
          challenge: EmailVerification.restore(
            createdAt: now,
            expiresAt: now.add(const Duration(hours: 24)),
            consumedAt: null,
          ),
        ),
      );
      when(() => users.findByEmail(any())).thenAnswer((_) async => user());

      await useCase.call(token: 'tok-1');
      verify(() => users.markEmailVerified('u-1')).called(1);
    });

    test('token usado -> TOKEN_INVALID y no re-verifica', () async {
      when(
        () => codes.findActive(
          target: any(named: 'target'),
          purpose: any(named: 'purpose'),
          now: any(named: 'now'),
          tokenHash: any(named: 'tokenHash'),
        ),
      ).thenAnswer(
        (_) async => VerificationCodeRecord(
          id: 'vc-9',
          target: 'ana@example.com',
          purpose: VerificationPurpose.emailVerification,
          codeHash: 'sha:tok-1',
          challenge: EmailVerification.restore(
            createdAt: now.subtract(const Duration(hours: 1)),
            expiresAt: now.add(const Duration(hours: 23)),
            consumedAt: now.subtract(const Duration(minutes: 30)),
          ),
        ),
      );
      await expectLater(
        useCase.call(token: 'tok-1'),
        throwsA(
          isA<IdentityException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.tokenInvalid,
          ),
        ),
      );
      verifyNever(() => users.markEmailVerified(any()));
    });

    test(
      'un OtpChallenge no sirve para verify-email -> TOKEN_INVALID',
      () async {
        when(
          () => codes.findActive(
            target: any(named: 'target'),
            purpose: any(named: 'purpose'),
            now: any(named: 'now'),
            tokenHash: any(named: 'tokenHash'),
          ),
        ).thenAnswer(
          (_) async => VerificationCodeRecord(
            id: 'vc-1',
            target: 'ana@example.com',
            purpose: VerificationPurpose.emailVerification,
            codeHash: 'x',
            challenge: OtpChallenge.restore(
              createdAt: now,
              expiresAt: now.add(const Duration(minutes: 5)),
              attempts: 0,
              consumedAt: null,
            ),
          ),
        );
        await expectLater(
          useCase.call(token: 'tok-1'),
          throwsA(
            isA<IdentityException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.tokenInvalid,
            ),
          ),
        );
      },
    );

    test('token desconocido/vencido/usado -> TOKEN_INVALID', () async {
      when(
        () => codes.findActive(
          target: any(named: 'target'),
          purpose: any(named: 'purpose'),
          now: any(named: 'now'),
          tokenHash: any(named: 'tokenHash'),
        ),
      ).thenAnswer((_) async => null);
      await expectLater(
        useCase.call(token: 'nope'),
        throwsA(
          isA<IdentityException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.tokenInvalid,
          ),
        ),
      );
    });
  });
}

extension on FakeHasher {
  String hashSyncFake(String s) => 'phc:$s';
}
