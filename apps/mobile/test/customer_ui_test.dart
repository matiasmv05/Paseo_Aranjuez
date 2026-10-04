import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paseo_mobile/app.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_filter_chip.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_points_tag.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_qr_code.dart';
import 'package:paseo_mobile/design_system/molecules/benefit_list_card.dart';
import 'package:paseo_mobile/design_system/molecules/paseo_bottom_nav_bar.dart';
import 'package:paseo_mobile/design_system/molecules/paseo_points_card.dart';
import 'package:paseo_mobile/design_system/molecules/qr_display_card.dart';
import 'package:paseo_mobile/design_system/molecules/transaction_tile.dart';
import 'package:paseo_mobile/design_system/organisms/redemption_confirm_dialog.dart';
import 'package:paseo_mobile/design_system/organisms/redemption_success_sheet.dart';
import 'package:paseo_mobile/pages/benefit_detail_page.dart';
import 'package:paseo_mobile/pages/client_shell_page.dart';
import 'package:paseo_mobile/pages/points_history_page.dart';
import 'package:paseo_mobile/pages/welcome_page.dart';

void main() {
  testWidgets(
    'CustomerApp navigates complete Paseo Points client experience and all 5 '
    'tabs',
    (tester) async {
      await tester.pumpWidget(const CustomerApp());
      await tester.pumpAndSettle();

      // 0. Verifica pantalla de bienvenida y pulsa "Comenzar"
      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.text('Paseo Points'), findsOneWidget);
      expect(find.text('Comenzar'), findsOneWidget);

      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      // 1. Verifica pantalla de Inicio / Dashboard (Pantalla 3)
      expect(find.byType(ClientShellPage), findsOneWidget);
      expect(find.text('Hola, Valentina 👋'), findsOneWidget);
      expect(
        find.text('Disfruta todos los beneficios de Paseo Aranjuez'),
        findsOneWidget,
      );
      expect(find.byType(PaseoPointsCard), findsOneWidget);
      expect(find.text('2.450'), findsOneWidget);
      expect(find.text('Mostrar mi QR'), findsOneWidget);
      expect(find.text('Beneficios para ti'), findsOneWidget);
      expect(find.text('Promociones vigentes'), findsOneWidget);
      // Desplaza la lista para revelar la sección de establecimientos
      await tester.drag(find.byType(ListView).first, const Offset(0, -260));
      await tester.pumpAndSettle();
      expect(find.text('Establecimientos'), findsOneWidget);
      expect(find.byType(PaseoBottomNavBar), findsOneWidget);

      // 2. Abre historial de puntos desde la tarjeta principal
      await tester.drag(find.byType(ListView).first, const Offset(0, 260));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PaseoPointsCard));
      await tester.pumpAndSettle();

      expect(find.byType(PointsHistoryPage), findsOneWidget);
      expect(find.text('Mis puntos'), findsOneWidget);
      expect(find.text('puntos disponibles'), findsOneWidget);
      expect(
        find.byType(PaseoFilterChip),
        findsNWidgets(3),
      ); // Todos, Ganados, Canjeados
      expect(find.byType(TransactionTile), findsWidgets);

      // Retorna a Inicio
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(ClientShellPage), findsOneWidget);

      // 3. Navega a la pestaña de QR desde el botón "Mostrar mi QR"
      await tester.tap(find.text('Mostrar mi QR'));
      await tester.pumpAndSettle();

      expect(find.byType(QrDisplayCard), findsOneWidget);
      expect(find.byType(PaseoQrCode), findsOneWidget);
      expect(find.text('Valentina Rodríguez'), findsOneWidget);
      expect(find.text('+591 720 12345'), findsOneWidget);

      // 4. Navega a la pestaña de Beneficios (Tab 1)
      final benefitsTab = find.descendant(
        of: find.byType(PaseoBottomNavBar),
        matching: find.text('Beneficios'),
      );
      await tester.tap(benefitsTab);
      await tester.pumpAndSettle();

      expect(find.text('Beneficios'), findsNWidgets(2));
      expect(find.byType(PaseoFilterChip), findsNWidgets(4)); // Categorías
      expect(find.byType(BenefitListCard), findsWidgets);
      expect(find.text('20% de descuento en Café Aranjuez'), findsOneWidget);

      // 5. Entra al detalle de un beneficio y ejecuta el flujo de canje
      await tester.tap(find.text('20% de descuento en Café Aranjuez'));
      await tester.pumpAndSettle();

      expect(find.byType(BenefitDetailPage), findsOneWidget);
      expect(find.byType(PaseoPointsTag), findsOneWidget);
      expect(find.text('Canjear por 500 puntos'), findsOneWidget);
      expect(find.text('Condiciones'), findsOneWidget);

      // Inicia el canje (muestra diálogo de confirmación - Pantalla 7)
      await tester.tap(find.text('Canjear por 500 puntos'));
      await tester.pumpAndSettle();

      expect(find.byType(RedemptionConfirmDialog), findsOneWidget);
      expect(find.text('¿Quieres canjear esta\nrecompensa?'), findsOneWidget);
      expect(
        find.text('Se descontarán 500 puntos\nde tu saldo.'),
        findsOneWidget,
      );
      expect(find.text('Confirmar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      // Confirma el canje (Pantalla 8: Canje realizado)
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(find.byType(RedemptionSuccessView), findsOneWidget);
      expect(find.text('¡Canje realizado!'), findsOneWidget);
      expect(find.text('PA-483921'), findsOneWidget);
      expect(find.text('Volver a beneficios'), findsOneWidget);

      // Retorna al catálogo de beneficios
      await tester.tap(find.text('Volver a beneficios'));
      await tester.pumpAndSettle();
      expect(find.byType(ClientShellPage), findsOneWidget);

      // 6. Navega a la pestaña de Promociones (Tab 3)
      final promosTab = find.descendant(
        of: find.byType(PaseoBottomNavBar),
        matching: find.text('Promociones'),
      );
      await tester.tap(promosTab);
      await tester.pumpAndSettle();

      expect(find.text('Promociones'), findsNWidgets(2));
      expect(find.text('Puntos dobles este fin de semana'), findsOneWidget);

      // 7. Navega a la pestaña de Perfil (Tab 4)
      final profileTab = find.descendant(
        of: find.byType(PaseoBottomNavBar),
        matching: find.text('Perfil'),
      );
      await tester.tap(profileTab);
      await tester.pumpAndSettle();

      expect(find.text('Mi perfil'), findsOneWidget);
      expect(find.text('Valentina Rodríguez'), findsOneWidget);
      expect(find.text('valentina@email.com'), findsOneWidget);
      expect(find.text('+591 720 12345'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);

      // 8. Cierra sesión y retorna a WelcomePage
      await tester.drag(find.byType(ListView).first, const Offset(0, -220));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomePage), findsOneWidget);
    },
  );
}
