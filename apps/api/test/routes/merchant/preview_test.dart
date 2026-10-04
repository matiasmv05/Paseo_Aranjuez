import 'dart:convert';
import 'dart:io';

import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;
import 'package:test/test.dart';

import '../../../routes/merchant/purchases/preview.dart' as preview_route;
import '_support.dart';

const _body = {
  'ticket': 'tkt',
  'gross_cents': 10000,
  'discount_cents': 0,
  'net_cents': 10000,
};

contract.PreviewPurchaseResult _result() => contract.PreviewPurchaseResult(
  points: 10,
  ruleId: 'rule-1',
  campaignRuleId: null,
  breakdown: const contract.CalculationBreakdown(
    pointsBase: 10,
    multiplierBp: 10000,
    pointsAfterMultiplier: 10,
    pointsBeforeCap: 10,
    capApplied: false,
    belowMinPurchase: false,
    rounding: contract.Rounding.floor,
  ),
);

void main() {
  test('200 sin escribir y coherente con el registro', () async {
    var called = 0;
    final deps = merchantDeps(
      preview:
          ({
            required MerchantContext context,
            required contract.PreviewPurchaseRequest request,
          }) async {
            called++;
            expect(request.netCents, 10000);
            return _result();
          },
    );
    final res = await preview_route.onRequest(
      routeContext(
        method: 'POST',
        path: '/merchant/purchases/preview',
        deps: deps,
        body: _body,
      ),
    );
    expect(res.statusCode, HttpStatus.ok);
    expect(called, 1);
    final json = jsonDecode(await res.body()) as Map;
    expect(json['points'], 10);
    expect(json['rule_id'], 'rule-1');
  });

  test('429 RATE_LIMITED cuando se supera el limite', () async {
    final deps = merchantDeps(rateLimiter: FakeRateLimiter(allowed: false));
    final res = await preview_route.onRequest(
      routeContext(
        method: 'POST',
        path: '/merchant/purchases/preview',
        deps: deps,
        body: _body,
      ),
    );
    expect(res.statusCode, HttpStatus.tooManyRequests);
    expect((jsonDecode(await res.body()) as Map)['code'], 'RATE_LIMITED');
  });

  test('409 NO_APPLICABLE_RULE', () async {
    final deps = merchantDeps(
      preview: ({
        required MerchantContext context,
        required contract.PreviewPurchaseRequest request,
      }) async => throw LoyaltyException.noApplicableRule(),
    );
    final res = await preview_route.onRequest(
      routeContext(
        method: 'POST',
        path: '/merchant/purchases/preview',
        deps: deps,
        body: _body,
      ),
    );
    expect(res.statusCode, HttpStatus.conflict);
    expect((jsonDecode(await res.body()) as Map)['code'], 'NO_APPLICABLE_RULE');
  });

  test('422 con cuerpo ausente', () async {
    final res = await preview_route.onRequest(
      routeContext(
        method: 'POST',
        path: '/merchant/purchases/preview',
        deps: merchantDeps(),
      ),
    );
    expect(res.statusCode, HttpStatus.unprocessableEntity);
  });

  test('405 con metodo no permitido', () async {
    final res = await preview_route.onRequest(
      routeContext(
        method: 'GET',
        path: '/merchant/purchases/preview',
        deps: merchantDeps(),
      ),
    );
    expect(res.statusCode, HttpStatus.methodNotAllowed);
  });
}
