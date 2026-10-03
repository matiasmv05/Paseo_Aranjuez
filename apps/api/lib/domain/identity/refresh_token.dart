import 'errors.dart';

/// Refresh token persistido: solo su **hash**, con familia/cadena para
/// deteccion de reutilizacion (FR-007).
final class RefreshTokenRecord {
  const RefreshTokenRecord({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.audience,
    required this.expiresAt,
    this.revokedAt,
  });

  final String id;

  /// Identificador de la cadena (login original).
  final String familyId;
  final String userId;
  final String audience;
  final DateTime expiresAt;
  final DateTime? revokedAt;

  bool get isRevoked => revokedAt != null;

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  RefreshTokenRecord revoked(DateTime at) => RefreshTokenRecord(
    id: id,
    familyId: familyId,
    userId: userId,
    audience: audience,
    expiresAt: expiresAt,
    revokedAt: at,
  );
}

/// Decision de rotacion de un refresh token (deteccion de reutilizacion a
/// nivel de modelo).
enum RotationDecision {
  /// Token vigente y no revocado: rota normalmente.
  ok,

  /// Token ya revocado (rotado antes o por logout): reutilizacion.
  /// La familia completa se revoca.
  reuseDetected,

  /// Token vencido.
  expired,
}

/// Evalua un refresh token presentado contra su registro. La aplicacion
/// reclama la rotacion de forma atomica (`tryClaimRotation`); si el reclamo
/// falla (`false`), otro proceso gano y esto es reutilizacion.
RotationDecision evaluateRotation(RefreshTokenRecord record, DateTime now) {
  if (record.isRevoked) return RotationDecision.reuseDetected;
  if (record.isExpired(now)) return RotationDecision.expired;
  return RotationDecision.ok;
}

/// Traduce la decision al error de dominio correspondiente (o `null` si ok).
IdentityException? rotationError(RotationDecision decision) =>
    switch (decision) {
      RotationDecision.ok => null,
      RotationDecision.reuseDetected => IdentityException.tokenReuseDetected(),
      RotationDecision.expired => IdentityException.tokenInvalid(),
    };
