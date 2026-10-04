import 'package:paseo_api/domain/identity/errors.dart';
import 'package:paseo_api/domain/identity/otp_challenge.dart';

/// Token de verificacion de correo (US2): es un **enlace**, no un OTP.
/// TTL de 24 horas (constante documentada, pendiente de `system_settings`)
/// y sin limite de intentos; un solo uso.
final class EmailVerification implements VerificationState {
  const new _({
    required this.createdAt,
    required this.expiresAt,
    required this.consumedAt,
  });

  factory issue(DateTime now) => EmailVerification._(
    createdAt: now,
    expiresAt: now.add(ttl),
    consumedAt: null,
  );

  /// Reconstruye desde persistencia.
  factory restore({
    required DateTime createdAt,
    required DateTime expiresAt,
    required DateTime? consumedAt,
  }) => EmailVerification._(
    createdAt: createdAt,
    expiresAt: expiresAt,
    consumedAt: consumedAt,
  );

  /// Vigencia del token de correo: 24 horas.
  static const ttl = Duration(hours: 24);

  @override
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? consumedAt;

  /// `true` en `expiresAt` exacto o despues (borde incluido).
  @override
  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  bool get isUsed => consumedAt != null;

  @override
  bool get isConsumed => isUsed;

  /// Consume el token. Lanza `TOKEN_INVALID` si ya se uso o vencio.
  @override
  EmailVerification consume(DateTime now) {
    if (isUsed || isExpired(now)) throw IdentityException.tokenInvalid();
    return EmailVerification._(
      createdAt: createdAt,
      expiresAt: expiresAt,
      consumedAt: now,
    );
  }
}
