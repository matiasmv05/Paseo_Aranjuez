import 'package:paseo_api/adapters/out/postgres/postgres.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import 'support.dart';

/// T006/T003: invariants of the ledger trigger and table permissions
/// (V005). Runs against the dev DB on 5433 with `paseo_app`.
void main() {
  late PgDatabase db;
  late PostgresUserRepository users;
  late PostgresCustomerRepository customers;

  setUpAll(() async {
    db = await PgDatabase.open(integrationConfig());
    users = PostgresUserRepository(db);
    customers = PostgresCustomerRepository(db);
  });

  tearDownAll(() async {
    await db.close();
  });

  Future<String> newCustomer({bool verified = true}) async {
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
    if (verified) {
      await customers.markPhoneVerified(userId: id, at: DateTime.now().toUtc());
    }
    return id;
  }

  Future<void> insertLedger(
    PgDatabase conn, {
    required String customerId,
    required int delta,
    required String type,
    required String idempotencyKey,
  }) async {
    await conn.session.execute(
      Sql.named(
        'INSERT INTO app.points_ledger (customer_id, delta, type, idempotency_key) '
        'VALUES (@c::uuid, @d, @t, @k)',
      ),
      parameters: {'c': customerId, 'd': delta, 't': type, 'k': idempotencyKey},
    );
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

  test(
    'CREDIT: el trigger mantiene el saldo y escribe balance_after',
    () async {
      final customerId = await newCustomer();
      await insertLedger(
        db,
        customerId: customerId,
        delta: 120,
        type: 'CREDIT',
        idempotencyKey: 't-${newId()}',
      );

      final r = await db.session.execute(
        Sql.named(
          'SELECT balance_after FROM app.points_ledger '
          'WHERE customer_id = @c::uuid',
        ),
        parameters: {'c': customerId},
      );
      expect(r.first[0]! as int, 120);
      expect(await balanceOf(customerId), 120);
    },
  );

  test(
    'REDEEM por encima del saldo aborta con 23514 y no deja rastro',
    () async {
      final customerId = await newCustomer();
      final key = 't-${newId()}';

      await expectLater(
        insertLedger(
          db,
          customerId: customerId,
          delta: -50,
          type: 'REDEEM',
          idempotencyKey: key,
        ),
        throwsA(
          isA<ServerException>().having((e) => e.code, 'sqlstate', '23514'),
        ),
      );

      expect(await balanceOf(customerId), 0);
      final r = await db.session.execute(
        Sql.named(
          'SELECT COUNT(*) FROM app.points_ledger WHERE idempotency_key = @k',
        ),
        parameters: {'k': key},
      );
      expect(r.first[0]! as int, 0);
    },
  );

  /// Espera hasta que exista un bloqueo sin conceder (B ya esta esperando a
  /// A). Sin esto, el orden de red puede serializar las transacciones y la
  /// "carrera" no se ejercita.
  Future<void> waitUntilBlocked(PgDatabase probe) async {
    for (var i = 0; i < 200; i++) {
      final r = await probe.connection.execute(
        'SELECT count(*) FROM pg_locks WHERE NOT granted',
      );
      if ((r.first[0]! as int) > 0) return;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    fail('B no llego a bloquearse: la carrera no se ejercito');
  }

  test(
    'dos CREDIT concurrentes sobre cliente nuevo no pierden actualizacion',
    () async {
      final customerId = await newCustomer();
      final a = await PgDatabase.open(integrationConfig());
      final b = await PgDatabase.open(integrationConfig());
      final probe = await PgDatabase.open(integrationConfig());
      try {
        await a.connection.execute('BEGIN');
        await insertLedger(
          a,
          customerId: customerId,
          delta: 100,
          type: 'CREDIT',
          idempotencyKey: 'race-${newId()}',
        );

        await b.connection.execute('BEGIN');
        // B ejecuta el trigger sin ver la fila de A (aun sin commit) y se
        // bloquea en el upsert hasta que A confirme.
        final bInsert = insertLedger(
          b,
          customerId: customerId,
          delta: 100,
          type: 'CREDIT',
          idempotencyKey: 'race-${newId()}',
        );
        await waitUntilBlocked(probe);
        await a.connection.execute('COMMIT');
        await bInsert;
        await b.connection.execute('COMMIT');

        // Con el trigger correcto (DO UPDATE SET balance = balance + delta
        // bajo el bloqueo de fila) el saldo final ES 200.
        expect(await balanceOf(customerId), 200);
      } finally {
        await probe.close();
        await b.close();
        await a.close();
      }
    },
  );

  test(
    'dos REDEEM concurrentes sobre saldo 100: solo uno gana (sin FOR UPDATE)',
    () async {
      final customerId = await newCustomer();
      await insertLedger(
        db,
        customerId: customerId,
        delta: 100,
        type: 'CREDIT',
        idempotencyKey: 't-${newId()}',
      );

      final a = await PgDatabase.open(integrationConfig());
      final b = await PgDatabase.open(integrationConfig());
      final probe = await PgDatabase.open(integrationConfig());
      try {
        await a.connection.execute('BEGIN');
        await insertLedger(
          a,
          customerId: customerId,
          delta: -70,
          type: 'REDEEM',
          idempotencyKey: 'race-${newId()}',
        );

        await b.connection.execute('BEGIN');
        final bInsert = insertLedger(
          b,
          customerId: customerId,
          delta: -70,
          type: 'REDEEM',
          idempotencyKey: 'race-${newId()}',
        );
        await waitUntilBlocked(probe);
        await a.connection.execute('COMMIT');
        // B hereda -70 sobre el saldo ya actualizado (30) -> viola CHECK.
        await expectLater(
          bInsert,
          throwsA(
            isA<ServerException>().having((e) => e.code, 'sqlstate', '23514'),
          ),
        );
        await b.connection.execute('ROLLBACK');

        expect(await balanceOf(customerId), 30);
      } finally {
        await probe.close();
        await b.close();
        await a.close();
      }
    },
  );

  test('paseo_app no puede UPDATE/DELETE/TRUNCATE points_ledger', () async {
    await expectLater(
      db.connection.execute(
        Sql.named('UPDATE app.points_ledger SET delta = 0'),
      ),
      throwsA(isA<ServerException>()),
    );
    await expectLater(
      db.connection.execute(Sql.named('DELETE FROM app.points_ledger')),
      throwsA(isA<ServerException>()),
    );
    await expectLater(
      db.connection.execute(Sql.named('TRUNCATE app.points_ledger')),
      throwsA(isA<ServerException>()),
    );
  });

  test(
    'paseo_app no puede escribir customer_balances (solo el trigger)',
    () async {
      final customerId = await newCustomer();
      await expectLater(
        db.connection.execute(
          Sql.named(
            'UPDATE app.customer_balances SET balance = 0 '
            'WHERE customer_id = @c::uuid',
          ),
          parameters: {'c': customerId},
        ),
        throwsA(isA<ServerException>()),
      );
      await expectLater(
        db.connection.execute(
          Sql.named(
            'INSERT INTO app.customer_balances (customer_id, balance) '
            'VALUES (@c::uuid, 0)',
          ),
          parameters: {'c': customerId},
        ),
        throwsA(isA<ServerException>()),
      );
    },
  );
}
