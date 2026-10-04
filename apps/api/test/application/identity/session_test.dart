import 'package:mocktail/mocktail.dart';
import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/application/identity/use_cases/forgot_password.dart';
import 'package:paseo_api/application/identity/use_cases/login.dart';
import 'package:paseo_api/application/identity/use_cases/logout.dart';
import 'package:paseo_api/application/identity/use_cases/refresh_session.dart';
import 'package:paseo_api/application/identity/use_cases/reset_password.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:paseo_shared/paseo_shared.dart';
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  final now = DateTime.utc(2026, 10, 3, 12);

  setUpAll(() {
    registerFallbackValue(Email.parse('fallback@example.com'));
    registerFallbackValue(
      AuthClaims(
        issuer: 'x',
        audience: 'paseo-mobile',
        subject: 'u-0',
        issuedAt: now,
        expiresAt: now,
        jwtId: 'j',
        role: UserRole.customer,
        customerId: null,
        establishmentId: null,
        branchId: null,
        phoneVerified: false,
        emailVerified: false,
        tokenVersion: 0,
      ),
    );
    registerFallbackValue(now);
    registerFallbackValue(UserRole.customer);
  });

  User user({
    String id = 'u-1',
    UserRole role = UserRole.customer,
    int tv = 2,
    bool emailVerified = true,
    UserStatus status = UserStatus.active,
  }) => User(
    id: id,
    email: 'ana@example.com',
    passwordHash: 'phc:secreto123',
    role: role,
    status: status,
    tokenVersion: tv,
    emailVerified: emailVerified,
  );

  late MockUserRepository users;
  late MockCustomerRepository customers;
  late MockRefreshTokenRepository refresh;
  late MockPasswordResetRepository resets;
  late MockAuditLogWriter audit;
  late MockTokenSigner signer;
  late MockEmailSender emailSender;
  late FakeTokenGenerator tokens;
  late Login login;

  setUp(() {
    users = MockUserRepository();
    customers = MockCustomerRepository();
    refresh = MockRefreshTokenRepository();
    resets = MockPasswordResetRepository();
    audit = MockAuditLogWriter();
    signer = MockTokenSigner();
    emailSender = MockEmailSender();
    tokens = FakeTokenGenerator();
    login = Login(
      users: users,
      customers: customers,
      refreshTokens: refresh,
      hasher: FakeHasher(),
      signer: signer,
      tokens: tokens,
      ids: SequentialIds(),
      clock: FixedClock(now),
      audit: audit,
    );
    when(() => signer.sign(any())).thenReturn('signed.jwt');
    when(
      () => refresh.insert(
        id: any(named: 'id'),
        familyId: any(named: 'familyId'),
        userId: any(named: 'userId'),
        audience: any(named: 'audience'),
        tokenHash: any(named: 'tokenHash'),
        expiresAt: any(named: 'expiresAt'),
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

  group('Login (US3, FR-005/FR-006)', () {
    test(
      'movil: 200 con aud=paseo-mobile y refresh (para el cuerpo)',
      () async {
        when(() => users.findByEmail(any())).thenAnswer((_) async => user());
        when(() => customers.findByUserId(any())).thenAnswer(
          (_) async =>
              const CustomerProfile(userId: 'u-1', phone: '+59170000000'),
        );
        final session = await login.call(
          email: 'ana@example.com',
          password: 'secreto123',
          client: ClientApp.mobile,
        );
        expect(session.accessToken, 'signed.jwt');
        expect(session.expiresIn, lessThanOrEqualTo(900));
        expect(session.refreshToken, isNotEmpty);
        final claims =
            verify(() => signer.sign(captureAny())).captured.single
                as AuthClaims;
        expect(claims.audience, 'paseo-mobile');
        expect(claims.role, UserRole.customer);
        expect(claims.tokenVersion, 2);
        verify(
          () => refresh.insert(
            id: any(named: 'id'),
            familyId: any(named: 'familyId'),
            userId: 'u-1',
            audience: 'paseo-mobile',
            tokenHash: any(named: 'tokenHash'),
            expiresAt: any(named: 'expiresAt'),
          ),
        ).called(1);
      },
    );

    test(
      'web-admin con rol admin -> aud=paseo-web-admin (cookie propia del adapter)',
      () async {
        when(
          () => users.findByEmail(any()),
        ).thenAnswer((_) async => user(role: UserRole.admin));
        final session = await login.call(
          email: 'ana@example.com',
          password: 'secreto123',
          client: ClientApp.webAdmin,
        );
        final claims =
            verify(() => signer.sign(captureAny())).captured.single
                as AuthClaims;
        expect(claims.audience, ClientApp.webAdmin.audience);
        expect(ClientApp.webAdmin.refreshCookieName, '__Secure-rt_admin');
        expect(session.refreshToken, isNotEmpty);
      },
    );

    test('web-admin sin rol admin -> 403 FORBIDDEN', () async {
      when(() => users.findByEmail(any())).thenAnswer((_) async => user());
      await expectLater(
        login.call(
          email: 'ana@example.com',
          password: 'secreto123',
          client: ClientApp.webAdmin,
        ),
        throwsA(
          isA<IdentityException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.forbidden,
          ),
        ),
      );
    });

    test(
      'credenciales invalidas: mismo CREDENTIALS_INVALID exista o no el correo',
      () async {
        when(() => users.findByEmail(any())).thenAnswer((_) async => null);
        await expectLater(
          login.call(
            email: 'nadie@example.com',
            password: 'secreto123',
            client: ClientApp.mobile,
          ),
          throwsA(
            isA<IdentityException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.credentialsInvalid,
            ),
          ),
        );
        when(() => users.findByEmail(any())).thenAnswer((_) async => user());
        await expectLater(
          login.call(
            email: 'ana@example.com',
            password: 'mala-contrasena',
            client: ClientApp.mobile,
          ),
          throwsA(
            isA<IdentityException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.credentialsInvalid,
            ),
          ),
        );
      },
    );
  });

  group('RefreshSession (US4, FR-007)', () {
    late RefreshSession useCase;

    RefreshTokenRecord record({DateTime? revokedAt, DateTime? expiresAt}) =>
        RefreshTokenRecord(
          id: 'rt-1',
          familyId: 'fam-1',
          userId: 'u-1',
          audience: 'paseo-mobile',
          expiresAt: expiresAt ?? now.add(const Duration(days: 30)),
          revokedAt: revokedAt,
        );

    setUp(() {
      useCase = RefreshSession(
        users: users,
        customers: customers,
        refreshTokens: refresh,
        signer: signer,
        tokens: tokens,
        ids: SequentialIds(),
        clock: FixedClock(now),
        login: login,
      );
      when(() => users.findById(any())).thenAnswer((_) async => user());
      when(() => customers.findByUserId(any())).thenAnswer(
        (_) async =>
            const CustomerProfile(userId: 'u-1', phone: '+59170000000'),
      );
      when(
        () => refresh.tryClaimRotation(
          id: any(named: 'id'),
          at: any(named: 'at'),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => refresh.revokeFamily(
          familyId: any(named: 'familyId'),
          at: any(named: 'at'),
        ),
      ).thenAnswer((_) async {});
    });

    test('rotacion: emite tokens nuevos en la misma familia', () async {
      when(
        () => refresh.findByTokenHash('sha:rt-actual'),
      ).thenAnswer((_) async => record());
      final session = await useCase.call(refreshToken: 'rt-actual');
      expect(session.accessToken, 'signed.jwt');
      verify(
        () => refresh.tryClaimRotation(
          id: 'rt-1',
          at: any(named: 'at'),
        ),
      ).called(1);
      // el nuevo refresh hereda la familia
      verify(
        () => refresh.insert(
          id: any(named: 'id'),
          familyId: 'fam-1',
          userId: 'u-1',
          audience: any(named: 'audience'),
          tokenHash: any(named: 'tokenHash'),
          expiresAt: any(named: 'expiresAt'),
        ),
      ).called(1);
      verifyNever(
        () => refresh.revokeFamily(
          familyId: any(named: 'familyId'),
          at: any(named: 'at'),
        ),
      );
    });

    test(
      'reutilizacion del refresh anterior -> TOKEN_REUSE_DETECTED + familia revocada',
      () async {
        when(
          () => refresh.findByTokenHash('sha:rt-viejo'),
        ).thenAnswer((_) async => record(revokedAt: now));
        when(
          () => refresh.tryClaimRotation(
            id: any(named: 'id'),
            at: any(named: 'at'),
          ),
        ).thenAnswer((_) async => false);
        await expectLater(
          useCase.call(refreshToken: 'rt-viejo'),
          throwsA(
            isA<IdentityException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.tokenReuseDetected,
            ),
          ),
        );
        verify(
          () => refresh.revokeFamily(
            familyId: 'fam-1',
            at: any(named: 'at'),
          ),
        ).called(1);
        // no se emite nada
        verifyNever(() => signer.sign(any()));
      },
    );

    test(
      'concurrencia: el reclamo atomico perdido se trata como reutilizacion',
      () async {
        when(
          () => refresh.findByTokenHash('sha:rt-x'),
        ).thenAnswer((_) async => record());
        when(
          () => refresh.tryClaimRotation(
            id: any(named: 'id'),
            at: any(named: 'at'),
          ),
        ).thenAnswer((_) async => false); // otro proceso gano
        await expectLater(
          useCase.call(refreshToken: 'rt-x'),
          throwsA(
            isA<IdentityException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.tokenReuseDetected,
            ),
          ),
        );
        verify(
          () => refresh.revokeFamily(
            familyId: 'fam-1',
            at: any(named: 'at'),
          ),
        ).called(1);
      },
    );

    test('token vencido -> TOKEN_INVALID sin revocar familia', () async {
      when(() => refresh.findByTokenHash('sha:rt-exp')).thenAnswer(
        (_) async =>
            record(expiresAt: now.subtract(const Duration(seconds: 1))),
      );
      await expectLater(
        useCase.call(refreshToken: 'rt-exp'),
        throwsA(
          isA<IdentityException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.tokenInvalid,
          ),
        ),
      );
      verifyNever(
        () => refresh.revokeFamily(
          familyId: any(named: 'familyId'),
          at: any(named: 'at'),
        ),
      );
    });

    test('token desconocido -> TOKEN_INVALID', () async {
      when(() => refresh.findByTokenHash(any())).thenAnswer((_) async => null);
      await expectLater(
        useCase.call(refreshToken: 'fantasma'),
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

  group('Logout (US4)', () {
    test('revoca el refresh actual; token desconocido no falla', () async {
      final useCase = Logout(
        refreshTokens: refresh,
        tokens: tokens,
        clock: FixedClock(now),
        audit: audit,
      );
      when(() => refresh.findByTokenHash('sha:rt-1')).thenAnswer(
        (_) async => RefreshTokenRecord(
          id: 'rt-1',
          familyId: 'fam-1',
          userId: 'u-1',
          audience: 'paseo-mobile',
          expiresAt: now.add(const Duration(days: 30)),
        ),
      );
      when(
        () => refresh.tryClaimRotation(
          id: any(named: 'id'),
          at: any(named: 'at'),
        ),
      ).thenAnswer((_) async => true);
      await useCase.call(refreshToken: 'rt-1');
      verify(() => refresh.tryClaimRotation(id: 'rt-1', at: now)).called(1);

      when(
        () => refresh.findByTokenHash('sha:desconocido'),
      ).thenAnswer((_) async => null);
      await useCase.call(refreshToken: 'desconocido'); // no lanza
    });
  });

  group('ForgotPassword (US5, FR-008): siempre 202', () {
    late ForgotPassword useCase;

    setUp(() {
      useCase = ForgotPassword(
        users: users,
        resets: resets,
        emailSender: emailSender,
        tokens: tokens,
        ids: SequentialIds(),
        clock: FixedClock(now),
        audit: audit,
      );
      when(
        () => resets.insert(
          id: any(named: 'id'),
          userId: any(named: 'userId'),
          tokenHash: any(named: 'tokenHash'),
          expiresAt: any(named: 'expiresAt'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => emailSender.sendPasswordReset(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async {});
    });

    test('correo inexistente -> termina normal, NO envia', () async {
      when(() => users.findByEmail(any())).thenAnswer((_) async => null);
      await useCase.call(email: 'nadie@example.com');
      verifyNever(
        () => emailSender.sendPasswordReset(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      );
    });

    test('correo no verificado -> termina normal, NO envia', () async {
      when(
        () => users.findByEmail(any()),
      ).thenAnswer((_) async => user(emailVerified: false));
      await useCase.call(email: 'ana@example.com');
      verifyNever(
        () => emailSender.sendPasswordReset(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      );
    });

    test('correo verificado -> persiste solo hash y envia token', () async {
      when(() => users.findByEmail(any())).thenAnswer((_) async => user());
      await useCase.call(email: 'ana@example.com');
      final llamada = verify(
        () => resets.insert(
          id: any(named: 'id'),
          userId: 'u-1',
          tokenHash: captureAny(named: 'tokenHash'),
          expiresAt: captureAny(named: 'expiresAt'),
        ),
      ).captured;
      expect(llamada[0] as String, startsWith('sha:')); // solo hash
      expect(
        (llamada[1] as DateTime).difference(now),
        const Duration(minutes: 30),
      );
      verify(
        () => emailSender.sendPasswordReset(
          email: Email.parse('ana@example.com'),
          token: any(named: 'token'),
        ),
      ).called(1);
    });
  });

  group('ResetPassword (US5, FR-008)', () {
    late ResetPassword useCase;

    setUp(() {
      useCase = ResetPassword(
        users: users,
        resets: resets,
        refreshTokens: refresh,
        hasher: FakeHasher(),
        tokens: tokens,
        clock: FixedClock(now),
        audit: audit,
        tx: PassThroughTx(),
      );
      when(
        () => users.setPassword(
          userId: any(named: 'userId'),
          passwordHash: any(named: 'passwordHash'),
        ),
      ).thenAnswer((_) async {});
      when(() => users.incrementTokenVersion(any())).thenAnswer((_) async {});
      when(
        () => refresh.revokeAllForUser(
          userId: any(named: 'userId'),
          at: any(named: 'at'),
        ),
      ).thenAnswer((_) async {});
    });

    test(
      'exito -> token_version++, revoca refresh, marca usado, audit',
      () async {
        when(() => resets.findByTokenHash('sha:tok-1')).thenAnswer(
          (_) async => PasswordResetRecord(
            id: 'pr-1',
            userId: 'u-1',
            expiresAt: now.add(const Duration(minutes: 30)),
          ),
        );
        when(
          () => resets.tryMarkUsed(
            id: any(named: 'id'),
            at: any(named: 'at'),
          ),
        ).thenAnswer((_) async => true);
        when(() => users.findById('u-1')).thenAnswer((_) async => user());

        await useCase.call(token: 'tok-1', newPassword: 'nueva-clave-9');

        verify(() => resets.tryMarkUsed(id: 'pr-1', at: now)).called(1);
        verify(() => users.incrementTokenVersion('u-1')).called(1);
        verify(
          () => refresh.revokeAllForUser(userId: 'u-1', at: now),
        ).called(1);
        verify(
          () => audit.write(
            action: 'auth.password.reset',
            entityType: 'user',
            entityId: 'u-1',
            userId: 'u-1',
          ),
        ).called(1);
      },
    );

    test('segundo uso del mismo token -> TOKEN_INVALID', () async {
      when(() => resets.findByTokenHash('sha:tok-1')).thenAnswer(
        (_) async => PasswordResetRecord(
          id: 'pr-1',
          userId: 'u-1',
          expiresAt: now.add(const Duration(minutes: 30)),
          usedAt: now, // ya usado
        ),
      );
      await expectLater(
        useCase.call(token: 'tok-1', newPassword: 'nueva-clave-9'),
        throwsA(
          isA<IdentityException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.tokenInvalid,
          ),
        ),
      );
      verifyNever(() => users.incrementTokenVersion(any()));
    });

    test('vencido o carrera de uso -> TOKEN_INVALID', () async {
      when(() => resets.findByTokenHash('sha:tok-1')).thenAnswer(
        (_) async => PasswordResetRecord(
          id: 'pr-1',
          userId: 'u-1',
          expiresAt: now.subtract(const Duration(minutes: 1)),
        ),
      );
      await expectLater(
        useCase.call(token: 'tok-1', newPassword: 'nueva-clave-9'),
        throwsA(isA<IdentityException>()),
      );
    });

    test(
      'contrasena invalida -> VALIDATION_FAILED antes de tocar nada',
      () async {
        await expectLater(
          useCase.call(token: 'tok-1', newPassword: 'corta'),
          throwsA(
            isA<IdentityException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.validationFailed,
            ),
          ),
        );
        verifyNever(() => resets.findByTokenHash(any()));
      },
    );
  });
}
