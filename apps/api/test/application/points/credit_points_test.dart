import 'package:paseo_api/application/points/credit_points.dart';
import 'package:paseo_api/application/points/ports.dart';
import 'package:paseo_api/domain/points/points.dart';
import 'package:paseo_shared/paseo_shared.dart';
import 'package:test/test.dart';

import '../identity/fakes.dart' show FakeTransactionRunner, FixedClock;
import 'fakes.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakePurchaseRepository purchases;
  late FakePointsIdempotencyRepository idempotency;
  late RecordingAuditLogWriter audit;
  late FakeTransactionRunner tx;
  late CreditPoints credit;

  const customerId = 'cust-1';
  const idempotencyKey = 'key-1';
  const requestHash = 'hash-1';
  final occurredAt = DateTime.utc(2026, 1, 1, 12);

  PurchaseInput purchaseInput() => const PurchaseInput(
    establishmentId: 'est-1',
    branchId: 'br-1',
    customerId: customerId,
    grossCents: 12000,
    discountCents: 0,
    netCents: 12000,
    invoiceRef: 'FAC-1',
    idempotencyKey: idempotencyKey,
  );

  setUp(() {
    ledger = FakeLedgerRepository();
    purchases = FakePurchaseRepository();
    idempotency = FakePointsIdempotencyRepository();
    audit = RecordingAuditLogWriter();
    tx = FakeTransactionRunner();
    credit = CreditPoints(
      ledger: ledger,
      idempotency: idempotency,
      purchases: purchases,
      audit: audit,
      tx: tx,
      clock: FixedClock(occurredAt),
    );
  });

  group('CreditPoints (HUT-04, FR-005/FR-006/FR-008, SEC-002)', () {
    test('pv=false rechaza y no toca base ni idempotencia', () async {
      await expectLater(
        credit(
          customerId: customerId,
          command: CreditCommand(points: 120, reference: 'FAC-1'),
          phoneVerified: false,
          purchaseInput: purchaseInput(),
          idempotencyKey: idempotencyKey,
          requestHash: requestHash,
        ),
        throwsA(
          isA<PointsException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.phoneNotVerified,
          ),
        ),
      );
      expect(ledger.creditInserts, isEmpty);
      expect(purchases.inserted, isEmpty);
      expect(idempotency.entries, isEmpty);
      expect(audit.calls, isEmpty);
    });

    test(
      'credito OK: compra + CREDIT + idempotencia + audit, en una tx',
      () async {
        final result = await credit(
          customerId: customerId,
          command: CreditCommand(points: 120, reference: 'FAC-1'),
          phoneVerified: true,
          purchaseInput: purchaseInput(),
          idempotencyKey: idempotencyKey,
          requestHash: requestHash,
        );

        expect(result.ledgerId, 'ledger-1');
        expect(result.balanceAfter, 120);
        expect(result.replayed, isFalse);
        // Compra insertada una vez con los montos enteros.
        expect(purchases.inserted, hasLength(1));
        expect(purchases.inserted.single.netCents, 12000);
        // Ledger: un solo CREDIT con la clave.
        expect(ledger.creditInserts, hasLength(1));
        expect(ledger.creditInserts.single['idempotencyKey'], idempotencyKey);
        expect(ledger.creditInserts.single['purchaseId'], isNotNull);
        // Respuesta guardada para replay.
        final entry = idempotency.entries['points.credit|$idempotencyKey']!;
        expect(entry.requestHash, requestHash);
        expect(entry.ledgerId, 'ledger-1');
        expect(entry.response, {
          'ledger_id': 'ledger-1',
          'balance_after': 120,
          'occurred_at': occurredAt.toIso8601String(),
        });
        // Auditoria de la escritura (sin PII: entityId es el ledger id).
        final call = audit.lastWhere('points.credit')!;
        expect(call['entityId'], 'ledger-1');
        expect(call['entityType'], 'points_ledger');
        expect(call['userId'], customerId);
      },
    );

    test('misma key + mismo payload: replay sin segundo CREDIT', () async {
      final first = await credit(
        customerId: customerId,
        command: CreditCommand(points: 120, reference: 'FAC-1'),
        phoneVerified: true,
        purchaseInput: purchaseInput(),
        idempotencyKey: idempotencyKey,
        requestHash: requestHash,
      );

      final second = await credit(
        customerId: customerId,
        command: CreditCommand(points: 120, reference: 'FAC-1'),
        phoneVerified: true,
        purchaseInput: purchaseInput(),
        idempotencyKey: idempotencyKey,
        requestHash: requestHash,
      );

      expect(second.ledgerId, first.ledgerId);
      expect(second.balanceAfter, first.balanceAfter);
      expect(second.replayed, isTrue);
      expect(ledger.creditInserts, hasLength(1));
      expect(purchases.inserted, hasLength(1));
    });

    test('misma key + payload distinto: 409 CONFLICT', () async {
      await credit(
        customerId: customerId,
        command: CreditCommand(points: 120, reference: 'FAC-1'),
        phoneVerified: true,
        purchaseInput: purchaseInput(),
        idempotencyKey: idempotencyKey,
        requestHash: requestHash,
      );

      await expectLater(
        credit(
          customerId: customerId,
          command: CreditCommand(points: 999, reference: 'FAC-1'),
          phoneVerified: true,
          purchaseInput: purchaseInput(),
          idempotencyKey: idempotencyKey,
          requestHash: 'hash-distinto',
        ),
        throwsA(
          isA<PointsException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.conflict,
          ),
        ),
      );
      expect(ledger.creditInserts, hasLength(1));
    });

    test('fallo a mitad de transaccion revierte TODO (sin rastro)', () async {
      ledger.failNextInsert = StateError('boom');

      await expectLater(
        credit(
          customerId: customerId,
          command: CreditCommand(points: 120, reference: 'FAC-1'),
          phoneVerified: true,
          purchaseInput: purchaseInput(),
          idempotencyKey: idempotencyKey,
          requestHash: requestHash,
        ),
        throwsA(isA<StateError>()),
      );

      expect(tx.rolledBack, isTrue);
      // El fake no mantiene saldo en este path (el trigger real aborta).
      expect(audit.calls, isEmpty);
    });

    test(
      'credito sin compra (purchaseInput null) solo inserta el CREDIT',
      () async {
        final result = await credit(
          customerId: customerId,
          command: CreditCommand(points: 50, reference: 'BONUS-1'),
          phoneVerified: true,
          idempotencyKey: idempotencyKey,
          requestHash: requestHash,
        );

        expect(result.balanceAfter, 50);
        expect(purchases.inserted, isEmpty);
        expect(ledger.creditInserts.single['purchaseId'], isNull);
      },
    );

    test(
      'puntos <= 0 se rechazan antes de tocar la base (ArgumentError)',
      () async {
        // La guarda vive en el dominio: el comando rechaza puntos <= 0 al
        // construirse, antes de que el caso de uso toque nada.
        expect(
          () => CreditCommand(points: 0, reference: 'FAC-1'),
          throwsArgumentError,
        );
        expect(ledger.creditInserts, isEmpty);
      },
    );
  });
}
