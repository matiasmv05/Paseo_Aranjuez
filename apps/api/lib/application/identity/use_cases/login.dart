import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';

/// US3: login por aplicacion (FR-005, FR-006).
/// Credenciales invalidas: `CREDENTIALS_INVALID` uniforme (exista o no el
/// correo). `paseo-web-admin` solo con `role=admin` -> 403 `FORBIDDEN`.
final class Login {
  const new({
    required this._users,
    required CustomerRepository customers,
    required this._refreshTokens,
    required this._hasher,
    required this._signer,
    required this._tokens,
    required this._ids,
    required this._clock,
    required this._audit,
    this.issuer = 'paseo-api',
    this.refreshLifetime = const Duration(days: 30),
    this.refreshTokenBytes = 32,
  }) : _customers = customers;

  final UserRepository _users;
  final CustomerRepository _customers;
  final RefreshTokenRepository _refreshTokens;
  final PasswordHasher _hasher;
  final TokenSigner _signer;
  final TokenGenerator _tokens;
  final IdGenerator _ids;
  final Clock _clock;
  final AuditLogWriter _audit;
  final String issuer;
  final Duration refreshLifetime;
  final int refreshTokenBytes;

  Future<IssuedSession> call({
    required String email,
    required String password,
    required ClientApp client,
  }) async {
    final user = await _users.findByEmail(Email.parse(email));
    if (user == null || user.status != UserStatus.active) {
      throw IdentityException.credentialsInvalid();
    }
    final ok = await _hasher.verify(hash: user.passwordHash, plain: password);
    if (!ok) throw IdentityException.credentialsInvalid();

    // FR-005: esa audiencia solo existe con rol admin.
    if (client == ClientApp.webAdmin && user.role != UserRole.admin) {
      throw IdentityException.forbidden();
    }

    CustomerProfile? customer;
    if (user.role == UserRole.customer) {
      customer = await _customers.findByUserId(user.id);
    }

    final now = _clock.nowUtc();
    final claims = AuthClaims(
      issuer: issuer,
      audience: client.audience,
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
    return issueSession(
      user: user,
      audience: client.audience,
      accessToken: _signer.sign(claims),
      expiresAt: claims.expiresAt,
      issuedAt: claims.issuedAt,
    );
  }

  /// Emite el refresh (hash en base) y construye la sesion. Compartido con
  /// `RefreshSession`: es el **mismo** codigo de emision.
  Future<IssuedSession> issueSession({
    required User user,
    required String audience,
    required String accessToken,
    required DateTime issuedAt,
    required DateTime expiresAt,
    String? familyId,
  }) async {
    final refreshToken = _tokens.randomToken(refreshTokenBytes);
    await _refreshTokens.insert(
      id: _ids.newId(),
      familyId: familyId ?? _ids.newId(),
      userId: user.id,
      audience: audience,
      tokenHash: _tokens.hashToken(refreshToken),
      expiresAt: issuedAt.add(refreshLifetime),
    );
    await _audit.write(
      action: 'auth.session.issue',
      entityType: 'user',
      entityId: user.id,
      userId: user.id,
    );
    return IssuedSession(
      accessToken: accessToken,
      expiresIn: expiresAt.difference(issuedAt).inSeconds,
      refreshToken: refreshToken,
    );
  }
}
