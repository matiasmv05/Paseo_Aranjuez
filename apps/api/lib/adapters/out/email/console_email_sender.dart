import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/email.dart';

/// Email sender for development: logs the email to stdout instead of sending.
/// Set EMAIL_SENDER=console in dev (decisión 03/10: sin Mailpit).
final class ConsoleEmailSender implements EmailSender {
  @override
  Future<void> sendEmailVerification({
    required Email email,
    required String token,
  }) async {
    print(
      '[EMAIL] To: ${email.value} | Subject: Verifica tu correo — Paseo Points | Token: $token',
    );
  }

  @override
  Future<void> sendPasswordReset({
    required Email email,
    required String token,
  }) async {
    print(
      '[EMAIL] To: ${email.value} | Subject: Recupera tu contraseña — Paseo Points | Token: $token',
    );
  }
}
