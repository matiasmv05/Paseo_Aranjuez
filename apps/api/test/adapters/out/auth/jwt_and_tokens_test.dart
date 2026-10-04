import 'dart:convert';

import 'package:paseo_api/adapters/out/auth/jwt_token_signer.dart';
import 'package:paseo_api/adapters/out/clock/system_clock.dart';
import 'package:paseo_api/adapters/out/tokens/crypto_token_generator.dart';
import 'package:paseo_api/adapters/out/tokens/uuid_id_generator.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:test/test.dart';

void main() {
  group('JwtTokenSigner (HS256)', () {
    AuthClaims claims({int tokenVersion = 3}) => AuthClaims(
      issuer: 'paseo-api',
      audience: 'paseo-mobile',
      subject: 'user-1',
      issuedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        1700000900000,
        isUtc: true,
      ),
      jwtId: 'jti-1',
      role: UserRole.customer,
      customerId: 'user-1',
      establishmentId: null,
      branchId: null,
      phoneVerified: true,
      emailVerified: true,
      tokenVersion: tokenVersion,
    );

    test('signs with kid and produces three-part JWT', () {
      const signer = JwtTokenSigner(secret: 'super-secret', kid: 'dev-key-1');

      final token = signer.sign(claims());
      final parts = token.split('.');
      expect(parts.length, 3, reason: 'header.payload.signature');
      final headerJson = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[0])),
      );
      expect(headerJson, contains('"alg":"HS256"'));
      expect(headerJson, contains('"kid":"dev-key-1"'));

      final payloadJson = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      expect(payloadJson, contains('"sub":"user-1"'));
      expect(payloadJson, contains('"aud":"paseo-mobile"'));
      expect(payloadJson, contains('"tv":3'));
    });

    test(
      'two signs of identical payload produce identical tokens (deterministic)',
      () {
        const signer = JwtTokenSigner(secret: 'super-secret', kid: 'dev-key-1');
        expect(
          signer.sign(claims(tokenVersion: 1)),
          equals(signer.sign(claims(tokenVersion: 1))),
        );
      },
    );
  });

  group('CryptoTokenGenerator', () {
    test('randomToken returns base64url of n bytes, deterministic hash via SHA-256', () {
      const gen = CryptoTokenGenerator();
      final t1 = gen.randomToken(32);
      final t2 = gen.randomToken(32);
      expect(t1, isNot(t2));
      expect(base64Url.decode(base64Url.normalize(t1)).length, 32);
      final h = gen.hashToken(t1);
      expect(h.length, 64); // SHA-256 hex
      expect(gen.hashToken(t1), equals(h)); // deterministic
    });

    test('randomOtp returns 6 digits', () {
      const gen = CryptoTokenGenerator();
      for (var i = 0; i < 50; i++) {
        final otp = gen.randomOtp();
        expect(RegExp(r'^[0-9]{6}$').hasMatch(otp), isTrue);
      }
    });
  });

  group('SystemClock & UuidIdGenerator', () {
    test('nowUtc returns UTC', () {
      const clock = SystemClock();
      expect(clock.nowUtc().isUtc, isTrue);
    });
    test('newId returns uuid v4', () {
      const gen = UuidIdGenerator();
      final a = gen.newId();
      final b = gen.newId();
      expect(a, isNot(b));
      expect(RegExp(r'^[0-9a-f-]{36}$').hasMatch(a), isTrue);
    });
  });
}
