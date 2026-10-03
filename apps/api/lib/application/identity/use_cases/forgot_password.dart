import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';

/// US5: solicitud de restablecimiento (FR-008). **Siempre** termina sin
/// error (la ruta mapea a 202), exista o no el correo; solo envia si el
/// correo existe y esta verificado.
final class ForgotPassword {
  const ForgotPassword({
    required UserRepository users,
    required PasswordResetRepository resets,
    required EmailSender emailSender,
    required TokenGenerator tokens,
    required IdGenerator ids,
    required Clock clock,
    required AuditLogWriter audit,
    this.tokenBytes = 32,
    this.tokenTtl = const Duration(minutes: 30),
  }) : _users = users,
       _resets = resets,
       _emailSender = emailSender,
       _tokens = tokens,
       _ids = ids,
       _clock = clock,
       _audit = audit;

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
      // Misma respuesta externa; solo se audita internamente.
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
