import 'package:paseo_api/application/points/ports.dart';
import 'package:paseo_api/application/points/read_use_cases.dart';
import 'package:paseo_api/domain/points/points.dart';
import 'package:test/test.dart';

import '../identity/fakes.dart' show FixedClock;
import 'fakes.dart';

void main() {
  const customerId = 'cust-1';
  final now = DateTime.utc(2026, 2, 1, 12);

  group('GetBalance (HU-04, FR-001)', () {
    late FakeBalanceRepository balances;
    late GetBalance useCase;

    setUp(() {
      balances = FakeBalanceRepository();
      useCase = GetBalance(balances: balances);
    });

    test('cliente sin movimientos devuelve saldo 0 sin fila en base', () async {
      final result = await useCase(customerId: customerId);

      expect(result.balance, 0);
      expect(result.updatedAt, isNull);
    });

    test('cliente con saldo devuelve el derivado por el trigger', () async {
      final updated = DateTime.utc(2026, 1, 31, 10);
      balances.balances[customerId] = BalanceView(
        balance: 340,
        updatedAt: updated,
      );

      final result = await useCase(customerId: customerId);

      expect(result.balance, 340);
      expect(result.updatedAt, updated);
    });

    test(
      'solo lee el cliente pedido (el cid viene del JWT en la ruta)',
      () async {
        balances.balances['otro'] = BalanceView(balance: 999, updatedAt: now);

        final result = await useCase(customerId: customerId);

        expect(result.balance, 0);
      },
    );
  });

  group('GetMovements (HU-05, FR-002; spec C7)', () {
    late FakeMovementsRepository movements;
    late GetMovements useCase;

    LedgerMovement movement(String id, DateTime at, int delta) =>
        LedgerMovement(
          id: id,
          type: delta >= 0 ? MovementType.credit : MovementType.redeem,
          deltaPoints: delta,
          occurredAt: at,
          origin: delta >= 0 ? 'purchase' : 'redemption',
          referenceId: 'ref-$id',
          balanceAfter: 100,
        );

    setUp(() {
      movements = FakeMovementsRepository();
      useCase = GetMovements(movements: movements);
    });

    test(
      'cliente sin movimientos devuelve página vacía (empty state)',
      () async {
        final page = await useCase(customerId: customerId);

        expect(page.items, isEmpty);
        expect(page.nextCursor, isNull);
      },
    );

    test('pagina por cursor sin repetidos ni omitidos', () async {
      movements.rows = [
        movement('m3', DateTime.utc(2026, 1, 3), 10),
        movement('m2', DateTime.utc(2026, 1, 2), -5),
        movement('m1', DateTime.utc(2026), 15),
      ];

      final page1 = await useCase(customerId: customerId, limit: 2);
      expect(page1.items.map((m) => m.id), ['m3', 'm2']);
      expect(page1.nextCursor, isNotNull);

      final page2 = await useCase(
        customerId: customerId,
        cursor: page1.nextCursor,
        limit: 2,
      );
      expect(page2.items.map((m) => m.id), ['m1']);
    });

    test('limit por defecto 20 y se acota al máximo 50', () async {
      String? seenCursor;
      int? seenLimit;
      useCase = GetMovements(
        movements: _CapturingMovementsRepository(
          onCall: (cursor, limit) {
            seenCursor = cursor;
            seenLimit = limit;
          },
        ),
      );

      await useCase(customerId: customerId);
      expect(seenCursor, isNull);
      expect(seenLimit, 20);

      await useCase(customerId: customerId, limit: 999);
      expect(seenLimit, 50);
    });

    test(
      'cursor inválido propaga FormatException (la ruta lo mapea a 422)',
      () async {
        await expectLater(
          useCase(customerId: customerId, cursor: '%%%invalid%%%'),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });

  group('ListRewards (HU-06, FR-003)', () {
    late FakeRewardsRepository rewards;
    late ListRewards useCase;

    setUp(() {
      rewards = FakeRewardsRepository();
      useCase = ListRewards(rewards: rewards, clock: FixedClock(now));
    });

    test('catálogo vacío devuelve lista vacía', () async {
      expect(await useCase(), isEmpty);
    });

    test('devuelve el listado activo del repositorio filtrado con "now" '
        'del servidor', () async {
      DateTime? seenNow;
      useCase = ListRewards(
        rewards: _CapturingRewardsRepository(onCall: (n) => seenNow = n),
        clock: FixedClock(now),
      );

      await useCase();
      expect(seenNow, now);
    });
  });

  group('ListEstablishments (HU-09, FR-004)', () {
    late FakeEstablishmentsRepository establishments;
    late ListEstablishments useCase;

    setUp(() {
      establishments = FakeEstablishmentsRepository();
      useCase = ListEstablishments(establishments: establishments);
    });

    test('sin establecimientos devuelve lista vacía', () async {
      expect(await useCase(), isEmpty);
    });

    test('devuelve los activos del repositorio', () async {
      establishments.rows = [
        const EstablishmentRecord(
          id: 'est-1',
          name: 'Café',
          category: 'CAFE',
          branches: [
            BranchRecord(id: 'br-1', name: 'Principal', address: 'Av. 1'),
          ],
        ),
      ];

      final result = await useCase();
      expect(result.single.name, 'Café');
      expect(result.single.branches.single.address, 'Av. 1');
    });
  });
}

/// Repositorio que captura los parámetros de la llamada.
final class _CapturingMovementsRepository implements MovementsRepository {
  new({required this.onCall});

  final void Function(String? cursor, int limit) onCall;

  @override
  Future<MovementsPage> getPage({
    required String customerId,
    String? cursor,
    int limit = 20,
  }) async {
    onCall(cursor, limit);
    return const MovementsPage(items: []);
  }
}

final class _CapturingRewardsRepository implements RewardsRepository {
  new({required this.onCall});

  final void Function(DateTime now) onCall;

  @override
  Future<List<RewardRecord>> listActive({required DateTime now}) async {
    onCall(now);
    return const [];
  }
}
