import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';

/// Verificador HS256 de access tokens (regla 8: sin PII en claims).
/// Lanza [IdentityException.unauthenticated] ante firma inválida,
/// formato incorrecto o expiración.
final class JwtTokenVerifier implements TokenVerifier {
  const JwtTokenVerifier({required this.secret, required this.clock});

  final String secret;
  final Clock clock;

  @override
  AuthClaims verify(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw IdentityException.unauthenticated();
    }
    final signingInput = '${parts[0]}.${parts[1]}';
    final mac = Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(signingInput));
    final expected = base64Url.encode(mac.bytes).replaceAll('=', '');
    if (expected != parts[2]) {
      throw IdentityException.unauthenticated();
    }
    final Map<String, Object?> payload;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('payload no JSON');
      }
      payload = decoded;
    } on Object {
      throw IdentityException.unauthenticated();
    }
    final exp = payload['exp'];
    final iat = payload['iat'];
    if (exp is! int || iat is! int) {
      throw IdentityException.unauthenticated();
    }
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      exp * 1000,
      isUtc: true,
    );
    if (!clock.nowUtc().isBefore(expiresAt)) {
      throw IdentityException.unauthenticated();
    }
    final role = switch (payload['role']) {
      'customer' => UserRole.customer,
      'merchant_owner' => UserRole.merchantOwner,
      'merchant_cashier' => UserRole.merchantCashier,
      'admin' => UserRole.admin,
      _ => throw IdentityException.unauthenticated(),
    };
    return AuthClaims(
      issuer: payload['iss'] as String? ?? '',
      audience: payload['aud'] as String? ?? '',
      subject: payload['sub'] as String? ?? '',
      issuedAt: DateTime.fromMillisecondsSinceEpoch(iat * 1000, isUtc: true),
      expiresAt: expiresAt,
      jwtId: payload['jti'] as String? ?? '',
      role: role,
      customerId: payload['cid'] as String?,
      establishmentId: payload['est'] as String?,
      branchId: payload['br'] as String?,
      phoneVerified: payload['pv'] == true,
      emailVerified: payload['ev'] == true,
      tokenVersion: payload['tv'] as int? ?? 0,
    );
  }
}
