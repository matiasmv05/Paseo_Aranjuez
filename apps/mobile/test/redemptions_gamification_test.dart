import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paseo_mobile/data/mock/mock_data.dart';
import 'package:paseo_mobile/design_system/atoms/paseo_tier_badge.dart';
import 'package:paseo_mobile/design_system/molecules/customer_tier_card.dart';
import 'package:paseo_mobile/design_system/molecules/referral_card.dart';
import 'package:paseo_mobile/design_system/organisms/merchant_promo_proposal_sheet.dart';
import 'package:paseo_mobile/design_system/organisms/merchant_redemption_validator.dart';
import 'package:paseo_mobile/design_system/organisms/notifications_sheet.dart';

void main() {
  group('MockData Redemptions & Gamification Engine', () {
    test('findCoupon locates default issued coupon PA-483921', () {
      final coupon = MockData.findCoupon('PA-483921');
      expect(coupon, isNotNull);
      expect(coupon!.code, equals('PA-483921'));
      expect(coupon.status, equals(RedemptionStatus.issued));
    });

    test('completeCoupon updates status to used and prevents reuse', () {
      // Primera validación y consumo en caja
      final firstAttempt = MockData.completeCoupon('PA-483921');
      expect(firstAttempt, isTrue);

      final usedCoupon = MockData.findCoupon('PA-483921');
      expect(usedCoupon?.status, equals(RedemptionStatus.used));

      // Intento repetido de consumo debe ser rechazado
      final secondAttempt = MockData.completeCoupon('PA-483921');
      expect(secondAttempt, isFalse);
    });

    test('issueCoupon creates coupon, deducts balance and logs ledger', () {
      final initialBalance = MockData.userBalance;
      const benefit = MockBenefit(
        id: 'ben-unit-test',
        title: 'Café de Prueba',
        establishment: 'Cafetería Demo',
        category: 'Gastronomía',
        pointsRequired: 200,
        description: 'Test description',
        imageAsset: 'assets/images/cafe_cappuccino.jpg',
        conditions: ['Una por cliente'],
      );

      final coupon = MockData.issueCoupon(benefit);
      expect(coupon, isNotNull);
      expect(coupon!.rewardId, equals('ben-unit-test'));
      expect(coupon.status, equals(RedemptionStatus.issued));
      expect(MockData.userBalance, equals(initialBalance - 200));

      final found = MockData.findCoupon(coupon.code);
      expect(found, isNotNull);
      expect(found?.rewardTitle, equals('Café de Prueba'));
    });

    test('getTierInfo returns correct tiers and progress', () {
      final bronce = MockData.getTierInfo(250);
      expect(bronce.tier, equals(LoyaltyTier.bronce));
      expect(bronce.displayName, equals('Bronce'));
      expect(bronce.multiplier, equals(1));
      expect(bronce.pointsToNextTier, equals(250));

      final plata = MockData.getTierInfo(800);
      expect(plata.tier, equals(LoyaltyTier.plata));
      expect(plata.displayName, equals('Plata'));
      expect(plata.multiplier, equals(1.1));

      final oro = MockData.getTierInfo(2000);
      expect(oro.tier, equals(LoyaltyTier.oro));
      expect(oro.displayName, equals('Oro'));
      expect(oro.multiplier, equals(1.2));

      final platinum = MockData.getTierInfo(3500);
      expect(platinum.tier, equals(LoyaltyTier.platinum));
      expect(platinum.displayName, equals('Platinum'));
      expect(platinum.multiplier, equals(1.5));
    });
  });

  group('CustomerTierCard & PaseoTierBadge Widgets', () {
    testWidgets('renders tier card with progress and multiplier', (
      tester,
    ) async {
      final tierInfo = MockData.getTierInfo(1200);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CustomerTierCard(tierInfo: tierInfo)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nivel de Lealtad'), findsOneWidget);
      expect(find.text('Nivel Plata'), findsOneWidget);
      expect(find.text('1.1x PUNTOS'), findsOneWidget);
      expect(find.byType(PaseoTierBadge), findsOneWidget);
      expect(find.text('Ver beneficios activos'), findsOneWidget);
    });

    testWidgets('renders ReferralCard with promo details and code', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ReferralCard(referralCode: 'TEST-CODE-99')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Invita amigos y gana puntos'), findsOneWidget);
      expect(find.text('TEST-CODE-99'), findsOneWidget);
      expect(find.text('Copiar'), findsOneWidget);
    });
  });

  group('MerchantRedemptionValidator Widget', () {
    testWidgets('allows cashier to verify and complete coupon redemption', (
      tester,
    ) async {
      // Ensure there is an issued coupon
      const testCoupon = MockRedemptionCoupon(
        id: 'red-test-01',
        code: 'PA-TEST99',
        rewardId: 'ben-01',
        rewardTitle: '20% Descuento Especial',
        establishmentName: 'Boutique Valldemossa',
        customerName: 'Cliente Test',
        customerPhone: '+591 700 00000',
        pointsSpent: 300,
        status: RedemptionStatus.issued,
        issuedAt: 'Ahora',
      );
      MockData.coupons.insert(0, testCoupon);

      MockRedemptionCoupon? completedCoupon;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MerchantRedemptionValidator(
              establishmentName: 'Boutique Valldemossa',
              onRedeemed: (coupon) => completedCoupon = coupon,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Validar Cupón de Canje'), findsOneWidget);
      expect(find.text('Verificar código'), findsOneWidget);

      // Escribir el código en el campo de texto
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'PA-TEST99');
      await tester.tap(find.text('Verificar código'));
      await tester.pumpAndSettle();

      // Verifica que encontró el cupón y muestra detalles
      expect(find.text('20% Descuento Especial'), findsOneWidget);
      expect(find.text('Entregar Recompensa en Caja'), findsOneWidget);

      // Confirmar entrega
      await tester.tap(find.text('Entregar Recompensa en Caja'));
      await tester.pumpAndSettle();

      // Debe mostrar pantalla de éxito
      expect(find.text('¡Canje Entregado con Éxito!'), findsOneWidget);
      expect(completedCoupon, isNotNull);
      expect(completedCoupon?.status, equals(RedemptionStatus.used));
    });
  });

  group('MerchantPromoProposalSheet Widget', () {
    testWidgets('allows establishment to propose promo for admin approval', (
      tester,
    ) async {
      String? proposedTitle;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MerchantPromoProposalSheet(
              establishmentName: 'Boutique Valldemossa',
              onProposed: (title) => proposedTitle = title,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Proponer Promoción'), findsOneWidget);
      expect(
        find.text('Sujeta a aprobación por administración (HU-14)'),
        findsOneWidget,
      );

      // Enviar propuesta
      await tester.tap(find.text('Enviar Propuesta al Administrador'));
      await tester.pumpAndSettle();

      expect(find.text('¡Propuesta Registrada!'), findsOneWidget);
      expect(find.text('ESTADO: PENDIENTE DE REVISIÓN'), findsOneWidget);
      expect(proposedTitle, isNotNull);
    });
  });

  group('NotificationsSheet Widget', () {
    testWidgets('renders notifications and allows marking as read', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: NotificationsSheet())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notificaciones'), findsOneWidget);
      expect(find.text('Marcar leídas'), findsOneWidget);
      expect(find.text('¡Ganaste 120 puntos!'), findsOneWidget);
    });
  });
}
