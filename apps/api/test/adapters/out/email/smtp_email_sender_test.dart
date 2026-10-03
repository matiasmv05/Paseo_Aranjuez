import 'package:paseo_api/adapters/out/email/smtp_email_sender.dart';
import 'package:paseo_api/domain/identity/email.dart';
import 'package:test/test.dart';

// We need to inject the send function to avoid real SMTP connections in tests.
// We'll test the SmtpEmailSender logic with a mock send function.
void main() {
  group('SmtpConfig', () {
    test('fromEnv reads SMTP_* variables', () {
      // This test just verifies the factory is available and reads env
      final cfg = SmtpConfig.fromEnv();
      expect(cfg.host, isNot(contains('undefined')));
      expect(cfg.port, 587);
    });

    test('isConfigured returns true when all fields set', () {
      const cfg = SmtpConfig(
        host: 'smtp.gmail.com',
        port: 587,
        username: 'u',
        password: 'p',
        from: 'f',
      );
      expect(cfg.isConfigured, isTrue);
    });

    test('isConfigured returns false when missing password', () {
      const cfg = SmtpConfig(
        host: 'smtp.gmail.com',
        port: 587,
        username: 'u',
        password: '',
        from: 'f',
      );
      expect(cfg.isConfigured, isFalse);
    });
  });

  group('SmtpEmailSender', () {
    test('sendEmailVerification throws when SMTP not configured', () async {
      const cfg = SmtpConfig(
        host: 'smtp.gmail.com',
        port: 587,
        username: '',
        password: '',
        from: '',
      );
      final sender = SmtpEmailSender(config: cfg);

      expect(
        () => sender.sendEmailVerification(
          email: Email.parse('user@example.com'),
          token: 'abc123',
        ),
        throwsA(isA<EmailNotConfiguredException>()),
      );
    });

    test('sendPasswordReset throws when SMTP not configured', () async {
      const cfg = SmtpConfig(
        host: 'smtp.gmail.com',
        port: 587,
        username: '',
        password: '',
        from: '',
      );
      final sender = SmtpEmailSender(config: cfg);

      expect(
        () => sender.sendPasswordReset(
          email: Email.parse('user@example.com'),
          token: 'reset-token',
        ),
        throwsA(isA<EmailNotConfiguredException>()),
      );
    });
  });
}
