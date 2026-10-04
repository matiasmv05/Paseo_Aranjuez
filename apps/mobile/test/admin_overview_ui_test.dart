import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paseo_mobile/app.dart';
import 'package:paseo_mobile/design_system/atoms/admin_pill_badge.dart';
import 'package:paseo_mobile/design_system/atoms/admin_tab_pill.dart';
import 'package:paseo_mobile/design_system/molecules/admin_header_bar.dart';
import 'package:paseo_mobile/design_system/molecules/admin_kpi_card.dart';
import 'package:paseo_mobile/design_system/organisms/admin_kpi_grid.dart';
import 'package:paseo_mobile/design_system/organisms/admin_sidebar.dart';
import 'package:paseo_mobile/design_system/organisms/admin_transaction_chart.dart';

void main() {
  testWidgets(
    'AdminWebApp renders Executive Overview with KPIs and interactive chart',
    (tester) async {
      // Configuramos tamaño de pantalla desktop amplio (1600 x 1000)
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const AdminWebApp());
      await tester.pumpAndSettle();

      // 1. Verifica barra lateral de navegación (AdminSidebar)
      expect(find.byType(AdminSidebar), findsOneWidget);
      expect(find.text('PASEO'), findsOneWidget);
      expect(find.text('POINTS CONCIERGE'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Stores'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Rewards'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('BOUTIQUE NODE'), findsOneWidget);
      expect(find.text('Aranjuez Central'), findsOneWidget);
      expect(find.text('NFC Terminal Active'), findsOneWidget);

      // 2. Verifica barra superior (AdminHeaderBar)
      expect(find.byType(AdminHeaderBar), findsOneWidget);
      expect(find.text('EXECUTIVE'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Alejandro Silva'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);

      // 3. Verifica cabecera del dashboard ejecutivo
      expect(
        find.text('PASEO POINTS INTELLIGENCE • LIVE NODE 01'),
        findsOneWidget,
      );
      expect(find.text('Executive Overview'), findsOneWidget);
      expect(find.byType(AdminPillBadge), findsNWidgets(2));
      expect(find.text('TODAY • OCT 24'), findsOneWidget);
      expect(find.text('REFRESH FEED'), findsOneWidget);

      // 4. Verifica cuadrícula de métricas clave (AdminKpiGrid & AdminKpiCard)
      expect(find.byType(AdminKpiGrid), findsOneWidget);
      expect(find.byType(AdminKpiCard), findsNWidgets(3));

      // Tarjeta 1: Total Users
      expect(find.text('TOTAL USERS'), findsOneWidget);
      expect(find.text('18,420'), findsOneWidget);
      expect(find.text('12.4%'), findsOneWidget);
      expect(find.text('this month'), findsOneWidget);
      expect(find.text('2,140 Black Tier • 16,280 Gold'), findsOneWidget);

      // Tarjeta 2: Points Issued Today
      expect(find.text('POINTS ISSUED TODAY'), findsOneWidget);
      expect(find.text('48,290'), findsOneWidget);
      expect(find.text('PTS'), findsNWidgets(2)); // En KPI y en PEAK
      expect(find.text(r'~$4,829 USD'), findsOneWidget);
      expect(find.text('94.2% Circulating Ratio'), findsOneWidget);

      // Tarjeta 3: Active Stores
      expect(find.text('ACTIVE STORES'), findsOneWidget);
      expect(find.text('54'), findsOneWidget);
      expect(find.text('STORES'), findsOneWidget);
      expect(
        find.text('100% estate coverage across all wings'),
        findsOneWidget,
      );
      expect(find.text('54 / 54 Online'), findsOneWidget);

      // 5. Verifica gráfico analítico de transacciones (AdminTransactionChart)
      expect(find.byType(AdminTransactionChart), findsOneWidget);
      expect(find.text('Recent Transaction Activity'), findsOneWidget);
      expect(find.text('VERIFIED LEDGER'), findsOneWidget);
      expect(find.text('68,400'), findsOneWidget);
      expect(find.text('42,150'), findsOneWidget);
      expect(find.text('PTS/day'), findsOneWidget);

      // Conmutadores de rango temporal
      expect(find.byType(AdminTabPill), findsNWidgets(2));
      expect(find.text('LAST 7 DAYS'), findsOneWidget);
      expect(find.text('LAST 30 DAYS'), findsOneWidget);

      // Perspectivas analíticas inferiores
      expect(find.text('HIGHEST VOLUME BOUTIQUE'), findsOneWidget);
      expect(find.text('Haute Horlogerie'), findsOneWidget);
      expect(find.text(' (32%)'), findsOneWidget);
      expect(find.text('PEAK ACTIVITY WINDOW'), findsOneWidget);
      expect(find.text('18:00 – 21:00 CEST'), findsOneWidget);
      expect(find.text('SETTLEMENT STATUS'), findsOneWidget);
      expect(find.text('All POS Synced'), findsOneWidget);

      // 6. Prueba interactiva: conmutar a LAST 30 DAYS
      await tester.tap(find.text('LAST 30 DAYS'));
      await tester.pumpAndSettle();

      // 7. Prueba interactiva: pulsar REFRESH FEED y comprobar feedback
      await tester.tap(find.text('REFRESH FEED'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(
        find.text('Datos ejecutivos sincronizados con el ledger privado.'),
        findsOneWidget,
      );

      // Restaura dimensiones
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    },
  );
}
