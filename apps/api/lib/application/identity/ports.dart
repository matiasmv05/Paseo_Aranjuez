import 'package:paseo_api/domain/identity/identity.dart';

/// Registro persistido de un codigo de verificacion (OTP o token de correo).
/// **Nunca** guarda el valor en claro (FR-004).
final class VerificationCodeRecord {
  const VerificationCodeRecord({
    required this.id,
    required this.target,
    required this.purpose,
    required this.codeHash,
    required this.challenge,
  });

  final String id;

  /// Telefono E.164 (OTP) o correo (verificacion de correo).
  final String target;
  final VerificationPurpose purpose;
  final String codeHash;
  final VerificationState challenge;
}

enum VerificationPurpose { phoneVerification, emailVerification }

/// Registro persistido de un token de recuperacion (FR-008): hash del
/// token, 30 min, un solo uso.
final class PasswordResetRecord {
  const PasswordResetRecord({
    required this.id,
    required this.userId,
    required this.expiresAt,
    this.usedAt,
  });

  final String id;
  final String userId;
  final DateTime expiresAt;
  final DateTime? usedAt;

  bool isUsable(DateTime now) => usedAt == null && now.isBefore(expiresAt);
}

/// Resultado de emitir un par access + refresh para una sesion.
final class IssuedSession {
  const IssuedSession({
    required this.accessToken,
    required this.expiresIn,
    required this.refreshToken,
  });

  final String accessToken;

  /// Segundos de vida del access token (<= 900).
  final int expiresIn;

  /// Refresh en claro: va al cuerpo (`paseo-mobile`) o a la cookie web;
  /// en base solo queda su hash.
  final String refreshToken;
}

// -------------------------------------------------------------------
// Puertos de persistencia
// -------------------------------------------------------------------

abstract interface class UserRepository {
  Future<User?> findByEmail(Email email);
  Future<User?> findById(String id);

  /// Crea el usuario; `null` si el correo ya existe (409).
  Future<User?> insertIfAbsent({
    required String id,
    required Email email,
    required String passwordHash,
    required UserRole role,
  });

  /// Incrementa `token_version` (invalida access tokens vivos).
  Future<void> incrementTokenVersion(String userId);

  Future<void> setPassword({
    required String userId,
    required String passwordHash,
  });

  Future<void> markEmailVerified(String userId);
}

abstract interface class CustomerRepository {
  Future<CustomerProfile?> findByUserId(String userId);
  Future<CustomerProfile?> findByPhone(PhoneBO phone);

  /// `null` si el telefono ya existe (409).
  Future<CustomerProfile?> insertIfAbsent(CustomerProfile profile);

  Future<void> markPhoneVerified({
    required String userId,
    required DateTime at,
  });
}

abstract interface class VerificationCodeRepository {
  /// Ultimo codigo vigente para (target, purpose); usado para reenvio.
  /// Con `tokenHash` busca el codigo por su hash (tokens enviados por
  /// correo, donde el cliente no conoce el target).
  Future<VerificationCodeRecord?> findActive({
    required String target,
    required VerificationPurpose purpose,
    required DateTime now,
    String? tokenHash,
  });

  Future<VerificationCodeRecord?> findLatest({
    required String target,
    required VerificationPurpose purpose,
  });

  /// Codigos emitidos hoy para el target (tope diario).
  Future<int> countIssuedSince({
    required String target,
    required DateTime since,
  });

  Future<void> insert({
    required String id,
    required String target,
    required VerificationPurpose purpose,
    required String codeHash,
    required VerificationState challenge,
  });

  Future<void> updateChallenge(String id, VerificationState challenge);
}

abstract interface class PasswordResetRepository {
  Future<PasswordResetRecord?> findByTokenHash(String tokenHash);
  Future<void> insert({
    required String id,
    required String userId,
    required String tokenHash,
    required DateTime expiresAt,
  });

  /// Marca como usado de forma atomica; `false` si ya estaba usado.
  Future<bool> tryMarkUsed({required String id, required DateTime at});
}

abstract interface class RefreshTokenRepository {
  Future<RefreshTokenRecord?> findByTokenHash(String tokenHash);
  Future<void> insert({
    required String id,
    required String familyId,
    required String userId,
    required String audience,
    required String tokenHash,
    required DateTime expiresAt,
  });

  /// Revoca de forma atomica; `false` si ya estaba revocado (reutilizacion
  /// en concurrencia: otro proceso gano la rotacion).
  Future<bool> tryClaimRotation({required String id, required DateTime at});

  /// Revoca toda la familia (deteccion de reutilizacion, reset de
  /// contrasena).
  Future<void> revokeFamily({required String familyId, required DateTime at});

  /// Revoca todos los refresh del usuario (reset de contrasena).
  Future<void> revokeAllForUser({required String userId, required DateTime at});
}

// -------------------------------------------------------------------
// Puertos de servicios
// -------------------------------------------------------------------

/// Escritura de `audit_log` (regla 2.4; FR-011). Sin datos personales.
abstract interface class AuditLogWriter {
  Future<void> write({
    required String action,
    required String entityType,
    String? entityId,
    String? userId,
    String role = 'system',
  });
}

/// Argon2id (PHC) fuera del hilo principal (SEC-001). Tambien se usa para
/// el hash de OTP.
abstract interface class PasswordHasher {
  Future<String> hash(String plain);
  Future<bool> verify({required String hash, required String plain});
}

/// Firma JWT (HS256, `kid`).
abstract interface class TokenSigner {
  String sign(AuthClaims claims);
}

abstract interface class OtpSender {
  Future<void> sendOtp({required PhoneBO phone, required String code});
}

abstract interface class EmailSender {
  Future<void> sendEmailVerification({
    required Email email,
    required String token,
  });

  Future<void> sendPasswordReset({required Email email, required String token});
}

abstract interface class Clock {
  DateTime nowUtc();
}

abstract interface class IdGenerator {
  String newId();
}

/// Tokens aleatorios (API keys criptograficas) y su hash determinista
/// (SHA-256) para persistir.
abstract interface class TokenGenerator {
  /// `length` en bytes (>= 32 para tokens de recuperacion, FR-008).
  String randomToken(int bytes);

  /// OTP numerico de 6 digitos.
  String randomOtp();

  String hashToken(String token);
}

/// Ejecuta un bloque en una transaccion; el adapter fija el contexto RLS
/// (`set_config(..., true)`, rol `system` para identidad).
abstract interface class TransactionRunner {
  Future<T> run<T>(Future<T> Function() body);
}
