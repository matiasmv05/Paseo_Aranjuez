import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paseo_mobile/app.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_brand_crest.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_welcome_button.dart';
import 'package:paseo_mobile/pages/client_shell_page.dart';
import 'package:paseo_mobile/pages/login_page.dart';
import 'package:paseo_mobile/pages/register_page.dart';
import 'package:paseo_mobile/pages/welcome_page.dart';

void main() {
  testWidgets(
    'WelcomePage renders brand emblem, luxury titles, and action buttons',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: WelcomePage()));
      await tester.pumpAndSettle();

      // 1. Verifica presencia del emblema de Paseo Aranjuez
      expect(find.byType(PaseoBrandCrest), findsOneWidget);
      expect(find.text('PASEO'), findsOneWidget);
      expect(find.text('ARANJUEZ'), findsOneWidget);

      // 2. Verifica títulos y subtítulos
      expect(find.text('Paseo Points'), findsOneWidget);
      expect(
        find.text(
          'Tu experiencia en Paseo Aranjuez,\nahora con más beneficios.',
        ),
        findsOneWidget,
      );

      // 3. Verifica botones de acción
      expect(find.byType(PaseoWelcomeButton), findsOneWidget);
      expect(find.text('Comenzar'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
    },
  );

  testWidgets(
    'Tapping Iniciar sesión navigates to LoginPage and allows moving to '
    'RegisterPage',
    (tester) async {
      await tester.pumpWidget(const CustomerApp());
      await tester.pumpAndSettle();

      // Abre la pantalla de inicio de sesión
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Ingresa a tu cuenta para continuar'), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Regístrate'), findsOneWidget);

      // Navega a la pantalla de registro
      await tester.ensureVisible(find.text('Regístrate'));
      await tester.tap(find.text('Regístrate'));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterPage), findsOneWidget);
      expect(find.text('Crear cuenta'), findsOneWidget);
      expect(find.text('Nombre completo'), findsOneWidget);
    },
  );

  testWidgets('Tapping Comenzar navigates directly to ClientShellPage', (
    tester,
  ) async {
    await tester.pumpWidget(const CustomerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    expect(find.byType(ClientShellPage), findsOneWidget);
    expect(find.text('Hola, Valentina 👋'), findsOneWidget);
  });
}
