import 'package:paseo_api/adapters/out/postgres/postgres.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;
import 'package:test/test.dart';

import 'merchant_support.dart';
import 'support.dart';

void main() {
  late PgDatabase db;
  late MerchantHarness harness;

  setUpAll(() async {
    db = await PgDatabase.open(integrationConfig());
    harness = MerchantHarness(db);
  });

  tearDownAll(() async {
    await db.close();
  });

  test(
    'HU-11: preview y registro usan la misma regla y el preview no escribe',
    () async {
      final customer = await createVerifiedCustomer(db);
      final context = await harness.contextFor(demoCashierUserId);
      final ticket = harness.ticketFor(
        customerId: customer.userId,
        branchId: context.branchId,
      );

      final before = await balanceOf(db, customer.userId) ?? 0;
      final preview = await harness.previewPurchase().call(
        context: context,
        request: contract.PreviewPurchaseRequest(
          ticket: ticket,
          grossCents: 10000,
          discountCents: 0,
          netCents: 10000,
        ),
      );

      expect(preview.ruleId, demoGlobalRuleId);
      expect(preview.campaignRuleId, isNull);
      expect(preview.points, 10);
      expect(preview.breakdown.pointsBase, 10);
      expect(preview.breakdown.multiplierBp, 10000);
      expect(preview.breakdown.rounding, contract.Rounding.floor);
      expect(preview.breakdown.belowMinPurchase, isFalse);
      expect(preview.breakdown.capApplied, isFalse);
      expect(await balanceOf(db, customer.userId) ?? 0, before);

      final registered = await harness.registerPurchase().call(
        context: context,
        request: contract.RegisterPurchaseRequest(
          ticket: ticket,
          grossCents: 10000,
          discountCents: 0,
          netCents: 10000,
          invoiceRef: 'IT-${newId()}',
        ),
        idempotencyKey: newId(),
      );
      expect(registered.purchase.pointsCredited, preview.points);
      expect(registered.purchase.ruleId, preview.ruleId);
    },
  );

  test('HU-11: factura repetida en el comercio es DUPLICATE_INVOICE', () async {
    final customer = await createVerifiedCustomer(db);
    final context = await harness.contextFor(demoCashierUserId);
    final ticket = harness.ticketFor(
      customerId: customer.userId,
      branchId: context.branchId,
    );
    final invoice = 'IT-${newId()}';

    await harness.registerPurchase().call(
      context: context,
      request: contract.RegisterPurchaseRequest(
        ticket: ticket,
        grossCents: 10000,
        discountCents: 0,
        netCents: 10000,
        invoiceRef: invoice,
      ),
      idempotencyKey: newId(),
    );

    await expectLater(
      harness.registerPurchase().call(
        context: context,
        request: contract.RegisterPurchaseRequest(
          ticket: ticket,
          grossCents: 10000,
          discountCents: 0,
          netCents: 10000,
          invoiceRef: invoice,
        ),
        idempotencyKey: newId(),
      ),
      throwsA(
        isA<LoyaltyException>().having(
          (e) => e.code,
          'code',
          contract.ApiErrorCode.duplicateInvoice,
        ),
      ),
    );
  });

  test(
    'HU-11: sin regla aplicable es NO_APPLICABLE_RULE y no escribe',
    () async {
      final customer = await createVerifiedCustomer(db);
      final context = await harness.contextFor(demoCashierUserId);
      final ticket = harness.ticketFor(
        customerId: customer.userId,
        branchId: context.branchId,
      );

      await expectLater(
        harness
            .registerPurchase(rules: const StubPointsRuleRepository([]))
            .call(
              context: context,
              request: contract.RegisterPurchaseRequest(
                ticket: ticket,
                grossCents: 10000,
                discountCents: 0,
                netCents: 10000,
                invoiceRef: 'IT-${newId()}',
              ),
              idempotencyKey: newId(),
            ),
        throwsA(
          isA<LoyaltyException>().having(
            (e) => e.code,
            'code',
            contract.ApiErrorCode.noApplicableRule,
          ),
        ),
      );
      expect(await balanceOf(db, customer.userId), isNull);
    },
  );

  test('HU-11: compra bajo la minima no crea fila en el ledger', () async {
    final customer = await createVerifiedCustomer(db);
    final context = await harness.contextFor(demoCashierUserId);
    final ticket = harness.ticketFor(
      customerId: customer.userId,
      branchId: context.branchId,
    );

    // Misma id real (FK `purchases.rule_id`) pero minimo alto: la compra
    // neta de 1000 centavos queda bajo la minima y no acredita.
    final belowMin = PointsRule(
      id: demoGlobalRuleId,
      scope: PointsRuleScope.global,
      type: PointsRuleType.base,
      priority: 100,
      pointsAwarded: 10,
      amountPerTierCents: 10000,
      multiplierBp: 10000,
      maxPointsPerPurchase: null,
      minPurchaseCents: 5000,
      rounding: Rounding.floor,
      validFrom: DateTime.utc(2020),
    );

    final outcome = await harness
        .registerPurchase(rules: StubPointsRuleRepository([belowMin]))
        .call(
          context: context,
          request: contract.RegisterPurchaseRequest(
            ticket: ticket,
            grossCents: 1000,
            discountCents: 0,
            netCents: 1000,
            invoiceRef: 'IT-${newId()}',
          ),
          idempotencyKey: newId(),
        );

    expect(outcome.created, isTrue);
    expect(outcome.purchase.pointsCredited, 0);
    expect(await creditCountForPurchase(db, outcome.purchase.id), 0);
    expect(await balanceOf(db, customer.userId), isNull);
  });
}
