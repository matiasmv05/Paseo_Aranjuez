import 'package:paseo_api/application/identity/ports.dart';

/// US4: logout (FR-007). Revoca el refresh actual; idempotente frente a
/// tokens desconocidos (204 igual: no revela nada).
final class Logout {
  const Logout({
    required RefreshTokenRepository refreshTokens,
    required TokenGenerator tokens,
    required Clock clock,
    required AuditLogWriter audit,
  }) : _refreshTokens = refreshTokens,
       _tokens = tokens,
       _clock = clock,
       _audit = audit;

  final RefreshTokenRepository _refreshTokens;
  final TokenGenerator _tokens;
  final Clock _clock;
  final AuditLogWriter _audit;

  Future<void> call({required String refreshToken}) async {
    final record = await _refreshTokens.findByTokenHash(
      _tokens.hashToken(refreshToken),
    );
    if (record == null) return;
    final now = _clock.nowUtc();
    await _refreshTokens.tryClaimRotation(id: record.id, at: now);
    await _audit.write(
      action: 'auth.logout',
      entityType: 'user',
      entityId: record.userId,
      userId: record.userId,
    );
  }
}
