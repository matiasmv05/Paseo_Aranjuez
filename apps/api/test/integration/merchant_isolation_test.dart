import 'package:paseo_api/adapters/out/postgres/postgres.dart';
import 'package:paseo_api/application/merchant/ports.dart';
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
    'HU-13: cajero ve solo lo suyo, dueno todo, otro comercio nada',
    () async {
      final customer = await createVerifiedCustomer(db);
      final cashier = await harness.contextFor(demoCashierUserId);
      final owner = await harness.contextFor(demoOwnerUserId);
      final branch = await principalBranchId(db);

      expect(cashier.isCashier, isTrue);
      expect(owner.isOwner, isTrue);

      // Compra registrada por el cajero.
      final cashierPurchase = await harness.registerPurchase().call(
        context: cashier,
        request: contract.RegisterPurchaseRequest(
          ticket: harness.ticketFor(
            customerId: customer.userId,
            branchId: cashier.branchId,
          ),
          grossCents: 10000,
          discountCents: 0,
          netCents: 10000,
          invoiceRef: 'IT-${newId()}',
        ),
        idempotencyKey: newId(),
      );

      // Compra registrada por el dueno en la sucursal principal.
      final ownerPurchase = await harness.registerPurchase().call(
        context: owner,
        request: contract.RegisterPurchaseRequest(
          ticket: harness.ticketFor(
            customerId: customer.userId,
            branchId: branch,
          ),
          grossCents: 20000,
          discountCents: 0,
          netCents: 20000,
          invoiceRef: 'IT-${newId()}',
        ),
        idempotencyKey: newId(),
      );

      final cashierIds = (await harness.listMovements().call(
        context: cashier,
        limit: 100,
      )).items.map((m) => m.id).toSet();
      expect(cashierIds, contains(cashierPurchase.purchase.id));
      expect(cashierIds, isNot(contains(ownerPurchase.purchase.id)));

      final ownerIds = (await harness.listMovements().call(
        context: owner,
        limit: 100,
      )).items.map((m) => m.id).toSet();
      expect(ownerIds, contains(cashierPurchase.purchase.id));
      expect(ownerIds, contains(ownerPurchase.purchase.id));

      // Comercio ajeno (UUID inexistente): la bandeja queda vacia.
      final foreignPage = await harness.listMovements().call(
        context: MerchantContext(
          establishmentId: newId(),
          establishmentName: 'Otro Comercio',
          userId: demoOwnerUserId,
          role: MerchantRole.owner,
        ),
        limit: 100,
      );
      expect(foreignPage.items, isEmpty);
    },
  );
}
