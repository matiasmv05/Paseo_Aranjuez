import 'package:paseo_api/domain/identity/identity.dart';
import 'package:test/test.dart';

AuthClaims _claims({UserRole role = UserRole.customer}) => AuthClaims(
  issuer: 'paseo-api',
  audience: 'paseo-mobile',
  subject: 'u-1',
  issuedAt: DateTime.utc(2026, 10, 3, 12),
  expiresAt: DateTime.utc(2026, 10, 3, 12, 15),
  jwtId: 'jti-1',
  role: role,
  customerId: role == UserRole.customer ? 'u-1' : null,
  establishmentId: null,
  branchId: null,
  phoneVerified: true,
  emailVerified: false,
  tokenVersion: 3,
);

void main() {
  group('AuthClaims (FR-006, SEC-002)', () {
    test('contiene EXACTAMENTE los claims del contrato, sin PII', () {
      final json = _claims().toJson();
      expect(json.keys.toSet(), {
        'iss',
        'aud',
        'sub',
        'iat',
        'exp',
        'jti',
        'role',
        'cid',
        'pv',
        'ev',
        'tv',
      });
      // Sin datos personales: correo, telefono, nombre.
      for (final pii in ['email', 'mail', 'phone', 'name', 'full_name']) {
        expect(json.keys, isNot(contains(pii)));
      }
      expect(json.values.whereType<String>(), isNot(anyElement(contains('@'))));
    });

    test('exp - iat <= 900 s', () {
      final json = _claims().toJson();
      expect(
        (json['exp']! as int) - (json['iat']! as int),
        lessThanOrEqualTo(900),
      );
      expect(_claims().lifetime, AuthClaims.maxLifetime);
    });

    test(
      'role merchant_cashier se serializa con guion bajo y br aparece si hay sucursal',
      () {
        final json = AuthClaims(
          issuer: 'paseo-api',
          audience: 'paseo-web-merchant',
          subject: 'u-9',
          issuedAt: DateTime.utc(2026),
          expiresAt: DateTime.utc(2026, 1, 1, 0, 15),
          jwtId: 'j',
          role: UserRole.merchantCashier,
          customerId: null,
          establishmentId: 'est-1',
          branchId: 'br-1',
          phoneVerified: false,
          emailVerified: true,
          tokenVersion: 1,
        ).toJson();
        expect(json['role'], 'merchant_cashier');
        expect(json['est'], 'est-1');
        expect(json['br'], 'br-1');
        expect(json.keys, isNot(contains('cid')));
      },
    );
  });
}
