import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';

/// HS256 JWT signer (SEC-002: sin PII en claims). `kid` del entorno.
/// HMAC-SHA256 sincronico (firma barata; el hash de contrasena pesado ya va en Isolate).
final class JwtTokenSigner implements TokenSigner {
  const new({required this.secret, required this.kid});

  final String secret;
  final String kid;

  @override
  String sign(AuthClaims claims) {
    final header = <String, Object?>{'alg': 'HS256', 'typ': 'JWT', 'kid': kid};
    final signingInput =
        '${_b64(jsonEncode(header))}.${_b64(jsonEncode(claims.toJson()))}';
    final mac = Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(signingInput));
    return '$signingInput.${base64Url.encode(mac.bytes).replaceAll('=', '')}';
  }

  static String _b64(String json) =>
      base64Url.encode(utf8.encode(json)).replaceAll('=', '');
}
