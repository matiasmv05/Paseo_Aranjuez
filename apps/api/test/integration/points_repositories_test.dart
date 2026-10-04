import 'package:paseo_api/adapters/out/clock/system_clock.dart';
import 'package:paseo_api/adapters/out/postgres/postgres.dart';
import 'package:paseo_api/application/points/points.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:paseo_api/domain/points/points.dart';
import 'package:paseo_shared/paseo_shared.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'support.dart';

/// T012: adaptadores Postgres del módulo de puntos contra la base dev
/// (5433, rol `paseo_app`). Escenarios 1–10 y 16 de la asignación HUT-04:
/// crédito, doble crédito, débito, débito > saldo, carrera de débitos,
/// misma referencia dos veces, fallo a mitad de transacción, permisos del
/// ledger (en `ledger_trigger_test.dart`) y lecturas de catálogo/saldo.
void main() {
  late PgDatabase db;
  late PostgresUserRepository users;
  late PostgresCustomerRepository customers;
  late PostgresPointsLedgerRepository ledger;
  late PostgresPointsIdempotencyRepository idempotency;
  late PostgresBalanceRepository balances;
  late PostgresMovementsRepository movements;
  late PostgresRewardsRepository rewards;
  late PostgresEstablishmentsRepository establishments;

  setUpAll(() async {
    db = await PgDatabase.open(integrationConfig());
    users = PostgresUserRepository(db);
    customers = PostgresCustomerRepository(db);
    ledger = PostgresPointsLedgerRepository(db);
    idempotency = PostgresPointsIdempotencyRepository(db);
    balances = PostgresBalanceRepository(db);
    movements = PostgresMovementsRepository(db);
    rewards = PostgresRewardsRepository(db);
    establishments = PostgresEstablishmentsRepository(db);
  });

  tearDownAll(() async {
    await db.close();
  });

  Future<String> newCustomer() async {
    final id = newId();
    await users.insertIfAbsent(
      id: id,
      email: Email.parse(uniqueEmail()),
      passwordHash: r'$argon2id$test',
      role: UserRole.customer,
    );
    await customers.insertIfAbsent(
      CustomerProfile(userId: id, phone: uniquePhone(), fullName: 'T'),
    );
    await customers.markPhoneVerified(userId: id, at: DateTime.now().toUtc());
    return id;
  }

  Future<int> balanceOf(String customerId) async {
    final r = await db.session.execute(
      Sql.named(
        'SELECT balance FROM app.customer_balances '
        'WHERE customer_id = @c::uuid',
      ),
      parameters: {'c': customerId},
    );
    return r.isEmpty ? 0 : r.first[0]! as int;
  }

  Future<int> ledgerCount(String customerId) async {
    final r = await db.session.execute(
      Sql.named(
        'SELECT COUNT(*) FROM app.points_ledger WHERE customer_id = @c::uuid',
      ),
      parameters: {'c': customerId},
    );
    return r.first[0]! as int;
  }

  group('PostgresPointsLedgerRepository + engine', () {
    test(
      '1. crédito OK: compra + CREDIT atómicos, balance_after del trigger',
      () async {
        final customerId = await newCustomer();
        final purchases = PostgresPurchaseRepository(db);
        final engine = CreditPoints(
          ledger: ledger,
          idempotency: idempotency,
          purchases: purchases,
          audit: PostgresAuditLogWriter(db),
          tx: PostgresTransactionRunner(db),
          clock: const SystemClock(),
        );
        final key = 'it-credit-${newId()}';
        final input = PurchaseInput(
          establishmentId: 'e0000000-0000-4000-8000-000000000001',
          branchId: 'b0000000-0000-4000-8000-000000000001',
          customerId: customerId,
          grossCents: 12000,
          discountCents: 0,
          netCents: 12000,
          invoiceRef: 'IT-${newId()}',
          idempotencyKey: key,
        );

        final result = await engine(
          customerId: customerId,
          command: CreditCommand(points: 120, reference: input.invoiceRef!),
          phoneVerified: true,
          idempotencyKey: key,
          requestHash: 'h-$key',
          purchaseInput: input,
        );

        expect(result.replayed, isFalse);
        expect(result.balanceAfter, 120);
        expect(await balanceOf(customerId), 120);
        expect(await ledgerCount(customerId), 1);
      },
    );

    test(
      '2. misma Idempotency-Key → replay de la respuesta, sin 2º CREDIT',
      () async {
        final customerId = await newCustomer();
        final engine = CreditPoints(
          ledger: ledger,
          idempotency: idempotency,
          purchases: PostgresPurchaseRepository(db),
          audit: PostgresAuditLogWriter(db),
          tx: PostgresTransactionRunner(db),
          clock: const SystemClock(),
        );
        final key = 'it-replay-${newId()}';

        final first = await engine(
          customerId: customerId,
          command: CreditCommand(points: 50, reference: 'R1'),
          phoneVerified: true,
          idempotencyKey: key,
          requestHash: 'h-$key',
        );
        final second = await engine(
          customerId: customerId,
          command: CreditCommand(points: 50, reference: 'R1'),
          phoneVerified: true,
          idempotencyKey: key,
          requestHash: 'h-$key',
        );

        expect(second.replayed, isTrue);
        expect(second.ledgerId, first.ledgerId);
        expect(second.balanceAfter, first.balanceAfter);
        expect(await ledgerCount(customerId), 1);
        expect(await balanceOf(customerId), 50);
      },
    );

    test(
      '3. misma key + payload distinto → CONFLICT y nada insertado',
      () async {
        final customerId = await newCustomer();
        final engine = CreditPoints(
          ledger: ledger,
          idempotency: idempotency,
          purchases: PostgresPurchaseRepository(db),
          audit: PostgresAuditLogWriter(db),
          tx: PostgresTransactionRunner(db),
          clock: const SystemClock(),
        );
        final key = 'it-conflict-${newId()}';
        await engine(
          customerId: customerId,
          command: CreditCommand(points: 50, reference: 'R1'),
          phoneVerified: true,
          idempotencyKey: key,
          requestHash: 'h-A',
        );

        await expectLater(
          engine(
            customerId: customerId,
            command: CreditCommand(points: 999, reference: 'R2'),
            phoneVerified: true,
            idempotencyKey: key,
            requestHash: 'h-B',
          ),
          throwsA(
            isA<PointsException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.conflict,
            ),
          ),
        );
        expect(await balanceOf(customerId), 50);
      },
    );

    test('4. débito OK: REDEEM con delta negativo y balance_after', () async {
      final customerId = await newCustomer();
      await ledger.insertCredit(
        customerId: customerId,
        points: 100,
        reference: 'seed',
        occurredAt: DateTime.now().toUtc(),
        idempotencyKey: 'it-dc-${newId()}',
      );

      final res = await ledger.insertDebit(
        customerId: customerId,
        points: 40,
        reference: 'rw-1',
        occurredAt: DateTime.now().toUtc(),
        idempotencyKey: 'it-dd-${newId()}',
      );

      expect(res.balanceAfter, 60);
      expect(await balanceOf(customerId), 60);
    });

    test(
      '5. débito > saldo → 23514 → INSUFFICIENT_POINTS, sin rastro',
      () async {
        final customerId = await newCustomer();
        await ledger.insertCredit(
          customerId: customerId,
          points: 30,
          reference: 'seed',
          occurredAt: DateTime.now().toUtc(),
          idempotencyKey: 'it-ec-${newId()}',
        );

        await expectLater(
          ledger.insertDebit(
            customerId: customerId,
            points: 70,
            reference: 'rw-1',
            occurredAt: DateTime.now().toUtc(),
            idempotencyKey: 'it-ed-${newId()}',
          ),
          throwsA(
            isA<PointsException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.insufficientPoints,
            ),
          ),
        );
        expect(await balanceOf(customerId), 30);
        expect(await ledgerCount(customerId), 1);
      },
    );

    test(
      '6. carrera: dos débitos de 70 sobre saldo 100 → gana uno solo',
      () async {
        final customerId = await newCustomer();
        await ledger.insertCredit(
          customerId: customerId,
          points: 100,
          reference: 'seed',
          occurredAt: DateTime.now().toUtc(),
          idempotencyKey: 'it-fc-${newId()}',
        );

        final a = await PgDatabase.open(integrationConfig());
        final b = await PgDatabase.open(integrationConfig());
        final probe = await PgDatabase.open(integrationConfig());
        try {
          await a.connection.execute('BEGIN');
          await PostgresPointsLedgerRepository(a).insertDebit(
            customerId: customerId,
            points: 70,
            reference: 'rw',
            occurredAt: DateTime.now().toUtc(),
            idempotencyKey: 'it-fa-${newId()}',
          );

          await b.connection.execute('BEGIN');
          final bInsert = PostgresPointsLedgerRepository(b).insertDebit(
            customerId: customerId,
            points: 70,
            reference: 'rw',
            occurredAt: DateTime.now().toUtc(),
            idempotencyKey: 'it-fb-${newId()}',
          );
          // B se bloquea en el upsert del trigger hasta que A confirme.
          for (var i = 0; i < 200; i++) {
            final r = await probe.connection.execute(
              'SELECT count(*) FROM pg_locks WHERE NOT granted',
            );
            if ((r.first[0]! as int) > 0) break;
            await Future<void>.delayed(const Duration(milliseconds: 25));
          }
          await a.connection.execute('COMMIT');

          await expectLater(
            bInsert,
            throwsA(
              isA<PointsException>().having(
                (e) => e.code,
                'code',
                ApiErrorCode.insufficientPoints,
              ),
            ),
          );
          await b.connection.execute('ROLLBACK');

          expect(await balanceOf(customerId), 30);
          expect(await ledgerCount(customerId), 2);
        } finally {
          await probe.close();
          await b.close();
          await a.close();
        }
      },
    );

    test('7. misma referencia externa (idempotency_key del ledger) dos veces → '
        '23505 → CONFLICT, una sola fila', () async {
      final customerId = await newCustomer();
      final key = 'it-g-${newId()}';
      await ledger.insertCredit(
        customerId: customerId,
        points: 10,
        reference: 'FAC-X',
        occurredAt: DateTime.now().toUtc(),
        idempotencyKey: key,
      );

      await expectLater(
        ledger.insertCredit(
          customerId: customerId,
          points: 10,
          reference: 'FAC-X',
          occurredAt: DateTime.now().toUtc(),
          idempotencyKey: key,
        ),
        throwsA(
          isA<PointsException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.conflict,
          ),
        ),
      );
      expect(await ledgerCount(customerId), 1);
      expect(await balanceOf(customerId), 10);
    });

    test(
      '8. fallo a mitad de transacción → rollback total (cero rastro)',
      () async {
        final customerId = await newCustomer();
        final tx = PostgresTransactionRunner(db);

        await expectLater(
          tx.run(() async {
            await ledger.insertCredit(
              customerId: customerId,
              points: 80,
              reference: 'x',
              occurredAt: DateTime.now().toUtc(),
              idempotencyKey: 'it-h-${newId()}',
            );
            throw StateError('fallo inyectado tras el INSERT del ledger');
          }),
          throwsA(isA<StateError>()),
        );

        expect(await ledgerCount(customerId), 0);
        expect(await balanceOf(customerId), 0);
      },
    );

    test('16. pv=false → el motor rechaza antes de tocar la base', () async {
      final customerId = await newCustomer();
      final engine = DebitPoints(
        ledger: ledger,
        idempotency: idempotency,
        audit: PostgresAuditLogWriter(db),
        tx: PostgresTransactionRunner(db),
        clock: const SystemClock(),
      );

      await expectLater(
        engine(
          customerId: customerId,
          command: DebitCommand(points: 10, reference: 'rw-1'),
          phoneVerified: false,
          idempotencyKey: 'it-pv-${newId()}',
          requestHash: 'h',
        ),
        throwsA(
          isA<PointsException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.phoneNotVerified,
          ),
        ),
      );
      expect(await ledgerCount(customerId), 0);
    });
  });

  group('Repositorios de lectura', () {
    test(
      'balance: sin movimientos → null (sin fila vacía); con → derivado',
      () async {
        final customerId = await newCustomer();
        expect(await balances.findByCustomerId(customerId), isNull);

        await ledger.insertCredit(
          customerId: customerId,
          points: 25,
          reference: 's',
          occurredAt: DateTime.now().toUtc(),
          idempotencyKey: 'it-bl-${newId()}',
        );
        final view = await balances.findByCustomerId(customerId);
        expect(view!.balance, 25);
      },
    );

    test(
      'movements: pagina por cursor (occurred_at, ledger_id) sin repetir',
      () async {
        final customerId = await newCustomer();
        for (var i = 0; i < 5; i++) {
          await ledger.insertCredit(
            customerId: customerId,
            points: 10,
            reference: 'r$i',
            occurredAt: DateTime.now().toUtc(),
            idempotencyKey: 'it-mv-$i-${newId()}',
          );
          // Asegura occurred_at distinto entre filas.
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }

        final page1 = await movements.getPage(customerId: customerId, limit: 2);
        expect(page1.items, hasLength(2));
        expect(page1.nextCursor, isNotNull);

        final seen = page1.items.map((m) => m.id).toSet();
        var cursor = page1.nextCursor;
        while (cursor != null) {
          final page = await movements.getPage(
            customerId: customerId,
            cursor: cursor,
            limit: 2,
          );
          for (final m in page.items) {
            expect(seen.add(m.id), isTrue, reason: 'repetido: ${m.id}');
            expect(m.balanceAfter, greaterThan(0));
            expect(m.occurredAt.isUtc, isTrue);
          }
          cursor = page.nextCursor;
        }
        expect(seen, hasLength(5));

        final other = await movements.getPage(customerId: await newCustomer());
        expect(other.items, isEmpty);
      },
    );

    test('rewards: solo ACTIVE vigentes; stock=0 → available=false; '
        'vencidas y DRAFT fuera (seed)', () async {
      final list = await rewards.listActive(now: DateTime.now().toUtc());

      final names = list.map((r) => r.name).toSet();
      expect(names, contains('Café con leche gratis'));
      expect(names, contains('Combo desayuno'));
      expect(names, isNot(contains('Promo vencida')));
      expect(names, isNot(contains('Borrador interno')));

      final sinStock = list.singleWhere((r) => r.name == 'Combo desayuno');
      expect(sinStock.available, isFalse);

      final conStock = list.singleWhere(
        (r) => r.name == 'Café con leche gratis',
      );
      expect(conStock.available, isTrue);
    });

    test(
      'establishments: activos con sucursales, sin campos admin (seed)',
      () async {
        final list = await establishments.listActive();

        final cafe = list.singleWhere((e) => e.name == 'Café Aranjuez');
        expect(cafe.category, 'CAFE');
        expect(cafe.branches, hasLength(2));
        expect(
          cafe.branches.map((b) => b.address),
          containsAll(['Av. Aranjuez 100', 'Calle Los Pinos 25']),
        );
      },
    );
  });
}
