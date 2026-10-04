/// Roles de actores del sistema (AGENTS.md §6).
enum UserRole { customer, merchantOwner, merchantCashier, admin }

/// Estado de la cuenta.
enum UserStatus { active, blocked }

/// Identidad de un actor (entidad). Sin telefono: el telefono del cliente
/// vive en [CustomerProfile].
final class User {
  const User({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.status,
    required this.tokenVersion,
    required this.emailVerified,
    this.phoneVerified = false,
    this.establishmentId,
    this.branchId,
  });

  final String id;

  /// Correo normalizado (minusculas). Nunca viaja al JWT.
  final String email;

  /// Hash Argon2id en formato PHC.
  final String passwordHash;
  final UserRole role;
  final UserStatus status;

  /// Version de tokens; se incrementa en cambios sensibles (reset de
  /// contrasena) para invalidar tokens vivos (claim `tv`).
  final int tokenVersion;
  final bool emailVerified;

  /// `users.phone_verified`: con `false` no hay QR ni acumulacion (FR-004).
  final bool phoneVerified;

  /// Solo comercios (`est`); `null` en customer y admin.
  final String? establishmentId;

  /// Solo cajero (`br`); sucursal fija (AGENTS.md §10.1).
  final String? branchId;
}

/// Perfil del cliente (entidad). `fullName` nunca viaja al JWT (SEC-002).
final class CustomerProfile {
  const CustomerProfile({
    required this.userId,
    required this.phone,
    this.fullName,
    this.phoneVerifiedAt,
  });

  final String userId;

  /// E.164 (`+591...`); unico.
  final String phone;
  final String? fullName;

  /// `null` mientras `pv=false`.
  final DateTime? phoneVerifiedAt;

  bool get phoneVerified => phoneVerifiedAt != null;

  CustomerProfile verifiedPhone(DateTime at) => CustomerProfile(
    userId: userId,
    phone: phone,
    fullName: fullName,
    phoneVerifiedAt: at,
  );
}
