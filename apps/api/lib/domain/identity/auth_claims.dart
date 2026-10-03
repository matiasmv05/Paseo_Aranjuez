import 'user.dart';

/// Claims del access token (FR-006, AGENTS.md §6).
///
/// **Exactamente** estos campos; sin datos personales (SEC-002: nada de
/// correo, telefono ni nombre). `sub` es el id de usuario (UUID).
final class AuthClaims {
  const AuthClaims({
    required this.issuer,
    required this.audience,
    required this.subject,
    required this.issuedAt,
    required this.expiresAt,
    required this.jwtId,
    required this.role,
    required this.customerId,
    required this.establishmentId,
    required this.branchId,
    required this.phoneVerified,
    required this.emailVerified,
    required this.tokenVersion,
  });

  /// Vida maxima del access token: 900 s (15 min).
  static const maxLifetime = Duration(minutes: 15);

  final String issuer;
  final String audience;
  final String subject;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String jwtId;
  final UserRole role;
  final String? customerId;
  final String? establishmentId;
  final String? branchId;
  final bool phoneVerified;
  final bool emailVerified;
  final int tokenVersion;

  Duration get lifetime => expiresAt.difference(issuedAt);

  /// Serializa a los claims exactos del contrato. Las claves opcionales
  /// (`cid`, `est`, `br`) solo aparecen si tienen valor; nunca `null`
  /// serializado (el verificador valida presencia por rol).
  Map<String, Object?> toJson() => {
    'iss': issuer,
    'aud': audience,
    'sub': subject,
    'iat': issuedAt.millisecondsSinceEpoch ~/ 1000,
    'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
    'jti': jwtId,
    'role': _roleWire(role),
    if (customerId != null) 'cid': customerId,
    if (establishmentId != null) 'est': establishmentId,
    if (branchId != null) 'br': branchId,
    'pv': phoneVerified,
    'ev': emailVerified,
    'tv': tokenVersion,
  };

  static String _roleWire(UserRole role) => switch (role) {
    UserRole.customer => 'customer',
    UserRole.merchantOwner => 'merchant_owner',
    UserRole.merchantCashier => 'merchant_cashier',
    UserRole.admin => 'admin',
  };
}
