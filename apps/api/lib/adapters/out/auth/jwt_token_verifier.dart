import 'dart:convert';

import 'package:crypto/crypto.dart';
<<<<<<< HEAD
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
=======
import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';

/// Verifica access tokens HS256 emitidos por [JwtTokenSigner] (FR-006, §6).
///
/// Comprueba firma, `alg`, `iss` y `exp`, y reconstruye [AuthClaims]. No
/// consulta la base: la frescura de `status`/`token_version` la valida el
/// middleware contra `app.users` (AGENTS.md §6).
final class JwtTokenVerifier implements TokenVerifier {
  const JwtTokenVerifier({required this.secret, this.issuer = 'paseo-api'});

  final String secret;
  final String issuer;

  @override
  AuthClaims? verify(String token, {required DateTime now}) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final signingInput = '${parts[0]}.${parts[1]}';
    if (!_signatureMatches(signingInput, parts[2])) return null;

    final Map<String, Object?> header;
    final Map<String, Object?> payload;
    try {
      header = _decode(parts[0]);
      payload = _decode(parts[1]);
    } on FormatException {
      return null;
    }
    if (header['alg'] != 'HS256') return null;
    if (payload['iss'] != issuer) return null;

    final role = _role(payload['role']);
    final subject = payload['sub'];
    final audience = payload['aud'];
    final jwtId = payload['jti'];
    final iat = payload['iat'];
    final exp = payload['exp'];
    final pv = payload['pv'];
    final ev = payload['ev'];
    final tv = payload['tv'];
    final cid = payload['cid'];
    final est = payload['est'];
    final br = payload['br'];
    if (role == null ||
        subject is! String ||
        audience is! String ||
        jwtId is! String ||
        iat is! int ||
        exp is! int ||
        pv is! bool ||
        ev is! bool ||
        tv is! int ||
        (cid != null && cid is! String) ||
        (est != null && est is! String) ||
        (br != null && br is! String)) {
      return null;
    }

    final issuedAt = DateTime.fromMillisecondsSinceEpoch(
      iat * 1000,
      isUtc: true,
    );
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      exp * 1000,
      isUtc: true,
    );
    if (!now.toUtc().isBefore(expiresAt)) return null;

    return AuthClaims(
      issuer: issuer,
      audience: audience,
      subject: subject,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      jwtId: jwtId,
      role: role,
      customerId: cid as String?,
      establishmentId: est as String?,
      branchId: br as String?,
      phoneVerified: pv,
      emailVerified: ev,
      tokenVersion: tv,
    );
  }

  bool _signatureMatches(String signingInput, String signature) {
    List<int> provided;
    try {
      final padded = base64Url.normalize(signature);
      provided = base64Url.decode(padded);
    } on FormatException {
      return false;
    }
    final expected = Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(signingInput)).bytes;
    if (provided.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= provided[i] ^ expected[i];
    }
    return diff == 0;
  }

  static Map<String, Object?> _decode(String segment) {
    final bytes = base64Url.decode(base64Url.normalize(segment));
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('segmento no es un objeto JSON');
    }
    return decoded;
  }

  static UserRole? _role(Object? wire) => switch (wire) {
>>>>>>> origin/main
    'customer' => UserRole.customer,
    'merchant_owner' => UserRole.merchantOwner,
    'merchant_cashier' => UserRole.merchantCashier,
    'admin' => UserRole.admin,
<<<<<<< HEAD
    _ => throw FormatException('Invalid role'),
=======
    _ => null,
>>>>>>> origin/main
  };
}
