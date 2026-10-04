import 'package:paseo_api/adapters/out/postgres/postgres.dart';
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

  test('HUT-02: identify + purchase bajo los umbrales de latencia', () async {
    final customer = await createVerifiedCustomer(db);
    final context = await harness.contextFor(demoCashierUserId);

    Future<Duration> once() async {
      final watch = Stopwatch()..start();
      final identified = await harness.identifyCustomer().call(
        context: context,
        input: IdentifyByPhone(customer.phone),
      );
      await harness.registerPurchase().call(
        context: context,
        request: contract.RegisterPurchaseRequest(
          ticket: identified.ticket,
          grossCents: 10000,
          discountCents: 0,
          netCents: 10000,
          invoiceRef: 'IT-${newId()}',
        ),
        idempotencyKey: newId(),
      );
      watch.stop();
      return watch.elapsed;
    }

    // Calentamiento: primer acceso a la base fuera de la medicion.
    await once();

    const iterations = 20;
    final samples = <Duration>[];
    final total = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      samples.add(await once());
    }
    total.stop();

    samples.sort();
    final p95 = samples[(0.95 * (samples.length - 1)).round()];
    final totalMs = total.elapsed.inMilliseconds;

    expect(
      total.elapsed,
      lessThan(const Duration(seconds: 3)),
      reason: 'identify+purchase excedio 3s: ${totalMs}ms',
    );
    expect(
      p95,
      lessThan(const Duration(milliseconds: 500)),
      reason: 'p95 excedio 500ms: ${p95.inMilliseconds}ms',
    );
  });
}
