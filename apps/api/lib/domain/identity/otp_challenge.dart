import 'errors.dart';

/// Reto OTP de 6 digitos (FR-004): solo hash en base, vigencia 5 min,
/// maximo 5 intentos, reenvio con espera de 60 s.
///
/// La comparacion del codigo la hace la aplicacion (puerto `PasswordHasher`);
/// esta entidad modela el estado: expiracion, consumo y contador de intentos.
final class OtpChallenge {
  const OtpChallenge._({
    required this.createdAt,
    required this.expiresAt,
    required this.attempts,
    required this.consumedAt,
  });

  /// Reconstruye desde persistencia.
  factory OtpChallenge.restore({
    required DateTime createdAt,
    required DateTime expiresAt,
    required int attempts,
    required DateTime? consumedAt,
  }) => OtpChallenge._(
    createdAt: createdAt,
    expiresAt: expiresAt,
    attempts: attempts,
    consumedAt: consumedAt,
  );

  factory OtpChallenge.issue(DateTime now) => OtpChallenge._(
    createdAt: now,
    expiresAt: now.add(ttl),
    attempts: 0,
    consumedAt: null,
  );

  /// Vigencia del codigo (5 minutos).
  static const ttl = Duration(minutes: 5);

  /// Intentos de verificacion permitidos.
  static const maxAttempts = 5;

  /// Espera minima entre envios (reenvio).
  static const resendCooldown = Duration(seconds: 60);

  final DateTime createdAt;
  final DateTime expiresAt;
  final int attempts;
  final DateTime? consumedAt;

  /// `true` en `expiresAt` exacto o despues (borde incluido).
  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  bool get isConsumed => consumedAt != null;

  bool get isExhausted => attempts >= maxAttempts;

  /// `true` si un nuevo envio en `sentAt` respeta el cooldown desde el
  /// ultimo envio (`lastSentAt`).
  static bool canResend(DateTime lastSentAt, DateTime now) =>
      !now.isBefore(lastSentAt.add(resendCooldown));

  /// Verifica el resultado de la comparacion del hash y devuelve el nuevo
  /// estado. Lanza:
  /// - `OTP_TOO_MANY_ATTEMPTS` si ya se agotaron los intentos (5.º fallo
  ///   agota y bloquea).
  /// - `OTP_EXPIRED` si vencio; **no consume intentos** (edge case).
  /// - `OTP_INVALID` si no coincide; incrementa `attempts`.
  OtpChallenge verify(DateTime now, {required bool matches}) {
    if (isExhausted) throw IdentityException.otpTooManyAttempts();
    if (isExpired(now)) throw IdentityException.otpExpired();
    if (!matches) {
      return _copy(attempts: attempts + 1);
    }
    return _copy(consumedAt: now);
  }

  OtpChallenge _copy({int? attempts, DateTime? consumedAt}) => OtpChallenge._(
    createdAt: createdAt,
    expiresAt: expiresAt,
    attempts: attempts ?? this.attempts,
    consumedAt: consumedAt ?? this.consumedAt,
  );
}
