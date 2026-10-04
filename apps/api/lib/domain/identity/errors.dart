import 'package:paseo_shared/paseo_shared.dart';

/// Error de dominio de identidad. El `code` es estable y proviene del
/// contrato (`ApiErrorCode` de `paseo_shared`); los adapters lo mapean a
/// RFC 9457 (AGENTS.md §9). Nunca contiene datos personales en `message`.
final class IdentityException implements Exception {
  const IdentityException(this.code, this.message);

  factory IdentityException.validation(String message) =>
      IdentityException(ApiErrorCode.validationFailed, message);
  factory IdentityException.phoneNotSupported() => const IdentityException(
    ApiErrorCode.phoneNotSupported,
    'prefijo no soportado',
  );
  factory IdentityException.conflict(String message) =>
      IdentityException(ApiErrorCode.conflict, message);
  factory IdentityException.otpInvalid() =>
      const IdentityException(ApiErrorCode.otpInvalid, 'codigo incorrecto');
  factory IdentityException.otpExpired() =>
      const IdentityException(ApiErrorCode.otpExpired, 'codigo vencido');
  factory IdentityException.otpTooManyAttempts() => const IdentityException(
    ApiErrorCode.otpTooManyAttempts,
    'demasiados intentos',
  );
  factory IdentityException.otpRateLimited() => const IdentityException(
    ApiErrorCode.otpRateLimited,
    'limite de reenvios alcanzado',
  );
  factory IdentityException.credentialsInvalid() => const IdentityException(
    ApiErrorCode.credentialsInvalid,
    'credenciales invalidas',
  );
  factory IdentityException.forbidden() =>
      const IdentityException(ApiErrorCode.forbidden, 'sin permiso');
  factory IdentityException.tokenInvalid() =>
      const IdentityException(ApiErrorCode.tokenInvalid, 'token invalido');
  factory IdentityException.unauthenticated() => const IdentityException(
    ApiErrorCode.unauthenticated,
    'falta autenticacion',
  );
  factory IdentityException.tokenReuseDetected() => const IdentityException(
    ApiErrorCode.tokenReuseDetected,
    'reutilizacion detectada',
  );

  final ApiErrorCode code;
  final String message;

  @override
  String toString() => 'IdentityException(${code.wire}: $message)';
}
