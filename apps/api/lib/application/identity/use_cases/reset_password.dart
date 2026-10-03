import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';

/// US5: restablecimiento de contrasena (FR-008).
/// Un solo uso y 30 min; exito = nueva contrasena + `token_version++` +
/// revocacion de todos los refresh tokens de la cuenta.
final class ResetPassword {
  const ResetPassword({
    required UserRepository users,
    required PasswordResetRepository resets,
    required RefreshTokenRepository refreshTokens,
    required PasswordHasher hasher,
    required TokenGenerator tokens,
    required Clock clock,
    required AuditLogWriter audit,
    required TransactionRunner tx,
  }) : _users = users,
       _resets = resets,
       _refreshTokens = refreshTokens,
       _hasher = hasher,
       _tokens = tokens,
       _clock = clock,
       _audit = audit,
       _tx = tx;

  final UserRepository _users;
  final PasswordResetRepository _resets;
  final RefreshTokenRepository _refreshTokens;
  final PasswordHasher _hasher;
  final TokenGenerator _tokens;
  final Clock _clock;
  final AuditLogWriter _audit;
  final TransactionRunner _tx;

  Future<void> call({
    required String token,
    required String newPassword,
  }) async {
    PasswordPolicy.validate(newPassword);
    final now = _clock.nowUtc();
    final record = await _resets.findByTokenHash(_tokens.hashToken(token));
    if (record == null || !record.isUsable(now)) {
      throw IdentityException.tokenInvalid();
    }
    await _tx.run(() async {
      // Un solo uso, atomico: segunda vez -> false -> TOKEN_INVALID.
      final claimed = await _resets.tryMarkUsed(id: record.id, at: now);
      if (!claimed) throw IdentityException.tokenInvalid();

      final user = await _users.findById(record.userId);
      if (user == null) throw IdentityException.tokenInvalid();

      await _users.setPassword(
        userId: user.id,
        passwordHash: await _hasher.hash(newPassword),
      );
      await _users.incrementTokenVersion(user.id);
      await _refreshTokens.revokeAllForUser(userId: user.id, at: now);
      await _audit.write(
        action: 'auth.password.reset',
        entityType: 'user',
        entityId: user.id,
        userId: user.id,
      );
    });
  }
}
