import 'package:paseo_api/domain/identity/identity.dart';
import 'package:paseo_shared/paseo_shared.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 10, 3, 12);

  group('OtpChallenge (FR-004)', () {
    test('recien emitido no esta vencido ni agotado', () {
      final c = OtpChallenge.issue(t0);
      expect(c.isExpired(t0), isFalse);
      expect(c.isExhausted, isFalse);
      expect(c.isConsumed, isFalse);
      expect(c.expiresAt, t0.add(const Duration(minutes: 5)));
    });

    test('vence a los 5 min EXACTOS (borde incluido)', () {
      final c = OtpChallenge.issue(t0);
      expect(
        c.isExpired(t0.add(const Duration(minutes: 4, seconds: 59))),
        isFalse,
      );
      expect(c.isExpired(t0.add(const Duration(minutes: 5))), isTrue);
      expect(
        c.isExpired(t0.add(const Duration(minutes: 5, seconds: 1))),
        isTrue,
      );
    });

    test('vencido -> OTP_EXPIRED y NO consume intentos (edge case)', () {
      final c = OtpChallenge.issue(t0);
      final vencido = t0.add(const Duration(minutes: 5));
      expect(
        () => c.verify(vencido, matches: false),
        throwsA(
          isA<IdentityException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.otpExpired,
          ),
        ),
      );
      expect(c.attempts, 0);
    });

    test('intento incorrecto incrementa el contador (OTP_INVALID se mapea en aplicacion)', () {
      final c = OtpChallenge.issue(t0).verify(t0, matches: false);
      expect(c.attempts, 1);
      expect(c.isConsumed, isFalse);
    });

    test(
      'el 5.o intento fallido agota y bloquea: 6.o -> OTP_TOO_MANY_ATTEMPTS',
      () {
        var c = OtpChallenge.issue(t0);
        for (var i = 0; i < 5; i++) {
          c = c.verify(t0, matches: false);
        }
        expect(c.attempts, 5);
        expect(c.isExhausted, isTrue);
        // aun con el codigo correcto ya no se puede
        expect(
          () => c.verify(t0, matches: true),
          throwsA(
            isA<IdentityException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.otpTooManyAttempts,
            ),
          ),
        );
      },
    );

    test('acierto marca consumido', () {
      final c = OtpChallenge.issue(t0).verify(t0, matches: true);
      expect(c.isConsumed, isTrue);
      expect(c.consumedAt, t0);
    });

    test('reenvio: <60 s no permitido, =60 s permitido (borde)', () {
      expect(
        OtpChallenge.canResend(t0, t0.add(const Duration(seconds: 59))),
        isFalse,
      );
      expect(
        OtpChallenge.canResend(t0, t0.add(const Duration(seconds: 60))),
        isTrue,
      );
    });
  });
}
