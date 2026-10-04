import 'package:paseo_shared/paseo_shared.dart';

/// Error de dominio de puntos. El `code` es estable y proviene del
/// contrato (`ApiErrorCode` de `paseo_shared`); los adapters lo mapean a
/// RFC 9457 (AGENTS.md §9). Nunca contiene datos personales en `message`.
///
/// El mapeo de errores de PostgreSQL (p. ej. `23514` del CHECK de saldo →
/// [PointsException.insufficientPoints], AGENTS.md §9) vive en
/// `adapters/out/postgres/pg_errors.dart`, no en el dominio.
final class PointsException implements Exception {
  const new(this.code, this.message);

  /// Saldo insuficiente para debitar (`CHECK (balance >= 0)` → 23514).
  factory insufficientPoints() => const PointsException(
    ApiErrorCode.insufficientPoints,
    'saldo insuficiente',
  );

  /// Teléfono no verificado (`pv=false`): no acreditar ni canjear
  /// (AGENTS.md §6; SEC-002).
  factory phoneNotVerified() => const PointsException(
    ApiErrorCode.phoneNotVerified,
    'teléfono no verificado',
  );

  /// Conflicto (p. ej. `Idempotency-Key` reutilizada con cuerpo distinto).
  factory conflict(String message) =>
      PointsException(ApiErrorCode.conflict, message);

  final ApiErrorCode code;
  final String message;

  @override
  String toString() => 'PointsException(${code.wire}: $message)';
}
