import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/application/identity/use_cases/login.dart';
import 'package:paseo_api/domain/identity/identity.dart';

/// US4: refresh rotativo con deteccion de reutilizacion (FR-007).
final class RefreshSession {
  const new({
    required this._users,
    required CustomerRepository customers,
    required this._refreshTokens,
    required this._signer,
    required this._tokens,
    required this._ids,
    required this._clock,
    required this._login,
    this.issuer = 'paseo-api',
  }) : _customers = customers;

  final UserRepository _users;
  final CustomerRepository _customers;
  final RefreshTokenRepository _refreshTokens;
  final TokenSigner _signer;
  final TokenGenerator _tokens;
  final IdGenerator _ids;
  final Clock _clock;
  final Login _login;
  final String issuer;

  /// Rota [refreshToken]. El token anterior queda revocado; su
  /// reutilizacion revoca toda la familia (`TOKEN_REUSE_DETECTED`).
  Future<IssuedSession> call({required String refreshToken}) async {
    final now = _clock.nowUtc();
    final record = await _refreshTokens.findByTokenHash(
      _tokens.hashToken(refreshToken),
    );
    if (record == null) throw IdentityException.tokenInvalid();

    // Reclamo atomico: exactamente un proceso gana la rotacion.
    final claimed = await _refreshTokens.tryClaimRotation(
      id: record.id,
      at: now,
    );
    if (!claimed || record.isRevoked) {
      // Reutilizacion (o carrera perdida): revoca la familia completa.
      await _refreshTokens.revokeFamily(familyId: record.familyId, at: now);
      throw IdentityException.tokenReuseDetected();
    }
    if (record.isExpired(now)) throw IdentityException.tokenInvalid();

    final user = await _users.findById(record.userId);
    if (user == null || user.status != UserStatus.active) {
      throw IdentityException.tokenInvalid();
    }
    CustomerProfile? customer;
    if (user.role == UserRole.customer) {
      customer = await _customers.findByUserId(user.id);
    }

    final claims = AuthClaims(
      issuer: issuer,
      audience: record.audience,
      subject: user.id,
      issuedAt: now,
      expiresAt: now.add(AuthClaims.maxLifetime),
      jwtId: _ids.newId(),
      role: user.role,
      customerId: customer?.userId,
      establishmentId: user.establishmentId,
      branchId: user.branchId,
      phoneVerified: customer?.phoneVerified ?? false,
      emailVerified: user.emailVerified,
      tokenVersion: user.tokenVersion,
    );
    return _login.issueSession(
      user: user,
      audience: record.audience,
      accessToken: _signer.sign(claims),
      issuedAt: claims.issuedAt,
      expiresAt: claims.expiresAt,
      familyId: record.familyId,
    );
  }
}
