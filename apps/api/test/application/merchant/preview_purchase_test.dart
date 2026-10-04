import 'package:paseo_api/adapters/out/auth/identification_signer.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/application/merchant/use_cases/preview_purchase.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  final now = DateTime.utc(2026, 10, 3, 12);
  const signer = IdentificationSigner(secret: 'test-secret');

  const owner = MerchantContext(
    establishmentId: 'est-1',
    establishmentName: 'Paseo',
    userId: 'u-owner',
    role: MerchantRole.owner,
  );
  const cashier = MerchantContext(
    establishmentId: 'est-1',
    establishmentName: 'Paseo',
    userId: 'u-cashier',
    role: MerchantRole.cashier,
    branchId: 'br-1',
    branchName: 'Principal',
  );

  String ticket({
    String establishmentId = 'est-1',
    String? branchId = 'br-1',
    DateTime? expiresAt,
  }) => signer.signTicket(
    IdentificationTicketClaims(
      customerId: 'c-1',
      establishmentId: establishmentId,
      branchId: branchId,
      issuedAt: now,
      expiresAt: expiresAt ?? now.add(IdentificationTicketClaims.ttl),
    ),
  );

  contract.PreviewPurchaseRequest request({
    required String token,
    int grossCents = 25000,
    int discountCents = 0,
    int netCents = 25000,
  }) => contract.PreviewPurchaseRequest(
    ticket: token,
    grossCents: grossCents,
    discountCents: discountCents,
    netCents: netCents,
  );

  PreviewPurchase build(List<PointsRule> rules) => PreviewPurchase(
    signer: signer,
    rules: FakePointsRuleRepository(rules),
    resolver: const RuleResolver(),
    calculator: const PointsCalculator(),
    clock: FixedClock(now),
  );

  group('PreviewPurchase (HU-11, FR-012)', () {
    test('calcula el desglose completo sin escribir (FR-013)', () async {
      final result = await build([pointsRule()])(
        context: owner,
        request: request(token: ticket()),
      );

      expect(result.points, 25);
      expect(result.ruleId, 'base-1');
      expect(result.campaignRuleId, isNull);
      expect(result.breakdown.pointsBase, 25);
      expect(result.breakdown.multiplierBp, 0);
      expect(result.breakdown.pointsAfterMultiplier, 25);
      expect(result.breakdown.capApplied, isFalse);
      expect(result.breakdown.belowMinPurchase, isFalse);
      expect(result.breakdown.rounding, contract.Rounding.floor);
    });

    test('aplica la campana y expone campaign_rule_id', () async {
      final rules = [
        pointsRule(),
        pointsRule(
          id: 'camp-1',
          type: PointsRuleType.campaign,
          scope: PointsRuleScope.global,
          establishmentId: null,
          multiplierBp: 20000,
        ),
      ];

      final result = await build(rules)(
        context: owner,
        request: request(token: ticket()),
      );

      expect(result.points, 50);
      expect(result.campaignRuleId, 'camp-1');
      expect(result.breakdown.pointsAfterMultiplier, 50);
    });

    test('aplica el tope mas bajo de base y campana', () async {
      final rules = [
        pointsRule(maxPointsPerPurchase: 10),
        pointsRule(
          id: 'camp-1',
          type: PointsRuleType.campaign,
          scope: PointsRuleScope.global,
          establishmentId: null,
          multiplierBp: 20000,
        ),
      ];

      final result = await build(rules)(
        context: owner,
        request: request(token: ticket()),
      );

      expect(result.points, 10);
      expect(result.breakdown.capApplied, isTrue);
      expect(result.breakdown.pointsBeforeCap, 50);
    });

    test('bajo la compra minima los puntos son 0', () async {
      final result = await build([pointsRule(minPurchaseCents: 30000)])(
        context: owner,
        request: request(token: ticket()),
      );

      expect(result.points, 0);
      expect(result.breakdown.belowMinPurchase, isTrue);
      expect(result.breakdown.pointsBase, 25);
    });

    test('sin regla aplicable -> NO_APPLICABLE_RULE (§7)', () async {
      await expectLater(
        build(const [])(
          context: owner,
          request: request(token: ticket()),
        ),
        throwsA(
          isA<LoyaltyException>().having(
            (error) => error.code,
            'code',
            contract.ApiErrorCode.noApplicableRule,
          ),
        ),
      );
    });

    test('montos inconsistentes -> VALIDATION_FAILED (§7)', () async {
      await expectLater(
        build([pointsRule()])(
          context: owner,
          request: request(token: ticket(), netCents: 9000),
        ),
        throwsA(
          isA<LoyaltyException>().having(
            (error) => error.code,
            'code',
            contract.ApiErrorCode.validationFailed,
          ),
        ),
      );
    });

    test('ticket de otro comercio -> INVALID_IDENTIFICATION_TICKET', () async {
      await expectLater(
        build([pointsRule()])(
          context: owner,
          request: request(token: ticket(establishmentId: 'est-2')),
        ),
        throwsA(
          isA<LoyaltyException>().having(
            (error) => error.code,
            'code',
            contract.ApiErrorCode.invalidIdentificationTicket,
          ),
        ),
      );
    });

    test('ticket vencido -> INVALID_IDENTIFICATION_TICKET', () async {
      await expectLater(
        build([pointsRule()])(
          context: owner,
          request: request(token: ticket(expiresAt: now)),
        ),
        throwsA(
          isA<LoyaltyException>().having(
            (error) => error.code,
            'code',
            contract.ApiErrorCode.invalidIdentificationTicket,
          ),
        ),
      );
    });

    test(
      'cajero con ticket de otra sucursal -> INVALID_IDENTIFICATION_TICKET',
      () async {
        await expectLater(
          build([pointsRule()])(
            context: cashier,
            request: request(token: ticket(branchId: 'br-2')),
          ),
          throwsA(
            isA<LoyaltyException>().having(
              (error) => error.code,
              'code',
              contract.ApiErrorCode.invalidIdentificationTicket,
            ),
          ),
        );
      },
    );

    test('cajero con su propia sucursal previsualiza', () async {
      final result = await build([pointsRule()])(
        context: cashier,
        request: request(token: ticket()),
      );
      expect(result.points, 25);
    });
  });
}
