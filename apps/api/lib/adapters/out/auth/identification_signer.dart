import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/domain/loyalty/identification.dart';

/// Firma y verifica ticket de identificacion y token QR con HMAC-SHA256
/// (research.md seccion 7, SEC-005).
///
/// El sobre es `base64url(payload).base64url(hmac)`, sin padding, donde el
/// payload es el JSON compacto de [IdentificationTicketClaims] o
/// [QrTokenClaims]. Se usa [secret] (`IDENTIFICATION_SECRET`, independiente
/// de `JWT_SECRET`) y la misma primitiva que `JwtTokenSigner`. El tipo de
/// token viaja en `kind`, asi que un QR no puede pasar por ticket.
///
/// La verificacion es determinista y sin estado: recibe el instante `now`
/// para que los TTL (300 s ticket, 60 s QR) se prueben con un reloj falso.
final class IdentificationSigner implements TicketSigner {
  const IdentificationSigner({required this.secret});

  /// Secreto compartido con el emisor de QR (Persona 1).
  final String secret;

  @override
  String signTicket(IdentificationTicketClaims claims) =>
      _sign(claims.toJson());

  @override
  IdentificationTicketClaims? verifyTicket(
    String token, {
    required DateTime now,
  }) {
    final payload = _verify(token, now: now);
    if (payload == null) {
      return null;
    }
    return IdentificationTicketClaims.fromJson(payload);
  }

  @override
  String signQr(QrTokenClaims claims) => _sign(claims.toJson());

  @override
  QrTokenClaims? verifyQr(String token, {required DateTime now}) {
    final payload = _verify(token, now: now);
    if (payload == null) {
      return null;
    }
    return QrTokenClaims.fromJson(payload);
  }

  String _sign(Map<String, Object?> payload) {
    final body = _encode(utf8.encode(jsonEncode(payload)));
    final signature = _encode(_mac(body));
    return '$body.$signature';
  }

  Map<String, Object?>? _verify(String token, {required DateTime now}) {
    final separator = token.indexOf('.');
    if (separator <= 0 || separator == token.length - 1) {
      return null;
    }
    final body = token.substring(0, separator);
    final signature = token.substring(separator + 1);
    if (body.contains('.') ||
        !_constantTimeEquals(_encode(_mac(body)), signature)) {
      return null;
    }
    final Map<String, Object?> payload;
    try {
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(body))),
      );
      if (decoded is! Map) {
        return null;
      }
      payload = decoded.cast<String, Object?>();
    } on FormatException {
      return null;
    }
    final expiresAt = _expiresAt(payload);
    if (expiresAt == null || !now.toUtc().isBefore(expiresAt)) {
      return null;
    }
    return payload;
  }

  DateTime? _expiresAt(Map<String, Object?> payload) {
    final exp = payload['exp'];
    final iat = payload['iat'];
    if (exp is! int || iat is! int || exp < iat) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
  }

  List<int> _mac(String body) =>
      Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(body)).bytes;

  String _encode(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}

bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) {
    return false;
  }
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}
