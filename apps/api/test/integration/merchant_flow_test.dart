import 'package:paseo_api/adapters/out/postgres/postgres.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/application/merchant/use_cases/identify_customer.dart';
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
    'HU-10 + HU-11 + HU-13: identificar, comprar, acreditar y listar',
    () async {
      final customer = await createVerifiedCustomer(db);
      final tableContext = await harness.contextFor(demoCashierUserId);

      expect(tableContext.role, MerchantRole.cashier);
      expect(tableContext.establishmentId, demoEstablishmentId);
      expect(tableContext.establishmentName, demoEstablishmentName);
      expect(tableContext.branchId, isNotNull);

      // HU-10: identificar por telefono devuelve ticket y nombre enmascarado.
      final identified = await harness.identifyCustomer().call(
        context: tableContext,
        input: IdentifyByPhone(customer.phone),
      );
      expect(identified.customerName, 'Ana T. Q.');
      expect(identified.ticket, isNotEmpty);
      expect(identified.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);

      // HU-10: identificar por QR usa el mismo camino de cliente verificado.
      final byQr = await harness.identifyCustomer().call(
        context: tableContext,
        input: IdentifyByQr(harness.qrFor(customer.userId)),
      );
      expect(byQr.customerName, 'Ana T. Q.');

      // HU-11: registrar la compra con el ticket por telefono.
      final invoice = 'IT-${newId()}';
      final before = await balanceOf(db, customer.userId) ?? 0;
      final outcome = await harness.registerPurchase().call(
        context: tableContext,
        request: contract.RegisterPurchaseRequest(
          ticket: identified.ticket,
          grossCents: 10000,
          discountCents: 0,
          netCents: 10000,
          invoiceRef: invoice,
        ),
        idempotencyKey: newId(),
      );

      expect(outcome.created, isTrue);
      expect(outcome.purchase.invoiceRef, invoice);
      // Regla GLOBAL del seed: 10 puntos por tramo de 10000 centavos.
      expect(outcome.purchase.pointsCredited, 10);

      // El trigger acredita el saldo; el ledger tiene un CREDIT.
      final after = await balanceOf(db, customer.userId);
      expect(after, before + 10);
      expect(await creditCountForPurchase(db, outcome.purchase.id), 1);

      // HU-13: el cajero ve su movimiento en la bandeja.
      final page = await harness.listMovements().call(
        context: tableContext,
        limit: 100,
      );
      final found = page.items.where((m) => m.id == outcome.purchase.id);
      expect(found, hasLength(1));
      expect(found.first.invoiceRef, invoice);
      expect(found.first.customerName, 'Ana T. Q.');
      expect(found.first.pointsCredited, 10);
    },
  );
}
