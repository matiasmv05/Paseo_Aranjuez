import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/application/merchant/use_cases/list_movements.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;
import 'package:test/test.dart';

import 'fakes.dart';

void main() {
  final now = DateTime.utc(2026, 10, 3, 12);

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

  MovementRecord record({
    String id = 'm-1',
    String customerName = 'Juan Perez',
    String branchId = 'br-1',
  }) => MovementRecord(
    id: id,
    createdAt: now,
    invoiceRef: 'F-$id',
    grossCents: 25000,
    discountCents: 0,
    netCents: 25000,
    pointsCredited: 25,
    customerName: customerName,
    branchId: branchId,
  );

  group('ListMovements (HU-13, FR-019)', () {
    test('el dueno ve todo el comercio (sin filtro de vendedor)', () async {
      final repo = FakeMovementRepository(
        MovementPageData(items: [record()], nextCursor: 'c-2'),
      );
      final result = await ListMovements(movements: repo)(context: owner);

      expect(repo.lastQuery!.establishmentId, 'est-1');
      expect(repo.lastQuery!.sellerUserId, isNull);
      expect(repo.lastQuery!.limit, ListMovements.defaultLimit);
      expect(repo.lastQuery!.cursor, isNull);
      expect(result.items, hasLength(1));
      expect(result.items.single.customerName, 'Juan P.');
      expect(result.nextCursor, 'c-2');
    });

    test('el cajero solo ve sus propios registros', () async {
      final repo = FakeMovementRepository(const MovementPageData(items: []));
      await ListMovements(movements: repo)(context: cashier);

      expect(repo.lastQuery!.sellerUserId, 'u-cashier');
    });

    test('enmascara nombres de una sola palabra', () async {
      final repo = FakeMovementRepository(
        MovementPageData(items: [record(customerName: 'Ana')]),
      );
      final result = await ListMovements(movements: repo)(context: owner);
      expect(result.items.single.customerName, 'A.');
    });

    test('respeta y propaga el cursor', () async {
      final repo = FakeMovementRepository(
        MovementPageData(items: [record()], nextCursor: null),
      );
      final result = await ListMovements(movements: repo)(
        context: owner,
        cursor: 'c-1',
      );

      expect(repo.lastQuery!.cursor, 'c-1');
      expect(result.nextCursor, isNull);
    });

    test('valida el limite dentro de 1..100', () async {
      ListMovements useCase() => ListMovements(
        movements: FakeMovementRepository(const MovementPageData(items: [])),
      );

      await useCase()(context: owner, limit: 1);
      await useCase()(context: owner, limit: 100);

      for (final invalid in [0, -1, 101, 5000]) {
        await expectLater(
          useCase()(context: owner, limit: invalid),
          throwsA(
            isA<LoyaltyException>().having(
              (error) => error.code,
              'code',
              contract.ApiErrorCode.validationFailed,
            ),
          ),
        );
      }
    });
  });
}
