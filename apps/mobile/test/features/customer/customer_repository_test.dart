import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paseo_mobile/features/customer/data/customer_repository.dart';
import 'package:paseo_mobile/features/customer/data/http_customer_repository.dart';

void main() {
  const baseUrl = 'http://localhost:8080';

  group('HttpCustomerRepository.fetchQrTicket', () {
    test('GET /api/v1/customers/me/qr con Bearer devuelve el ticket', () async {
      final client = MockClient((request) async {
        expect(request.method, equals('GET'));
        expect(request.url.path, equals('/api/v1/customers/me/qr'));
        expect(request.headers['authorization'], equals('Bearer tok-123'));
        return http.Response(
          jsonEncode({'qr_ticket': 'qr.jwt.firmado', 'expires_in': 300}),
          200,
        );
      });
      final repo = HttpCustomerRepository(client: client, baseUrl: baseUrl);

      final ticket = await repo.fetchQrTicket('tok-123');

      expect(ticket, equals('qr.jwt.firmado'));
    });

    test('401 lanza CustomerApiException con code UNAUTHENTICATED', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'type': 'about:blank',
            'title': 'Unauthorized',
            'status': 401,
            'code': 'UNAUTHENTICATED',
          }),
          401,
          headers: {'content-type': 'application/problem+json'},
        );
      });
      final repo = HttpCustomerRepository(client: client, baseUrl: baseUrl);

      try {
        await repo.fetchQrTicket('expirado');
        fail('debió lanzar CustomerApiException');
      } on CustomerApiException catch (e) {
        expect(e.statusCode, equals(401));
        expect(e.code, equals('UNAUTHENTICATED'));
      }
    });
  });
}
