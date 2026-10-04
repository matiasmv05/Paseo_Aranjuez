import 'package:paseo_api/adapters/out/postgres/postgres.dart';
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
    'HU-11: misma Idempotency-Key acredita una sola vez (200 replay)',
    () async {
      final customer = await createVerifiedCustomer(db);
      final context = await harness.contextFor(demoCashierUserId);
      final ticket = harness.ticketFor(
        customerId: customer.userId,
        branchId: context.branchId,
      );

      final key = newId();
      final invoice = 'IT-${newId()}';
      final first = await harness.registerPurchase().call(
        context: context,
        request: contract.RegisterPurchaseRequest(
          ticket: ticket,
          grossCents: 10000,
          discountCents: 0,
          netCents: 10000,
          invoiceRef: invoice,
        ),
        idempotencyKey: key,
      );
      expect(first.created, isTrue);

      final balanceAfterFirst = await balanceOf(db, customer.userId);
      expect(balanceAfterFirst, 10);

      // Replay identico: no vuelve a mover el ledger ni crea otra compra.
      final replay = await harness.registerPurchase().call(
        context: context,
        request: contract.RegisterPurchaseRequest(
          ticket: ticket,
          grossCents: 10000,
          discountCents: 0,
          netCents: 10000,
          invoiceRef: invoice,
        ),
        idempotencyKey: key,
      );
      expect(replay.created, isFalse);
      expect(replay.purchase.id, first.purchase.id);

      // Replay con cuerpo distinto: la clave manda; devuelve la original.
      final replayDifferentBody = await harness.registerPurchase().call(
        context: context,
        request: contract.RegisterPurchaseRequest(
          ticket: ticket,
          grossCents: 99999,
          discountCents: 0,
          netCents: 99999,
          invoiceRef: 'IT-${newId()}',
        ),
        idempotencyKey: key,
      );
      expect(replayDifferentBody.created, isFalse);
      expect(replayDifferentBody.purchase.id, first.purchase.id);
      expect(replayDifferentBody.purchase.netCents, 10000);

      expect(await purchaseCountByKey(db, demoEstablishmentId, key), 1);
      expect(await creditCountForPurchase(db, first.purchase.id), 1);
      expect(await balanceOf(db, customer.userId), balanceAfterFirst);

      // Clave nueva crea una compra nueva y acredita otra vez.
      final second = await harness.registerPurchase().call(
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
      expect(second.created, isTrue);
      expect(second.purchase.id, isNot(first.purchase.id));
      expect(await balanceOf(db, customer.userId), balanceAfterFirst! + 10);
    },
  );
}
