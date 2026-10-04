import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paseo_mobile/app.dart';
import 'package:paseo_mobile/design_system/atoms/pos_preset_button.dart';
import 'package:paseo_mobile/design_system/molecules/pos_activity_item.dart';
import 'package:paseo_mobile/design_system/molecules/pos_member_card.dart';
import 'package:paseo_mobile/design_system/organisms/merchant_sidebar.dart';
import 'package:paseo_mobile/design_system/organisms/pos_activity_feed.dart';
import 'package:paseo_mobile/design_system/organisms/pos_member_lookup.dart';
import 'package:paseo_mobile/design_system/organisms/pos_purchase_form.dart';

void main() {
  testWidgets(
    'MerchantWebApp renders Store Front & Quick Entry POS and computes points',
    (tester) async {
      // Configuramos tamaño de pantalla desktop amplio (1600 x 1000)
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MerchantWebApp());
      await tester.pumpAndSettle();

      // 1. Verifica barra lateral (MerchantSidebar)
      expect(find.byType(MerchantSidebar), findsOneWidget);
      expect(find.text('PASEO POINTS'), findsOneWidget);
      expect(find.text('ARANJUEZ CONCIERGE'), findsOneWidget);
      expect(find.text('STORE FRONT / QUICK\nENTRY'), findsOneWidget);
      expect(find.text('Paseo Direct NFC Channel'), findsOneWidget);
      expect(find.text('PA-8842-VIP'), findsOneWidget);

      // 2. Verifica cabecera de terminal (PosHeaderBar)
      expect(find.text('OPERATIONS'), findsOneWidget);
      expect(find.text('BOUTIQUE POS\nTERMINAL'), findsOneWidget);
      expect(find.text('ELENA VANCE'), findsOneWidget);
      expect(find.text('FLOOR DIRECTOR'), findsOneWidget);
      expect(
        find.text('BOUTIQUE VALLDEMOSSA • TERMINAL 01 • ONLINE'),
        findsOneWidget,
      );

      // 3. Verifica título de sección y estado de enlace
      expect(find.text('Store Front & Quick Entry'), findsOneWidget);
      expect(find.text('POS LINK 01 ACTIVE'), findsOneWidget);
      expect(find.text('DAILY SYNC #4102'), findsOneWidget);

      // 4. Verifica organismo de autenticación de socio (PosMemberLookup)
      expect(find.byType(PosMemberLookup), findsOneWidget);
      expect(find.text('Client Identification'), findsOneWidget);
      expect(find.text('CRYPTOGRAPHIC NFC & OPTICAL TERMINAL'), findsOneWidget);
      expect(find.byType(PosMemberCard), findsOneWidget);
      expect(find.text('Alejandro Morales'), findsNWidgets(2));
      expect(find.text('VIP OBSIDIAN'), findsOneWidget);
      expect(find.text('#ARJ-9921'), findsNWidgets(2));
      expect(find.text('3,450'), findsOneWidget);

      // 5. Verifica formulario de compra y cálculo instantáneo
      expect(find.byType(PosPurchaseForm), findsOneWidget);
      expect(find.text('Store Purchase Registration'), findsOneWidget);
      expect(find.text('450.00'), findsOneWidget);
      expect(find.text('TCK-88204'), findsOneWidget);
      expect(find.text('+450 PTS'), findsOneWidget);
      expect(find.text('(+45 VIP\nBonus)'), findsOneWidget);
      expect(find.text('495'), findsOneWidget);

      // 6. Verifica presets y cálculo en vivo: pulsa +€50
      expect(find.byType(PosPresetButton), findsNWidgets(5));
      await tester.tap(find.text('+€50'));
      await tester.pumpAndSettle();

      // Monto a 500.00 y puntos actualizados a 500 Base + 50 Bonus = 550 Total
      expect(find.text('500.00'), findsOneWidget);
      expect(find.text('+500 PTS'), findsOneWidget);
      expect(find.text('(+50 VIP\nBonus)'), findsOneWidget);
      expect(find.text('550'), findsOneWidget);

      // 7. Verifica feed contable y registro de compra
      expect(find.byType(PosActivityFeed), findsOneWidget);
      expect(find.text('Store Activity Feed'), findsOneWidget);
      expect(find.byType(PosActivityItem), findsNWidgets(3));
      expect(find.text('SHIFT OVERVIEW (TERMINAL 01)'), findsOneWidget);
      expect(find.text('€3,730.00'), findsOneWidget);
      expect(find.text('4,065 PTS'), findsOneWidget);

      // 8. Registra la compra y verifica actualización del feed
      await tester.tap(find.text('REGISTER PURCHASE & AWARD POINTS  →'));
      await tester.pumpAndSettle();

      // Verifica que se agregó la transacción al tope del feed
      expect(find.text('Ahora'), findsOneWidget);
      expect(find.text('€500.00'), findsOneWidget);
      expect(find.text('+550'), findsOneWidget);
      expect(find.byType(PosActivityItem), findsNWidgets(4));

      // Restaura dimensiones
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    },
  );
}
