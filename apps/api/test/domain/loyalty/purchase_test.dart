import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:paseo_shared/paseo_shared.dart' show ApiErrorCode;
import 'package:test/test.dart';

void main() {
  PurchaseDraft draft({
    int grossCents = 10000,
    int discountCents = 0,
    int netCents = 10000,
    String invoiceRef = 'F-001',
    int pointsCredited = 10,
    String idempotencyKey = 'key-1',
  }) => PurchaseDraft(
    establishmentId: 'est-1',
    branchId: 'br-1',
    customerId: 'cust-1',
    sellerUserId: 'seller-1',
    grossCents: grossCents,
    discountCents: discountCents,
    netCents: netCents,
    invoiceRef: invoiceRef,
    ruleId: 'rule-1',
    campaignRuleId: null,
    ruleSnapshot: const {'id': 'rule-1'},
    idempotencyKey: idempotencyKey,
    pointsCredited: pointsCredited,
  );

  group('PurchaseDraft (FR-016)', () {
    test('acepta una compra coherente y normaliza invoice_ref', () {
      final result = draft(
        grossCents: 10000,
        discountCents: 2000,
        netCents: 8000,
      );
      expect(result.netCents, 8000);
      expect(result.invoiceRef, 'F-001');
    });

    test('recorta espacios de invoice_ref', () {
      expect(draft(invoiceRef: '  F-9  ').invoiceRef, 'F-9');
    });

    test('rechaza net != gross - discount', () {
      expect(
        () => draft(grossCents: 10000, discountCents: 2000, netCents: 9000),
        throwsA(_validationFailure()),
      );
    });

    test('rechaza montos negativos', () {
      expect(
        () => draft(grossCents: -1, discountCents: 0, netCents: -1),
        throwsA(_validationFailure()),
      );
    });

    test('rechaza invoice_ref vacio', () {
      expect(() => draft(invoiceRef: '   '), throwsA(_validationFailure()));
    });

    test('rechaza points_credited negativo', () {
      expect(() => draft(pointsCredited: -1), throwsA(_validationFailure()));
    });

    test('rechaza Idempotency-Key vacia', () {
      expect(() => draft(idempotencyKey: '  '), throwsA(_validationFailure()));
    });
  });

  group('Purchase (lectura)', () {
    Purchase purchase({
      int grossCents = 10000,
      int discountCents = 0,
      int netCents = 10000,
      String invoiceRef = 'F-001',
    }) => Purchase(
      id: 'p-1',
      establishmentId: 'est-1',
      branchId: 'br-1',
      customerId: 'cust-1',
      sellerUserId: 'seller-1',
      grossCents: grossCents,
      discountCents: discountCents,
      netCents: netCents,
      invoiceRef: invoiceRef,
      ruleId: 'rule-1',
      campaignRuleId: null,
      ruleSnapshot: const {'id': 'rule-1'},
      idempotencyKey: 'key-1',
      pointsCredited: 10,
      createdAt: DateTime.utc(2025, 1, 1),
    );

    test('construye una compra coherente', () {
      expect(purchase().netCents, 10000);
    });

    test('rechaza net != gross - discount', () {
      expect(() => purchase(netCents: 1), throwsA(_validationFailure()));
    });

    test('rechaza invoice_ref vacio', () {
      expect(() => purchase(invoiceRef: ''), throwsA(_validationFailure()));
    });
  });
}

Matcher _validationFailure() => isA<LoyaltyException>().having(
  (e) => e.code,
  'code',
  ApiErrorCode.validationFailed,
);
