import 'dart:convert';
import 'dart:io';

import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/application/merchant/use_cases/register_purchase.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;
import 'package:test/test.dart';

import '../../../routes/merchant/purchases/index.dart' as purchase_route;
import '_support.dart';

const _body = {
  'ticket': 'tkt',
  'gross_cents': 10000,
  'discount_cents': 1000,
  'net_cents': 9000,
  'invoice_ref': 'F-001',
};

contract.Purchase _purchase() => contract.Purchase(
  id: 'p-1',
  invoiceRef: 'F-001',
  grossCents: 10000,
  discountCents: 1000,
  netCents: 9000,
  pointsCredited: 9,
  ruleId: 'rule-1',
  campaignRuleId: null,
  createdAt: DateTime.utc(2026),
);

void main() {
  test('422 cuando falta Idempotency-Key', () async {
    final res = await purchase_route.onRequest(
      routeContext(
        method: 'POST',
        path: '/merchant/purchases',
        deps: merchantDeps(),
        body: _body,
      ),
    );
    expect(res.statusCode, HttpStatus.unprocessableEntity);
    expect((jsonDecode(await res.body()) as Map)['code'], 'VALIDATION_FAILED');
  });

  test('201 al crear la compra', () async {
    final deps = merchantDeps(
      register:
          ({
            required MerchantContext context,
            required contract.RegisterPurchaseRequest request,
            required String idempotencyKey,
          }) async {
            expect(idempotencyKey, 'key-1');
            return RegisterPurchaseOutcome(
              purchase: _purchase(),
              created: true,
            );
          },
    );
    final res = await purchase_route.onRequest(
      routeContext(
        method: 'POST',
        path: '/merchant/purchases',
        deps: deps,
        body: _body,
        headers: {'idempotency-key': 'key-1'},
      ),
    );
    expect(res.statusCode, HttpStatus.created);
    final json = jsonDecode(await res.body()) as Map;
    expect(json['id'], 'p-1');
    expect(json['points_credited'], 9);
  });

  test('200 en el replay idempotente', () async {
    final deps = merchantDeps(
      register:
          ({
            required MerchantContext context,
            required contract.RegisterPurchaseRequest request,
            required String idempotencyKey,
          }) async =>
              RegisterPurchaseOutcome(purchase: _purchase(), created: false),
    );
    final res = await purchase_route.onRequest(
      routeContext(
        method: 'POST',
        path: '/merchant/purchases',
        deps: deps,
        body: _body,
        headers: {'idempotency-key': 'key-1'},
      ),
    );
    expect(res.statusCode, HttpStatus.ok);
  });

  test('409 DUPLICATE_INVOICE', () async {
    final deps = merchantDeps(
      register: ({
        required MerchantContext context,
        required contract.RegisterPurchaseRequest request,
        required String idempotencyKey,
      }) async => throw LoyaltyException.duplicateInvoice(),
    );
    final res = await purchase_route.onRequest(
      routeContext(
        method: 'POST',
        path: '/merchant/purchases',
        deps: deps,
        body: _body,
        headers: {'idempotency-key': 'key-1'},
      ),
    );
    expect(res.statusCode, HttpStatus.conflict);
    expect((jsonDecode(await res.body()) as Map)['code'], 'DUPLICATE_INVOICE');
  });

  test('422 INVALID_IDENTIFICATION_TICKET', () async {
    final deps = merchantDeps(
      register: ({
        required MerchantContext context,
        required contract.RegisterPurchaseRequest request,
        required String idempotencyKey,
      }) async => throw LoyaltyException.invalidIdentificationTicket(),
    );
    final res = await purchase_route.onRequest(
      routeContext(
        method: 'POST',
        path: '/merchant/purchases',
        deps: deps,
        body: _body,
        headers: {'idempotency-key': 'key-1'},
      ),
    );
    expect(res.statusCode, HttpStatus.unprocessableEntity);
    expect(
      (jsonDecode(await res.body()) as Map)['code'],
      'INVALID_IDENTIFICATION_TICKET',
    );
  });

  test('422 ante invariantes de montos invalidas', () async {
    final deps = merchantDeps(
      register:
          ({
            required MerchantContext context,
            required contract.RegisterPurchaseRequest request,
            required String idempotencyKey,
          }) async => throw LoyaltyException.validation(
            'net_cents no coincide con gross_cents - discount_cents',
          ),
    );
    final res = await purchase_route.onRequest(
      routeContext(
        method: 'POST',
        path: '/merchant/purchases',
        deps: deps,
        body: _body,
        headers: {'idempotency-key': 'key-1'},
      ),
    );
    expect(res.statusCode, HttpStatus.unprocessableEntity);
    expect((jsonDecode(await res.body()) as Map)['code'], 'VALIDATION_FAILED');
  });

  test('429 RATE_LIMITED cuando se supera el limite', () async {
    final deps = merchantDeps(rateLimiter: FakeRateLimiter(allowed: false));
    final res = await purchase_route.onRequest(
      routeContext(
        method: 'POST',
        path: '/merchant/purchases',
        deps: deps,
        body: _body,
        headers: {'idempotency-key': 'key-1'},
      ),
    );
    expect(res.statusCode, HttpStatus.tooManyRequests);
    expect((jsonDecode(await res.body()) as Map)['code'], 'RATE_LIMITED');
  });

  test('405 con metodo no permitido', () async {
    final res = await purchase_route.onRequest(
      routeContext(
        method: 'GET',
        path: '/merchant/purchases',
        deps: merchantDeps(),
      ),
    );
    expect(res.statusCode, HttpStatus.methodNotAllowed);
  });
}
