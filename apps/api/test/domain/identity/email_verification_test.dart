import 'package:paseo_api/domain/identity/identity.dart';
import 'package:paseo_shared/paseo_shared.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 10, 3, 12);

  group('EmailVerification (US2, R1: TTL propio de 24 h)', () {
    test('TTL es 24 horas, no 5 min', () {
      final v = EmailVerification.issue(t0);
      expect(EmailVerification.ttl, const Duration(hours: 24));
      expect(v.expiresAt, t0.add(const Duration(hours: 24)));
      // a los 5 min NO esta vencido (era el bug del OtpChallenge reutilizado)
      expect(v.isExpired(t0.add(const Duration(minutes: 5))), isFalse);
    });

    test('vence a las 24 h EXACTAS (borde incluido)', () {
      final v = EmailVerification.issue(t0);
      expect(
        v.isExpired(t0.add(const Duration(hours: 23, minutes: 59))),
        isFalse,
      );
      expect(v.isExpired(t0.add(const Duration(hours: 24))), isTrue);
    });

    test('consume marca used; segunda vez -> TOKEN_INVALID', () {
      final v = EmailVerification.issue(t0).consume(t0);
      expect(v.isUsed, isTrue);
      expect(
        () => v.consume(t0),
        throwsA(
          isA<IdentityException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.tokenInvalid,
          ),
        ),
      );
    });

    test('vencido -> TOKEN_INVALID al consumir', () {
      final v = EmailVerification.restore(
        createdAt: t0.subtract(const Duration(hours: 25)),
        expiresAt: t0.subtract(const Duration(hours: 1)),
        consumedAt: null,
      );
      expect(
        () => v.consume(t0),
        throwsA(
          isA<IdentityException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.tokenInvalid,
          ),
        ),
      );
    });

    test('sin limite de intentos: no hay contador ni agotamiento', () {
      final v = EmailVerification.issue(t0);
      // es un enlace: consumir en cualquier momento dentro del TTL funciona
      expect(
        v.consume(t0.add(const Duration(hours: 23, minutes: 59))).isUsed,
        isTrue,
      );
    });
  });
}
