import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';

/// US5: solicitud de restablecimiento (FR-008). **Siempre** termina sin
/// error (la ruta mapea a 202), exista o no el correo; solo envia si el
/// correo existe y esta verificado.
final class ForgotPassword {
  const new({
    required this._users,
    required PasswordResetRepository resets,
    required this._emailSender,
    required this._tokens,
    required this._ids,
    required this._clock,
    required this._audit,
    this.tokenBytes = 32,
    this.tokenTtl = const Duration(minutes: 30),
  }) : _resets = resets;

  final UserRepository _users;
  final PasswordResetRepository _resets;
  final EmailSender _emailSender;
  final TokenGenerator _tokens;
  final IdGenerator _ids;
  final Clock _clock;
  final AuditLogWriter _audit;

  /// >= 32 bytes aleatorios (FR-008).
  final int tokenBytes;

  /// 30 minutos.
  final Duration tokenTtl;

  Future<void> call({required String email}) async {
    final parsed = Email.parse(email);
    final user = await _users.findByEmail(parsed);
    if (user == null || !user.emailVerified) {
      // Respuesta siempre 202 en la ruta; no se revela existencia y el
      // acceso sin cuenta no se audita (no contiene actor ni efectos).
      return;
    }
    final now = _clock.nowUtc();
    final token = _tokens.randomToken(tokenBytes);
    await _resets.insert(
      id: _ids.newId(),
      userId: user.id,
      tokenHash: _tokens.hashToken(token),
      expiresAt: now.add(tokenTtl),
    );
    await _emailSender.sendPasswordReset(email: parsed, token: token);
    await _audit.write(
      action: 'auth.password.forgot',
      entityType: 'user',
      entityId: user.id,
      userId: user.id,
    );
  }
}
