import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';

/// US2: verificacion del correo con el token enviado (FR-001, spec US2).
/// Token vencido/usado/desconocido -> `TOKEN_INVALID`.
final class VerifyEmail {
  const new({
    required this._users,
    required VerificationCodeRepository codes,
    required this._tokens,
    required this._clock,
    required this._audit,
  }) : _codes = codes;

  final UserRepository _users;
  final VerificationCodeRepository _codes;
  final TokenGenerator _tokens;
  final Clock _clock;
  final AuditLogWriter _audit;

  Future<void> call({required String token}) async {
    final now = _clock.nowUtc();
    final record = await _codes.findActive(
      target: '',
      purpose: VerificationPurpose.emailVerification,
      now: now,
      tokenHash: _tokens.hashToken(token),
    );
    final state = record?.challenge;
    if (state is! EmailVerification) throw IdentityException.tokenInvalid();
    // Usado o vencido (24 h) -> TOKEN_INVALID (el dominio lanza).
    await _codes.updateChallenge(record!.id, state.consume(now));
    final user = await _users.findByEmail(Email.parse(record.target));
    if (user == null) throw IdentityException.tokenInvalid();
    await _users.markEmailVerified(user.id);
    await _audit.write(
      action: 'auth.email.verify',
      entityType: 'user',
      entityId: user.id,
      userId: user.id,
    );
  }
}
