import 'package:paseo_api/adapters/out/email/console_email_sender.dart';
import 'package:paseo_api/domain/identity/email.dart';
import 'package:test/test.dart';

void main() {
  group('ConsoleEmailSender', () {
    test('sendEmailVerification does not throw', () async {
      final sender = ConsoleEmailSender();
      await expectLater(
        sender.sendEmailVerification(
          email: Email.parse('user@example.com'),
          token: 'verify-abc',
        ),
        completes,
      );
    });

    test('sendPasswordReset does not throw', () async {
      final sender = ConsoleEmailSender();
      await expectLater(
        sender.sendPasswordReset(
          email: Email.parse('user@example.com'),
          token: 'reset-xyz',
        ),
        completes,
      );
    });
  });
}