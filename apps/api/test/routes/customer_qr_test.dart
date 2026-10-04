import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paseo_api/adapters/in/customer_qr.dart';
import 'package:paseo_api/adapters/out/auth/jwt_token_signer.dart';
import 'package:paseo_api/adapters/out/auth/jwt_token_verifier.dart';
import 'package:paseo_api/application/customer/issue_customer_qr_ticket.dart';
import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:test/test.dart';

import '../../routes/customers/me/qr.dart' as qr_route;

class _MockContext extends Mock implements RequestContext {}

class _FixedClock implements Clock {
  const _FixedClock(this.now);

  final DateTime now;

  @override
  DateTime nowUtc() => now;
}

class _FixedIds implements IdGenerator {
  const _FixedIds(this.id);

  final String id;

  @override
  String newId() => id;
}

void main() {
  const secret = 'test-secret';
  final clock = _FixedClock(DateTime.utc(2026));
  const signer = JwtTokenSigner(secret: secret, kid: 'test-key');
  final verifier = JwtTokenVerifier(secret: secret, clock: clock);

  QrTicketIssuer issuer() {
    final useCase = IssueCustomerQrTicket(
      verifier: verifier,
      signer: signer,
      clock: clock,
      ids: const _FixedIds('qr-ticket-1'),
    );
    return ({String? authorizationHeader}) =>
        useCase(authorizationHeader: authorizationHeader);
  }

  RequestContext ctx({Map<String, String> headers = const {}}) {
    final context = _MockContext();
    when(() => context.request).thenReturn(
      Request(
        'GET',
        Uri.parse('http://localhost/customers/me/qr'),
        headers: headers,
      ),
    );
    when(
      () => context.read<Future<QrTicketIssuer>>(),
    ).thenAnswer((_) async => issuer());
    return context;
  }

  AuthClaims customerClaims() => AuthClaims(
    issuer: 'paseo-api',
    audience: 'paseo-mobile',
    subject: 'user-1',
    issuedAt: clock.now,
    expiresAt: clock.now.add(const Duration(minutes: 15)),
    jwtId: 'jti-1',
    role: UserRole.customer,
    customerId: 'cust-1',
    establishmentId: null,
    branchId: null,
    phoneVerified: true,
    emailVerified: false,
    tokenVersion: 0,
  );

  Map<String, Object?> decodePayload(String jwt) {
    final parts = jwt.split('.');
    final decoded = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    return (decoded as Map).cast<String, Object?>();
  }

  group('GET /customers/me/qr', () {
    test('200 con ticket firmado de 5 min para cliente autenticado', () async {
      final token = signer.sign(customerClaims());
      final res = await qr_route.onRequest(
        ctx(headers: {'authorization': 'Bearer $token'}),
      );

      expect(res.statusCode, HttpStatus.ok);
      final body = jsonDecode(await res.body()) as Map<String, dynamic>;
      expect(body['expires_in'], 300);
      expect(body['qr_ticket'], isA<String>());

      final payload = decodePayload(body['qr_ticket'] as String);
      expect(payload['sub'], equals('cust-1'));
      expect(payload['aud'], equals('paseo-qr'));
      expect((payload['exp'] as int) - (payload['iat'] as int), equals(300));
    });

    test('401 UNAUTHENTICATED sin header Authorization', () async {
      final res = await qr_route.onRequest(ctx());

      expect(res.statusCode, HttpStatus.unauthorized);
      final body = jsonDecode(await res.body()) as Map<String, dynamic>;
      expect(body['code'], equals('UNAUTHENTICATED'));
    });

    test('401 UNAUTHENTICATED con firma inválida', () async {
      const otherSigner = JwtTokenSigner(secret: 'otro-secreto', kid: 'k2');
      final token = otherSigner.sign(customerClaims());
      final res = await qr_route.onRequest(
        ctx(headers: {'authorization': 'Bearer $token'}),
      );

      expect(res.statusCode, HttpStatus.unauthorized);
      final body = jsonDecode(await res.body()) as Map<String, dynamic>;
      expect(body['code'], equals('UNAUTHENTICATED'));
    });

    test('403 FORBIDDEN si el JWT no es de cliente', () async {
      final admin = AuthClaims(
        issuer: 'paseo-api',
        audience: 'paseo-web-admin',
        subject: 'admin-1',
        issuedAt: clock.now,
        expiresAt: clock.now.add(const Duration(minutes: 15)),
        jwtId: 'jti-2',
        role: UserRole.admin,
        customerId: null,
        establishmentId: null,
        branchId: null,
        phoneVerified: false,
        emailVerified: true,
        tokenVersion: 0,
      );
      final token = signer.sign(admin);
      final res = await qr_route.onRequest(
        ctx(headers: {'authorization': 'Bearer $token'}),
      );

      expect(res.statusCode, HttpStatus.forbidden);
      final body = jsonDecode(await res.body()) as Map<String, dynamic>;
      expect(body['code'], equals('FORBIDDEN'));
    });
  });
}
