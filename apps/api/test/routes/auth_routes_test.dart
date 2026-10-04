import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paseo_api/adapters/in/auth_use_cases.dart';
import 'package:paseo_api/domain/identity/errors.dart';
import 'package:test/test.dart';

import '../../routes/auth/login.dart' as login_route;
import '../../routes/auth/logout.dart' as logout_route;
import '../../routes/auth/password/forgot.dart' as forgot_route;
import '../../routes/auth/password/reset.dart' as reset_route;
import '../../routes/auth/phone/send-otp.dart' as send_otp;
import '../../routes/auth/phone/verify.dart' as otp_verify;
import '../../routes/auth/verify-email.dart' as verify_email;

class _MockContext extends Mock implements RequestContext;

class _FakeAuthUseCases extends Mock implements AuthUseCases;

RequestContext _ctx(
  String method,
  String path,
  Object? body,
  AuthUseCases useCases, {
  Map<String, String> headers = const {},
}) {
  final ctx = _MockContext();
  when(() => ctx.request).thenReturn(
    Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: {'content-type': 'application/json', ...headers},
      body: body is String ? body : (body == null ? null : jsonEncode(body)),
    ),
  );
  when(() => ctx.read<Future<AuthUseCases>>())
      .thenAnswer((_) async => useCases);
  return ctx;
}

void main() {
  group('POST /auth/phone/verify', () {
    test('200 on valid otp', () async {
      final useCases = _FakeAuthUseCases();
      when(() => useCases.verifyPhoneOtp)
          .thenReturn(({required phone, required code}) async {});
      final res = await otp_verify.onRequest(
        _ctx('POST', '/auth/phone/verify', {
          'phone': '+59160000000',
          'code': '123456',
        }, useCases),
      );
      expect(res.statusCode, HttpStatus.ok);
      final json = jsonDecode(await res.body()) as Map<String, dynamic>;
      expect(json['phone_verified'], isTrue);
    });

    test('422 OTP_INVALID', () async {
      final useCases = _FakeAuthUseCases();
      when(() => useCases.verifyPhoneOtp).thenReturn(
        ({required phone, required code}) async =>
            throw IdentityException.otpInvalid(),
      );
      final res = await otp_verify.onRequest(
        _ctx('POST', '/auth/phone/verify', {
          'phone': '+59160000000',
          'code': '123456',
        }, useCases),
      );
      expect(res.statusCode, HttpStatus.unprocessableEntity);
      expect((jsonDecode(await res.body()) as Map)['code'], 'OTP_INVALID');
    });

    test('422 OTP_EXPIRED', () async {
      final useCases = _FakeAuthUseCases();
      when(() => useCases.verifyPhoneOtp).thenReturn(
        ({required phone, required code}) async =>
            throw IdentityException.otpExpired(),
      );
      final res = await otp_verify.onRequest(
        _ctx('POST', '/auth/phone/verify', {
          'phone': '+59160000000',
          'code': '123456',
        }, useCases),
      );
      expect(res.statusCode, HttpStatus.unprocessableEntity);
      expect((jsonDecode(await res.body()) as Map)['code'], 'OTP_EXPIRED');
    });

    test('422 invalid body', () async {
      final res = await otp_verify.onRequest(
        _ctx('POST', '/auth/phone/verify', null, _FakeAuthUseCases()),
      );
      expect(res.statusCode, HttpStatus.unprocessableEntity);
    });
  });

  group('POST /auth/phone/send-otp', () {
    test('202 always', () async {
      final useCases = _FakeAuthUseCases();
      when(() => useCases.resendPhoneOtp)
          .thenReturn(({required phone}) async {});
      final res = await send_otp.onRequest(
        _ctx('POST', '/auth/phone/send-otp', {
          'phone': '+59160000000',
        }, useCases),
      );
      expect(res.statusCode, HttpStatus.accepted);
    });

    test('429 OTP_RATE_LIMITED', () async {
      final useCases = _FakeAuthUseCases();
      when(() => useCases.resendPhoneOtp).thenReturn(
        ({required phone}) async => throw IdentityException.otpRateLimited(),
      );
      final res = await send_otp.onRequest(
        _ctx('POST', '/auth/phone/send-otp', {
          'phone': '+59160000000',
        }, useCases),
      );
      expect(res.statusCode, HttpStatus.tooManyRequests);
    });
  });

  group('POST /auth/verify-email', () {
    test('204 on success', () async {
      final useCases = _FakeAuthUseCases();
      when(() => useCases.verifyEmail).thenReturn(({required token}) async {});
      final res = await verify_email.onRequest(
        _ctx('POST', '/auth/verify-email', {'token': 'tok'}, useCases),
      );
      expect(res.statusCode, HttpStatus.noContent);
    });

    test('401 TOKEN_INVALID', () async {
      final useCases = _FakeAuthUseCases();
      when(() => useCases.verifyEmail).thenReturn(
        ({required token}) async => throw IdentityException.tokenInvalid(),
      );
      final res = await verify_email.onRequest(
        _ctx('POST', '/auth/verify-email', {'token': 'tok'}, useCases),
      );
      expect(res.statusCode, HttpStatus.unauthorized);
    });
  });

  group('POST /auth/login', () {
    test('401 invalid credentials + CREDENTIALS_INVALID code', () async {
      final useCases = _FakeAuthUseCases();
      when(() => useCases.login).thenReturn(
        ({required email, required password, required client}) async =>
            throw IdentityException.credentialsInvalid(),
      );
      final res = await login_route.onRequest(
        _ctx(
          'POST',
          '/auth/login',
          {'email': 'a@b.com', 'password': 'x'},
          useCases,
          headers: {'x-paseo-client': 'paseo-mobile'},
        ),
      );
      expect(res.statusCode, HttpStatus.unauthorized);
    });

    test('403 when web-admin without admin role', () async {
      final useCases = _FakeAuthUseCases();
      when(() => useCases.login).thenReturn(
        ({required email, required password, required client}) async =>
            throw IdentityException.forbidden(),
      );
      final res = await login_route.onRequest(
        _ctx(
          'POST',
          '/auth/login',
          {'email': 'a@b.com', 'password': 'x'},
          useCases,
          headers: {'x-paseo-client': 'paseo-web-admin'},
        ),
      );
      expect(res.statusCode, HttpStatus.forbidden);
    });

    test('401 missing X-Paseo-Client', () async {
      final res = await login_route.onRequest(
        _ctx('POST', '/auth/login', {
          'email': 'a@b.com',
          'password': 'x',
        }, _FakeAuthUseCases()),
      );
      expect(res.statusCode, HttpStatus.unauthorized);
    });
  });

  group('POST /auth/logout', () {
    test('204 always (idempotent)', () async {
      final useCases = _FakeAuthUseCases();
      when(() => useCases.logout)
          .thenReturn(({required refreshToken}) async {});
      final res = await logout_route.onRequest(
        _ctx('POST', '/auth/logout', {'refresh_token': 't123'}, useCases),
      );
      expect(res.statusCode, HttpStatus.noContent);
    });

    test('422 missing refresh_token', () async {
      final res = await logout_route.onRequest(
        _ctx('POST', '/auth/logout', {'other': 'x'}, _FakeAuthUseCases()),
      );
      expect(res.statusCode, HttpStatus.unprocessableEntity);
    });
  });

  group('POST /auth/password/forgot', () {
    test('202 always (no account disclosure)', () async {
      final useCases = _FakeAuthUseCases();
      when(() => useCases.forgotPassword)
          .thenReturn(({required email}) async {});
      final res = await forgot_route.onRequest(
        _ctx('POST', '/auth/password/forgot', {'email': 'a@b.com'}, useCases),
      );
      expect(res.statusCode, HttpStatus.accepted);
    });
  });

  group('POST /auth/password/reset', () {
    test('204 on success', () async {
      final useCases = _FakeAuthUseCases();
      when(() => useCases.resetPassword)
          .thenReturn(({required token, required newPassword}) async {});
      final res = await reset_route.onRequest(
        _ctx('POST', '/auth/password/reset', {
          'token': 't',
          'new_password': 'newpass123',
        }, useCases),
      );
      expect(res.statusCode, HttpStatus.noContent);
    });

    test('401 TOKEN_INVALID', () async {
      final useCases = _FakeAuthUseCases();
      when(() => useCases.resetPassword).thenReturn(
        ({required token, required newPassword}) async =>
            throw IdentityException.tokenInvalid(),
      );
      final res = await reset_route.onRequest(
        _ctx('POST', '/auth/password/reset', {
          'token': 't',
          'new_password': 'newpass123',
        }, useCases),
      );
      expect(res.statusCode, HttpStatus.unauthorized);
    });
  });
}
