import 'package:flutter_test/flutter_test.dart';
import 'package:paseo_mobile/features/identity/data/mock_auth_repository.dart';
import 'package:paseo_mobile/features/identity/data/token_storage.dart';
import 'package:paseo_mobile/features/identity/identity_state.dart';

void main() {
  group('IdentityNotifier', () {
    test('estado inicial es IdentityInitial', () {
      final notifier = IdentityNotifier(
        MockAuthRepository(),
        tokenStorage: InMemoryTokenStorage(),
      );
      expect(notifier.value, isA<IdentityInitial>());
    });

    test(
      'sendOtp pasa por IdentityLoading y termina en OtpSentSuccess',
      () async {
        final notifier = IdentityNotifier(
          MockAuthRepository(),
          tokenStorage: InMemoryTokenStorage(),
        );
        final states = <IdentityState>[notifier.value];
        notifier.addListener(() => states.add(notifier.value));

        await notifier.sendOtp('+59170123456');

        expect(states, hasLength(3));
        expect(states[0], isA<IdentityInitial>());
        expect(states[1], isA<IdentityLoading>());
        expect(states[2], isA<OtpSentSuccess>());
      },
    );

    test('verifyOtp correcto emite OtpVerified y persiste el token', () async {
      final store = InMemoryTokenStorage();
      final notifier = IdentityNotifier(
        MockAuthRepository(),
        tokenStorage: store,
      );

      await notifier.verifyOtp('+59170123456', '123456');

      expect(notifier.value, isA<OtpVerified>());
      expect(await store.getToken(), isNotNull);
      expect(await store.getToken(), isNotEmpty);
    });

    test(
      'verifyOtp incorrecto emite IdentityFailure y no persiste token',
      () async {
        final store = InMemoryTokenStorage();
        final notifier = IdentityNotifier(
          MockAuthRepository(),
          tokenStorage: store,
        );

        await notifier.verifyOtp('+59170123456', '000000');

        expect(notifier.value, isA<IdentityFailure>());
        expect(await store.getToken(), isNull);
      },
    );

    test(
      'checkAuthStatus con token guardado emite IdentityAuthenticated',
      () async {
        final store = InMemoryTokenStorage();
        await store.saveToken('jwt-previo');
        final notifier = IdentityNotifier(
          MockAuthRepository(),
          tokenStorage: store,
        );

        await notifier.checkAuthStatus();

        expect(notifier.value, isA<IdentityAuthenticated>());
      },
    );

    test('checkAuthStatus sin token emite IdentityUnauthenticated', () async {
      final notifier = IdentityNotifier(
        MockAuthRepository(),
        tokenStorage: InMemoryTokenStorage(),
      );

      await notifier.checkAuthStatus();

      expect(notifier.value, isA<IdentityUnauthenticated>());
    });
  });
}
