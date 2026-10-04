import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paseo_mobile/features/customer/profile_screen.dart';
import 'package:paseo_mobile/features/identity/data/mock_auth_repository.dart';
import 'package:paseo_mobile/features/identity/data/token_storage.dart';
import 'package:paseo_mobile/features/identity/identity_state.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  IdentityNotifier buildNotifier(TokenStorage store) {
    return IdentityNotifier(MockAuthRepository(), tokenStorage: store);
  }

  testWidgets('muestra la información básica del perfil', (tester) async {
    await tester.pumpWidget(
      ProfileScreen(
        phone: '+59170123456',
        notifier: buildNotifier(InMemoryTokenStorage()),
      ),
    );

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('+59170123456'), findsOneWidget);
  });

  testWidgets('muestra el código QR del cliente (/customers/me/qr)', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProfileScreen(
        phone: '+59170123456',
        notifier: buildNotifier(InMemoryTokenStorage()),
        qrPayload: 'qr-token-abc',
      ),
    );

    expect(find.byKey(const Key('customerQr')), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets(
    'Cerrar Sesión borra el token, resetea el notifier y vuelve al registro',
    (tester) async {
      final store = InMemoryTokenStorage();
      await store.saveToken('jwt-previo');
      final notifier = buildNotifier(store);
      await notifier.checkAuthStatus();
      expect(notifier.value, isA<IdentityAuthenticated>());

      await tester.pumpWidget(ProfileScreen(notifier: notifier));
      await tester.tap(find.byKey(const Key('logoutButton')));
      await tester.pumpAndSettle();

      expect(await store.getToken(), isNull);
      expect(notifier.value, isA<IdentityUnauthenticated>());
      expect(find.text('Register'), findsOneWidget);
    },
  );
}
