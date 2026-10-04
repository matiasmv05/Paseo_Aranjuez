import 'package:flutter_test/flutter_test.dart';
import 'package:paseo_mobile/app.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_end_of_ledger.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_nfc_beacon.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_nfc_chip.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_points_pill.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_section_tag.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_vip_pill.dart';
import 'package:paseo_mobile/design_system/molecules/paseo_curated_reward_card.dart';
import 'package:paseo_mobile/design_system/molecules/paseo_history_card.dart';
import 'package:paseo_mobile/design_system/organisms/membership_pass_card.dart';

void main() {
  testWidgets(
    'CustomerApp renders VIP Club landing screen and navigates all tabs',
    (tester) async {
      await tester.pumpWidget(const CustomerApp());
      await tester.pumpAndSettle();

      // 1. Verifica elementos de la pantalla CLUB (Screenshot 4)
      expect(find.text('PASEO ARANJUEZ PRIVILÈGES'), findsOneWidget);
      expect(find.text('Good evening,\nAlejandro'), findsOneWidget);
      expect(find.byType(PaseoVipPill), findsOneWidget);
      expect(find.text('VIP\nOBSIDIAN'), findsOneWidget);
      expect(find.text('#ARJ-9921'), findsOneWidget);

      // Tarjeta de membresía (MembershipPassCard)
      expect(find.byType(MembershipPassCard), findsOneWidget);
      expect(find.text('MEMBERSHIP PASS'), findsOneWidget);
      expect(find.byType(PaseoNfcChip), findsOneWidget);
      expect(find.text('NFC READY'), findsOneWidget);
      expect(find.text('ACCUMULATED PRIVILEGE BALANCE'), findsOneWidget);
      expect(find.text('3,450'), findsOneWidget);
      expect(find.text('PTS'), findsOneWidget);
      expect(find.text('PROGRESS'), findsOneWidget);
      expect(find.text('550 PTS TO SOVEREIGN TIER'), findsOneWidget);
      expect(find.text('PASEO ARANJUEZ'), findsOneWidget);
      expect(find.text('VALID THRU 12/27'), findsOneWidget);

      // Botones de acción CTA
      expect(find.text('REDEEM PRIVILÈGES  →'), findsOneWidget);
      expect(find.text('TAP TO PAY (NFC READY)'), findsOneWidget);

      // 2. Interacción con Tap to Pay (NFC Modal)
      await tester.ensureVisible(find.text('TAP TO PAY (NFC READY)'));
      await tester.tap(find.text('TAP TO PAY (NFC READY)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CONCIERGE NFC READY'), findsOneWidget);
      expect(find.text('Aproxima tu dispositivo'), findsOneWidget);

      // Cierra el modal NFC
      await tester.tap(find.text('CANCELAR'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 3. Navega a REWARDS mediante el botón de canje
      await tester.ensureVisible(find.text('REDEEM PRIVILÈGES  →'));
      await tester.tap(find.text('REDEEM PRIVILÈGES  →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('ATELIER ALLOCATIONS'), findsOneWidget);
      expect(find.text('Curated Privilèges'), findsOneWidget);
      expect(find.byType(PaseoPointsPill), findsOneWidget);
      expect(find.byType(PaseoCuratedRewardCard), findsNWidgets(2));
      expect(find.text('Swiss Automatic Watch\nService'), findsOneWidget);
      expect(find.byType(PaseoNfcBeacon), findsOneWidget);

      // 4. Navega a la pestaña ACTIVITY
      await tester.tap(find.text('ACTIVITY'));
      await tester.pumpAndSettle();

      expect(find.byType(PaseoSectionTag), findsOneWidget);
      expect(find.text('MEMBER ACTIVITY'), findsOneWidget);
      expect(find.text('Points History'), findsOneWidget);
      expect(find.byType(PaseoHistoryCard), findsNWidgets(2));
      expect(find.text('Haute Horlogerie Boutique'), findsOneWidget);
      expect(find.byType(PaseoEndOfLedger), findsOneWidget);

      // 5. Navega a la pestaña PROFILE
      await tester.tap(find.text('PROFILE'));
      await tester.pumpAndSettle();

      expect(find.text('Alejandro Morales'), findsOneWidget);
      expect(find.text('VIP OBSIDIAN MEMBER'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);

      // 6. Regresa a la pestaña CLUB
      await tester.tap(find.text('CLUB'));
      await tester.pumpAndSettle();

      expect(find.text('Good evening,\nAlejandro'), findsOneWidget);
      expect(find.byType(MembershipPassCard), findsOneWidget);
    },
  );
}
