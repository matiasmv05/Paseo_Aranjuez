import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paseo_mobile/features/identity/data/token_storage.dart';
import 'package:paseo_mobile/features/identity/domain/auth_repository.dart';
import 'package:paseo_mobile/features/identity/identity_state.dart';
import 'package:paseo_mobile/features/identity/otp_verify_screen.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  IdentityNotifier buildNotifier({AuthRepository? repo}) {
    return IdentityNotifier(
      repo ?? _MockRepo(),
      tokenStorage: InMemoryTokenStorage(),
    );
  }

  Future<void> pumpOtp(
    WidgetTester tester, {
    String phone = '+59170123456',
    IdentityNotifier? notifier,
  }) async {
    await tester.pumpWidget(
      OtpVerifyScreen(phone: phone, notifier: notifier ?? buildNotifier()),
    );
  }

  testWidgets('botón de reenvío deshabilitado y contador en 60s al abrir', (
    tester,
  ) async {
    await pumpOtp(tester);

    final resend = find.byKey(const Key('resendOtpButton'));
    expect(resend, findsOneWidget);
    expect(tester.widget<TextButton>(resend).onPressed, isNull);
    expect(find.byKey(const Key('resendCountdownText')), findsOneWidget);
    expect(find.textContaining('60'), findsOneWidget);
  });

  testWidgets('el temporizador llega a 0 y habilita el botón', (tester) async {
    await pumpOtp(tester);

    await tester.pump(const Duration(seconds: 60));

    final resend = find.byKey(const Key('resendOtpButton'));
    expect(tester.widget<TextButton>(resend).onPressed, isNotNull);
    expect(find.textContaining('60'), findsNothing);
  });

  testWidgets(
    'reenviar invoca sendOtp, reinicia el temporizador y muestra SnackBar',
    (tester) async {
      final repo = _MockRepo();
      when(() => repo.sendOtp('+59170123456')).thenAnswer((_) async {});
      final notifier = buildNotifier(repo: repo);

      await pumpOtp(tester, notifier: notifier);
      await tester.pump(const Duration(seconds: 60));

      final resend = find.byKey(const Key('resendOtpButton'));
      await tester.tap(resend);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Invocó sendOtp con el teléfono de la pantalla.
      verify(() => repo.sendOtp('+59170123456')).called(1);

      // El temporizador se reinició: botón deshabilitado y contador en 60s.
      expect(tester.widget<TextButton>(resend).onPressed, isNull);
      expect(find.textContaining('60'), findsOneWidget);

      // Confirmación visual del reenvío.
      expect(find.text('Código reenviado con éxito'), findsOneWidget);
    },
  );
}
