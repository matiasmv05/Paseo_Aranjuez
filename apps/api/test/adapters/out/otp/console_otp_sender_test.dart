import 'package:paseo_api/adapters/out/otp/console_otp_sender.dart';
import 'package:paseo_api/domain/identity/phone_bo.dart';
import 'package:test/test.dart';

void main() {
  group('ConsoleOtpSender', () {
    test('sendOtp does not throw and returns normally', () async {
      final sender = ConsoleOtpSender();
      await expectLater(
        sender.sendOtp(phone: PhoneBO.parse('+59160000000'), code: '123456'),
        completes,
      );
    });

    test('sendOtp prints to stdout (side effect: prints OTP line)', () async {
      final sender = ConsoleOtpSender();
      // Console print is a side effect; we verify no exception.
      await sender.sendOtp(phone: PhoneBO.parse('+59160123456'), code: '654321');
    });
  });
}