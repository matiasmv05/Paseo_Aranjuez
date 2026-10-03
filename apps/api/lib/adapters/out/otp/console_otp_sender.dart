import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/phone_bo.dart';

/// OTP sender for development: logs the code to stdout.
/// Never used in production (AGENTS.md §15: OTP provider decided later).
final class ConsoleOtpSender implements OtpSender {
  @override
  Future<void> sendOtp({required PhoneBO phone, required String code}) async {
    print('[OTP] To: ${phone.value} | Code: $code | Purpose: phone verification');
  }
}
