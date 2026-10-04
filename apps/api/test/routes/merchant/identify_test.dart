import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paseo_api/adapters/in/merchant_use_cases.dart';
import 'package:paseo_api/adapters/in/middleware/merchant_auth_middleware.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;
import 'package:test/test.dart';

import '../../../routes/merchant/customers/identify.dart' as identify_route;
import '_support.dart';

Future<Response> _through(
  MerchantDependencies deps, {
  String? authorization,
}) async {
  final handler = merchantAuth()(
    (_) async => Response.json(body: {'ok': true}),
  );
  return handler(middlewareContext(deps: deps, authorization: authorization));
}

MerchantDependencies _deps({
  AuthClaims? claims,
  User? user,
  MerchantContext? context,
}) => merchantDeps(
  verifier: StubVerifier(claims ?? sampleClaims()),
  users: StubUsers(user: user ?? sampleUser()),
  establishments: StubEstablishments(context: context ?? sampleMerchant()),
);

void main() {
  setUpAll(() {
    registerFallbackValue(() => sampleMerchant());
  });

  group('merchantAuth (matriz de autorizacion)', () {
    test('401 sin encabezado Authorization', () async {
      final res = await _through(_deps());
      expect(res.statusCode, HttpStatus.unauthorized);
      expect((jsonDecode(await res.body()) as Map)['code'], 'UNAUTHENTICATED');
    });

    test('401 cuando el verificador no valida el token', () async {
      final deps = merchantDeps(verifier: StubVerifier());
      final res = await _through(deps, authorization: 'Bearer x');
      expect(res.statusCode, HttpStatus.unauthorized);
    });

    test('401 cuando la audiencia no es paseo-web-merchant', () async {
      final deps = _deps(claims: sampleClaims(audience: 'paseo-mobile'));
      final res = await _through(deps, authorization: 'Bearer x');
      expect(res.statusCode, HttpStatus.unauthorized);
    });

    test('403 con rol customer', () async {
      final deps = _deps(claims: sampleClaims(role: UserRole.customer));
      final res = await _through(deps, authorization: 'Bearer x');
      expect(res.statusCode, HttpStatus.forbidden);
      expect((jsonDecode(await res.body()) as Map)['code'], 'FORBIDDEN');
    });

    test('403 con rol admin', () async {
      final deps = _deps(claims: sampleClaims(role: UserRole.admin));
      final res = await _through(deps, authorization: 'Bearer x');
      expect(res.statusCode, HttpStatus.forbidden);
    });

    test('401 cuando el usuario no existe en la base', () async {
      final deps = merchantDeps(
        verifier: StubVerifier(sampleClaims()),
        users: StubUsers(),
        establishments: StubEstablishments(context: sampleMerchant()),
      );
      final res = await _through(deps, authorization: 'Bearer x');
      expect(res.statusCode, HttpStatus.unauthorized);
    });

    test('401 cuando el usuario esta bloqueado', () async {
      final deps = _deps(user: sampleUser(status: UserStatus.blocked));
      final res = await _through(deps, authorization: 'Bearer x');
      expect(res.statusCode, HttpStatus.unauthorized);
    });

    test('401 cuando token_version no coincide', () async {
      final deps = _deps(claims: sampleClaims(tokenVersion: 1));
      final res = await _through(deps, authorization: 'Bearer x');
      expect(res.statusCode, HttpStatus.unauthorized);
    });

    test(
      '403 PHONE_NOT_VERIFIED cuando el telefono no esta verificado',
      () async {
        final deps = _deps(user: sampleUser(phoneVerified: false));
        final res = await _through(deps, authorization: 'Bearer x');
        expect(res.statusCode, HttpStatus.forbidden);
        expect(
          (jsonDecode(await res.body()) as Map)['code'],
          'PHONE_NOT_VERIFIED',
        );
      },
    );

    test('403 cuando el comercio del claim no coincide con la base', () async {
      final deps = _deps(context: sampleMerchant(establishmentId: 'est-2'));
      final res = await _through(deps, authorization: 'Bearer x');
      expect(res.statusCode, HttpStatus.forbidden);
    });

    test('403 cuando el cajero no tiene sucursal', () async {
      final deps = _deps(
        claims: sampleClaims(role: UserRole.merchantCashier, branchId: null),
        context: sampleMerchant(role: MerchantRole.cashier, branchId: null),
      );
      final res = await _through(deps, authorization: 'Bearer x');
      expect(res.statusCode, HttpStatus.forbidden);
    });

    test('200 para un dueno valido', () async {
      final res = await _through(_deps(), authorization: 'Bearer x');
      expect(res.statusCode, HttpStatus.ok);
    });

    test('200 para un cajero con sucursal', () async {
      final deps = _deps(
        claims: sampleClaims(role: UserRole.merchantCashier, branchId: 'br-1'),
        context: sampleMerchant(role: MerchantRole.cashier, branchId: 'br-1'),
      );
      final res = await _through(deps, authorization: 'Bearer x');
      expect(res.statusCode, HttpStatus.ok);
    });
  });

  group('POST /merchant/customers/identify', () {
    test('200 con identificacion por telefono', () async {
      final deps = merchantDeps(
        identify: ({required MerchantContext context, required input}) async =>
            contract.IdentifyResult(
              ticket: 'tkt',
              expiresAt: DateTime.utc(2026),
              customerName: 'J*** P***',
            ),
      );
      final res = await identify_route.onRequest(
        routeContext(
          method: 'POST',
          path: '/merchant/customers/identify',
          deps: deps,
          body: {'method': 'PHONE', 'phone': '+59160000000'},
        ),
      );
      expect(res.statusCode, HttpStatus.ok);
      final json = jsonDecode(await res.body()) as Map;
      expect(json['ticket'], 'tkt');
      expect(json['customer_name'], 'J*** P***');
    });

    test('200 con identificacion por QR', () async {
      final deps = merchantDeps(
        identify: ({required MerchantContext context, required input}) async =>
            contract.IdentifyResult(
              ticket: 'qkt',
              expiresAt: DateTime.utc(2026),
              customerName: 'A*** B***',
            ),
      );
      final res = await identify_route.onRequest(
        routeContext(
          method: 'POST',
          path: '/merchant/customers/identify',
          deps: deps,
          body: {'method': 'QR', 'qr_token': 'opaque'},
        ),
      );
      expect(res.statusCode, HttpStatus.ok);
    });

    test('403 PHONE_NOT_VERIFIED', () async {
      final deps = merchantDeps(
        identify: ({required MerchantContext context, required input}) async =>
            throw LoyaltyException.phoneNotVerified(),
      );
      final res = await identify_route.onRequest(
        routeContext(
          method: 'POST',
          path: '/merchant/customers/identify',
          deps: deps,
          body: {'method': 'PHONE', 'phone': '+59160000000'},
        ),
      );
      expect(res.statusCode, HttpStatus.forbidden);
      expect(
        (jsonDecode(await res.body()) as Map)['code'],
        'PHONE_NOT_VERIFIED',
      );
    });

    test('404 CUSTOMER_NOT_FOUND', () async {
      final deps = merchantDeps(
        identify: ({required MerchantContext context, required input}) async =>
            throw LoyaltyException.customerNotFound(),
      );
      final res = await identify_route.onRequest(
        routeContext(
          method: 'POST',
          path: '/merchant/customers/identify',
          deps: deps,
          body: {'method': 'PHONE', 'phone': '+59160000000'},
        ),
      );
      expect(res.statusCode, HttpStatus.notFound);
      expect(
        (jsonDecode(await res.body()) as Map)['code'],
        'CUSTOMER_NOT_FOUND',
      );
    });

    test('422 INVALID_QR_TOKEN', () async {
      final deps = merchantDeps(
        identify: ({required MerchantContext context, required input}) async =>
            throw LoyaltyException.invalidQrToken(),
      );
      final res = await identify_route.onRequest(
        routeContext(
          method: 'POST',
          path: '/merchant/customers/identify',
          deps: deps,
          body: {'method': 'QR', 'qr_token': 'bad'},
        ),
      );
      expect(res.statusCode, HttpStatus.unprocessableEntity);
      expect((jsonDecode(await res.body()) as Map)['code'], 'INVALID_QR_TOKEN');
    });

    test('422 con cuerpo ausente', () async {
      final res = await identify_route.onRequest(
        routeContext(
          method: 'POST',
          path: '/merchant/customers/identify',
          deps: merchantDeps(),
        ),
      );
      expect(res.statusCode, HttpStatus.unprocessableEntity);
    });

    test('405 con metodo no permitido', () async {
      final res = await identify_route.onRequest(
        routeContext(
          method: 'GET',
          path: '/merchant/customers/identify',
          deps: merchantDeps(),
        ),
      );
      expect(res.statusCode, HttpStatus.methodNotAllowed);
    });
  });
}
