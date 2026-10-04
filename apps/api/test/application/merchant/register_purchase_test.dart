import 'package:paseo_api/adapters/out/auth/identification_signer.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/application/merchant/use_cases/register_purchase.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;
import 'package:test/test.dart';

import 'fakes.dart';

/// Repositorio que simula una carrera: la primera consulta no ve la clave
/// (otro request gana la insercion) y la segunda si la encuentra.
final class _RaceRepository extends FakePurchaseRepository {
  _RaceRepository({required this.existing});

  final Purchase existing;
  int _lookups = 0;

  @override
  Future<Purchase?> findByIdempotencyKey({
    required String establishmentId,
    required String idempotencyKey,
  }) async {
    _lookups++;
    return _lookups == 1 ? null : existing;
  }
}

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

  contract.RegisterPurchaseRequest register({
    required String token,
    int grossCents = 25000,
    int discountCents = 0,
    int netCents = 25000,
    String invoiceRef = 'F-1',
  }) => contract.RegisterPurchaseRequest(
    ticket: token,
    grossCents: grossCents,
    discountCents: discountCents,
    netCents: netCents,
    invoiceRef: invoiceRef,
  );

  RegisterPurchase build({
    required PurchaseRepository purchases,
    List<PointsRule> rules = const [],
  }) => RegisterPurchase(
    signer: signer,
    rules: FakePointsRuleRepository(rules),
    resolver: const RuleResolver(),
    calculator: const PointsCalculator(),
    purchases: purchases,
    clock: FixedClock(now),
  );

  Purchase winner() => Purchase(
    id: 'p-race',
    establishmentId: 'est-1',
    branchId: 'br-1',
    customerId: 'c-1',
    sellerUserId: 'u-owner',
    grossCents: 25000,
    discountCents: 0,
    netCents: 25000,
    invoiceRef: 'F-RACE',
    ruleId: 'base-1',
    campaignRuleId: null,
    ruleSnapshot: const {},
    idempotencyKey: 'k-race',
    pointsCredited: 25,
    createdAt: now,
  );

  group('RegisterPurchase (HU-11, FR-009/FR-016)', () {
    test(
      'crea la compra y devuelve 201 con los puntos y el snapshot',
      () async {
        final purchases = FakePurchaseRepository(createdAt: now);

        final outcome =
            await build(purchases: purchases, rules: [pointsRule()])(
              context: owner,
              request: register(token: ticket()),
              idempotencyKey: 'k-1',
            );

        expect(outcome.created, isTrue);
        expect(outcome.purchase.id, 'p-1');
        expect(outcome.purchase.pointsCredited, 25);
        expect(outcome.purchase.invoiceRef, 'F-1');
        expect(purchases.insertions, hasLength(1));
        final snapshot = purchases.insertions.single.ruleSnapshot;
        expect(snapshot['base'], isA<Map<String, Object?>>());
        expect(
          (snapshot['base']! as Map<String, Object?>)['points_awarded'],
          10,
        );
      },
    );

    test(
      'replay con la misma Idempotency-Key no vuelve a insertar (§9)',
      () async {
        final purchases = FakePurchaseRepository(createdAt: now);
        final useCase = build(purchases: purchases, rules: [pointsRule()]);

        final first = await useCase(
          context: owner,
          request: register(token: ticket()),
          idempotencyKey: 'k-1',
        );
        final second = await useCase(
          context: owner,
          request: register(token: ticket()),
          idempotencyKey: 'k-1',
        );

        expect(first.created, isTrue);
        expect(second.created, isFalse);
        expect(second.purchase.id, first.purchase.id);
        expect(purchases.insertions, hasLength(1));
      },
    );

    test('factura repetida -> DUPLICATE_INVOICE (FR-016)', () async {
      final purchases = FakePurchaseRepository(createdAt: now);
      final useCase = build(purchases: purchases, rules: [pointsRule()]);

      await useCase(
        context: owner,
        request: register(token: ticket()),
        idempotencyKey: 'k-1',
      );

      await expectLater(
        useCase(
          context: owner,
          request: register(token: ticket()),
          idempotencyKey: 'k-2',
        ),
        throwsA(
          isA<LoyaltyException>().having(
            (error) => error.code,
            'code',
            contract.ApiErrorCode.duplicateInvoice,
          ),
        ),
      );
      expect(purchases.insertions, hasLength(1));
    });

    test(
      'violacion 23505 de invoice_ref en carrera -> DUPLICATE_INVOICE',
      () async {
        final purchases = FakePurchaseRepository(createdAt: now)
          ..nextViolation = const PurchaseUniqueViolation(
            PurchaseUniqueField.invoiceRef,
          );

        await expectLater(
          build(purchases: purchases, rules: [pointsRule()])(
            context: owner,
            request: register(token: ticket()),
            idempotencyKey: 'k-1',
          ),
          throwsA(
            isA<LoyaltyException>().having(
              (error) => error.code,
              'code',
              contract.ApiErrorCode.duplicateInvoice,
            ),
          ),
        );
      },
    );

    test(
      'violacion 23505 de idempotency_key en carrera -> replay 200',
      () async {
        final purchases = _RaceRepository(existing: winner())
          ..nextViolation = const PurchaseUniqueViolation(
            PurchaseUniqueField.idempotencyKey,
          );

        final outcome =
            await build(purchases: purchases, rules: [pointsRule()])(
              context: owner,
              request: register(token: ticket(), invoiceRef: 'F-RACE'),
              idempotencyKey: 'k-race',
            );

        expect(outcome.created, isFalse);
        expect(outcome.purchase.id, 'p-race');
      },
    );

    test('bajo la compra minima registra con 0 puntos sin ledger', () async {
      final purchases = FakePurchaseRepository(createdAt: now);

      final outcome =
          await build(
            purchases: purchases,
            rules: [pointsRule(minPurchaseCents: 30000)],
          )(
            context: owner,
            request: register(token: ticket()),
            idempotencyKey: 'k-1',
          );

      expect(outcome.created, isTrue);
      expect(outcome.purchase.pointsCredited, 0);
    });

    test('montos inconsistentes -> VALIDATION_FAILED', () async {
      await expectLater(
        build(purchases: FakePurchaseRepository(), rules: [pointsRule()])(
          context: owner,
          request: register(token: ticket(), netCents: 9000),
          idempotencyKey: 'k-1',
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

    test('invoice_ref vacia -> VALIDATION_FAILED', () async {
      await expectLater(
        build(purchases: FakePurchaseRepository(), rules: [pointsRule()])(
          context: owner,
          request: register(token: ticket(), invoiceRef: '   '),
          idempotencyKey: 'k-1',
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

    test('sin sucursal atribuible -> VALIDATION_FAILED (§10.1)', () async {
      await expectLater(
        build(purchases: FakePurchaseRepository(), rules: [pointsRule()])(
          context: owner,
          request: register(token: ticket(branchId: null)),
          idempotencyKey: 'k-1',
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
        build(purchases: FakePurchaseRepository(), rules: [pointsRule()])(
          context: owner,
          request: register(token: ticket(establishmentId: 'est-2')),
          idempotencyKey: 'k-1',
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
          build(purchases: FakePurchaseRepository(), rules: [pointsRule()])(
            context: cashier,
            request: register(token: ticket(branchId: 'br-2')),
            idempotencyKey: 'k-1',
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
  });
}
