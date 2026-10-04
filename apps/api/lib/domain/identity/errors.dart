import 'package:paseo_shared/paseo_shared.dart';

/// Error de dominio de identidad. El `code` es estable y proviene del
/// contrato (`ApiErrorCode` de `paseo_shared`); los adapters lo mapean a
/// RFC 9457 (AGENTS.md §9). Nunca contiene datos personales en `message`.
final class IdentityException implements Exception {
  const new(this.code, this.message);

  factory validation(String message) =>
      IdentityException(ApiErrorCode.validationFailed, message);
  factory phoneNotSupported() => const IdentityException(
    ApiErrorCode.phoneNotSupported,
    'prefijo no soportado',
  );
  factory conflict(String message) =>
      IdentityException(ApiErrorCode.conflict, message);
  factory otpInvalid() =>
      const IdentityException(ApiErrorCode.otpInvalid, 'codigo incorrecto');
  factory otpExpired() =>
      const IdentityException(ApiErrorCode.otpExpired, 'codigo vencido');
  factory otpTooManyAttempts() => const IdentityException(
    ApiErrorCode.otpTooManyAttempts,
    'demasiados intentos',
  );
  factory otpRateLimited() => const IdentityException(
    ApiErrorCode.otpRateLimited,
    'limite de reenvios alcanzado',
  );
  factory credentialsInvalid() => const IdentityException(
    ApiErrorCode.credentialsInvalid,
    'credenciales invalidas',
  );
  factory forbidden() =>
      const IdentityException(ApiErrorCode.forbidden, 'sin permiso');
  factory tokenInvalid() =>
      const IdentityException(ApiErrorCode.tokenInvalid, 'token invalido');
  factory tokenReuseDetected() => const IdentityException(
    ApiErrorCode.tokenReuseDetected,
    'reutilizacion detectada',
  );

  final ApiErrorCode code;
  final String message;

  @override
  String toString() => 'IdentityException(${code.wire}: $message)';
}
