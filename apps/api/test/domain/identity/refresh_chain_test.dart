import 'package:paseo_api/domain/identity/identity.dart';
import 'package:paseo_shared/paseo_shared.dart';
import 'package:test/test.dart';

RefreshTokenRecord _token({DateTime? expiresAt, DateTime? revokedAt}) =>
    RefreshTokenRecord(
      id: 'rt-1',
      familyId: 'fam-1',
      userId: 'u-1',
      audience: 'paseo-mobile',
      expiresAt: expiresAt ?? DateTime.utc(2026, 11, 3),
      revokedAt: revokedAt,
    );

void main() {
  final now = DateTime.utc(2026, 10, 3, 12);

  group('RefreshChain / evaluateRotation (FR-007)', () {
    test('token vigente y no revocado -> ok', () {
      expect(evaluateRotation(_token(), now), RotationDecision.ok);
    });

    test('rotacion: el anterior queda revocado en el modelo', () {
      final anterior = _token();
      final rotado = anterior.revoked(now);
      expect(rotado.isRevoked, isTrue);
      expect(evaluateRotation(rotado, now), RotationDecision.reuseDetected);
    });

    test('reutilizacion -> reuseDetected y error TOKEN_REUSE_DETECTED', () {
      final decision = evaluateRotation(_token(revokedAt: now), now);
      expect(decision, RotationDecision.reuseDetected);
      expect(rotationError(decision)!.code, ApiErrorCode.tokenReuseDetected);
    });

    test('vencido (borde exacto) -> expired -> TOKEN_INVALID', () {
      final vencido = _token(expiresAt: now);
      expect(evaluateRotation(vencido, now), RotationDecision.expired);
      expect(
        rotationError(RotationDecision.expired)!.code,
        ApiErrorCode.tokenInvalid,
      );
    });

    test('revocado tiene precedencia sobre vencido (reuso, no expiracion)', () {
      final r = _token(expiresAt: now, revokedAt: now);
      expect(evaluateRotation(r, now), RotationDecision.reuseDetected);
    });

    // Concurrencia a nivel de modelo: dos rotaciones simultaneas sobre el
    // mismo registro; solo una ve el estado "no revocado".
    test('concurrencia: el segundo rotador ve el token revocado (reuso)', () {
      final original = _token();
      // Proceso A rota primero.
      final trasA = original.revoked(now);
      // Proceso B, que tenia una vista vieja, presenta el mismo token.
      expect(evaluateRotation(trasA, now), RotationDecision.reuseDetected);
      expect(evaluateRotation(original, now), RotationDecision.ok);
    });

    test('rotationError(ok) es null', () {
      expect(rotationError(RotationDecision.ok), isNull);
    });
  });
}
