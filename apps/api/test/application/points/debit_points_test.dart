import 'package:paseo_api/application/points/debit_points.dart';
import 'package:paseo_api/domain/points/points.dart';
import 'package:paseo_shared/paseo_shared.dart';
import 'package:test/test.dart';

import '../identity/fakes.dart' show FakeTransactionRunner, FixedClock;
import 'fakes.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakePointsIdempotencyRepository idempotency;
  late RecordingAuditLogWriter audit;
  late FakeTransactionRunner tx;
  late DebitPoints debit;

  const customerId = 'cust-1';
  const idempotencyKey = 'd-1';
  const requestHash = 'hash-1';
  final occurredAt = DateTime.utc(2026, 1, 1, 12);

  setUp(() {
    ledger = FakeLedgerRepository();
    idempotency = FakePointsIdempotencyRepository();
    audit = RecordingAuditLogWriter();
    tx = FakeTransactionRunner();
    debit = DebitPoints(
      ledger: ledger,
      idempotency: idempotency,
      audit: audit,
      tx: tx,
      clock: FixedClock(occurredAt),
    );
  });

  group('DebitPoints (HUT-04, FR-005/FR-006/FR-008, SEC-002)', () {
    test('pv=false rechaza y no toca base ni idempotencia', () async {
      await expectLater(
        debit(
          customerId: customerId,
          command: DebitCommand(points: 70, reference: 'rw-1'),
          phoneVerified: false,
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
      expect(ledger.debitInserts, isEmpty);
      expect(idempotency.entries, isEmpty);
      expect(audit.calls, isEmpty);
    });

    test('debito OK: REDEEM + idempotencia + audit', () async {
      ledger.seedBalance(100);

      final result = await debit(
        customerId: customerId,
        command: DebitCommand(points: 70, reference: 'rw-1'),
        phoneVerified: true,
        idempotencyKey: idempotencyKey,
        requestHash: requestHash,
      );

      expect(result.replayed, isFalse);
      expect(result.balanceAfter, 30);
      expect(ledger.debitInserts, hasLength(1));
      expect(ledger.debitInserts.single['points'], 70);
      final entry = idempotency.entries['points.debit|$idempotencyKey']!;
      expect(entry.response['balance_after'], 30);
      final call = audit.lastWhere('points.debit')!;
      expect(call['entityId'], result.ledgerId);
      expect(call['entityType'], 'points_ledger');
    });

    test('debito > saldo: INSUFFICIENT_POINTS propagado; revierte', () async {
      ledger.seedBalance(50);

      await expectLater(
        debit(
          customerId: customerId,
          command: DebitCommand(points: 70, reference: 'rw-1'),
          phoneVerified: true,
          idempotencyKey: idempotencyKey,
          requestHash: requestHash,
        ),
        throwsA(
          isA<PointsException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.insufficientPoints,
          ),
        ),
      );
      expect(tx.rolledBack, isTrue);
      expect(audit.calls, isEmpty);
    });

    test('misma key + mismo payload: replay sin segundo REDEEM', () async {
      ledger.seedBalance(100);

      final first = await debit(
        customerId: customerId,
        command: DebitCommand(points: 70, reference: 'rw-1'),
        phoneVerified: true,
        idempotencyKey: idempotencyKey,
        requestHash: requestHash,
      );
      final second = await debit(
        customerId: customerId,
        command: DebitCommand(points: 70, reference: 'rw-1'),
        phoneVerified: true,
        idempotencyKey: idempotencyKey,
        requestHash: requestHash,
      );

      expect(second.ledgerId, first.ledgerId);
      expect(second.balanceAfter, first.balanceAfter);
      expect(second.replayed, isTrue);
      expect(ledger.debitInserts, hasLength(1));
    });

    test('misma key + payload distinto: 409 CONFLICT', () async {
      ledger.seedBalance(100);
      await debit(
        customerId: customerId,
        command: DebitCommand(points: 70, reference: 'rw-1'),
        phoneVerified: true,
        idempotencyKey: idempotencyKey,
        requestHash: requestHash,
      );

      await expectLater(
        debit(
          customerId: customerId,
          command: DebitCommand(points: 30, reference: 'rw-1'),
          phoneVerified: true,
          idempotencyKey: idempotencyKey,
          requestHash: 'distinto',
        ),
        throwsA(
          isA<PointsException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.conflict,
          ),
        ),
      );
      expect(ledger.debitInserts, hasLength(1));
    });

    test(
      'puntos <= 0 se rechazan antes de tocar la base (ArgumentError)',
      () async {
        // La guarda vive en el dominio: el comando rechaza puntos <= 0 al
        // construirse, antes de que el caso de uso toque nada.
        expect(
          () => DebitCommand(points: 0, reference: 'rw-1'),
          throwsArgumentError,
        );
        expect(ledger.debitInserts, isEmpty);
      },
    );
  });
}
