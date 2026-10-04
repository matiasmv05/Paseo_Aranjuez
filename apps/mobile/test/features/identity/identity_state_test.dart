import 'package:flutter_test/flutter_test.dart';
import 'package:paseo_mobile/features/identity/data/mock_auth_repository.dart';
import 'package:paseo_mobile/features/identity/identity_state.dart';

void main() {
  group('IdentityNotifier', () {
    test('estado inicial es IdentityInitial', () {
      final notifier = IdentityNotifier(MockAuthRepository());
      expect(notifier.value, isA<IdentityInitial>());
    });

    test('sendOtp pasa por IdentityLoading y termina en OtpSentSuccess',
        () async {
      final notifier = IdentityNotifier(MockAuthRepository());
      final states = <IdentityState>[notifier.value];
      notifier.addListener(() => states.add(notifier.value));

      await notifier.sendOtp('+59170123456');

      expect(states, hasLength(3));
      expect(states[0], isA<IdentityInitial>());
      expect(states[1], isA<IdentityLoading>());
      expect(states[2], isA<OtpSentSuccess>());
    });

    test('verifyOtp con código correcto termina en OtpVerified', () async {
      final notifier = IdentityNotifier(MockAuthRepository());

      await notifier.verifyOtp('+59170123456', '123456');

      expect(notifier.value, isA<OtpVerified>());
    });

    test('verifyOtp con código incorrecto emite IdentityFailure', () async {
      final notifier = IdentityNotifier(MockAuthRepository());

      await notifier.verifyOtp('+59170123456', '000000');

      expect(notifier.value, isA<IdentityFailure>());
      expect(
        (notifier.value as IdentityFailure).message,
        contains('OTP'),
      );
    });
  });
}
