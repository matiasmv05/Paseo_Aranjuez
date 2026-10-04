import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:paseo_api/domain/identity/identity.dart';

/// HS256 JWT verifier.
final class JwtTokenVerifier {
  const JwtTokenVerifier({required this.secret, required this.kid});

  final String secret;
  final String kid;

  AuthClaims? verify(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    final headerB64 = parts[0];
    final payloadB64 = parts[1];
    final signatureB64 = parts[2];

    final signingInput = '$headerB64.$payloadB64';
    final mac = Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(signingInput));
    final expectedSignature = base64Url.encode(mac.bytes).replaceAll('=', '');

    if (signatureB64 != expectedSignature) return null;

    try {
      final headerStr = utf8.decode(
        base64Url.decode(base64Url.normalize(headerB64)),
      );
      final header = jsonDecode(headerStr) as Map<String, dynamic>;
      if (header['alg'] != 'HS256' ||
          header['typ'] != 'JWT' ||
          header['kid'] != kid) {
        return null;
      }

      final payloadStr = utf8.decode(
        base64Url.decode(base64Url.normalize(payloadB64)),
      );
      final payload = jsonDecode(payloadStr) as Map<String, dynamic>;

      final exp = payload['exp'] as int;
      if (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 >= exp) {
        return null;
      }

      return AuthClaims(
        issuer: payload['iss'] as String,
        audience: payload['aud'] as String,
        subject: payload['sub'] as String,
        issuedAt: DateTime.fromMillisecondsSinceEpoch(
          (payload['iat'] as int) * 1000,
          isUtc: true,
        ),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          (payload['exp'] as int) * 1000,
          isUtc: true,
        ),
        jwtId: payload['jti'] as String,
        role: _roleFromWire(payload['role'] as String),
        customerId: payload['cid'] as String?,
        establishmentId: payload['est'] as String?,
        branchId: payload['br'] as String?,
        phoneVerified: payload['pv'] as bool,
        emailVerified: payload['ev'] as bool,
        tokenVersion: payload['tv'] as int,
      );
    } catch (_) {
      return null;
    }
  }

  static UserRole _roleFromWire(String role) => switch (role) {
    'customer' => UserRole.customer,
    'merchant_owner' => UserRole.merchantOwner,
    'merchant_cashier' => UserRole.merchantCashier,
    'admin' => UserRole.admin,
    _ => throw FormatException('Invalid role'),
  };
}
