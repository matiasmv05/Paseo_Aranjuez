import 'dart:convert';
import 'dart:io';

import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;
import 'package:test/test.dart';

import '../../../routes/merchant/movements/index.dart' as movements_route;
import '_support.dart';

contract.Movement _movement() => contract.Movement(
  id: 'm-1',
  createdAt: DateTime.utc(2026),
  invoiceRef: 'F-001',
  grossCents: 10000,
  discountCents: 1000,
  netCents: 9000,
  pointsCredited: 9,
  customerName: 'J*** P***',
  branchId: 'br-1',
);

void main() {
  test('200 con pagina de movimientos', () async {
    final deps = merchantDeps(
      list:
          ({
            required MerchantContext context,
            int? limit,
            String? cursor,
          }) async =>
              contract.MovementPage(items: [_movement()], nextCursor: 'next'),
    );
    final res = await movements_route.onRequest(
      routeContext(method: 'GET', path: '/merchant/movements', deps: deps),
    );
    expect(res.statusCode, HttpStatus.ok);
    final json = jsonDecode(await res.body()) as Map;
    expect(json['next_cursor'], 'next');
    final items = json['items']! as List;
    expect(items, hasLength(1));
    final item = (items.first as Map).cast<String, Object?>();
    expect(item['customer_name'], 'J*** P***');
    expect(item.containsKey('phone'), isFalse);
    expect(item.containsKey('email'), isFalse);
  });

  test('200 con comercio ajeno: pagina vacia', () async {
    final deps = merchantDeps(
      list: ({
        required MerchantContext context,
        int? limit,
        String? cursor,
      }) async => const contract.MovementPage(items: []),
    );
    final res = await movements_route.onRequest(
      routeContext(method: 'GET', path: '/merchant/movements', deps: deps),
    );
    expect(res.statusCode, HttpStatus.ok);
    final json = jsonDecode(await res.body()) as Map;
    expect(json['items'], isEmpty);
    expect(json['next_cursor'], isNull);
  });

  test('422 cuando limit no es entero', () async {
    final res = await movements_route.onRequest(
      routeContext(
        method: 'GET',
        path: '/merchant/movements?limit=abc',
        deps: merchantDeps(),
      ),
    );
    expect(res.statusCode, HttpStatus.unprocessableEntity);
    expect((jsonDecode(await res.body()) as Map)['code'], 'VALIDATION_FAILED');
  });

  test('propaga cursor y limit al caso de uso', () async {
    int? seenLimit;
    String? seenCursor;
    final deps = merchantDeps(
      list:
          ({
            required MerchantContext context,
            int? limit,
            String? cursor,
          }) async {
            seenLimit = limit;
            seenCursor = cursor;
            return const contract.MovementPage(items: []);
          },
    );
    final res = await movements_route.onRequest(
      routeContext(
        method: 'GET',
        path: '/merchant/movements?limit=5&cursor=c1',
        deps: deps,
      ),
    );
    expect(res.statusCode, HttpStatus.ok);
    expect(seenLimit, 5);
    expect(seenCursor, 'c1');
  });

  test('pasa el contexto del cajero (filtro por vendedor)', () async {
    MerchantContext? seen;
    final deps = merchantDeps(
      list:
          ({
            required MerchantContext context,
            int? limit,
            String? cursor,
          }) async {
            seen = context;
            return const contract.MovementPage(items: []);
          },
    );
    final res = await movements_route.onRequest(
      routeContext(
        method: 'GET',
        path: '/merchant/movements',
        deps: deps,
        merchant: sampleMerchant(role: MerchantRole.cashier, branchId: 'br-1'),
      ),
    );
    expect(res.statusCode, HttpStatus.ok);
    expect(seen!.isCashier, isTrue);
    expect(seen!.userId, 'user-1');
  });

  test('405 con metodo no permitido', () async {
    final res = await movements_route.onRequest(
      routeContext(
        method: 'POST',
        path: '/merchant/movements',
        deps: merchantDeps(),
      ),
    );
    expect(res.statusCode, HttpStatus.methodNotAllowed);
  });
}
