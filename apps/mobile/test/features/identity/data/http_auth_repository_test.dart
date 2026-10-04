import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paseo_mobile/features/identity/data/http_auth_repository.dart';

void main() {
  const baseUrl = 'http://localhost:8080';

  group('HttpAuthRepository.sendOtp', () {
    test('envía POST a /api/v1/auth/phone/send-otp y tiene éxito', () async {
      final client = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/api/v1/auth/phone/send-otp'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, equals({'phone': '+59170123456'}));
        return http.Response('', 202);
      });
      final repo = HttpAuthRepository(client: client, baseUrl: baseUrl);

      await repo.sendOtp('+59170123456');
      // completa sin lanzar
    });

    test(
      'lanza AuthApiException con el code del API si responde 4xx',
      () async {
        final client = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'type': 'about:blank',
              'title': 'Validación fallida',
              'status': 422,
              'code': 'PHONE_NOT_SUPPORTED',
            }),
            422,
            headers: {'content-type': 'application/problem+json'},
          );
        });
        final repo = HttpAuthRepository(client: client, baseUrl: baseUrl);

        try {
          await repo.sendOtp('+18005551234');
          fail('debió lanzar AuthApiException');
        } on AuthApiException catch (e) {
          expect(e.statusCode, equals(422));
          expect(e.code, equals('PHONE_NOT_SUPPORTED'));
          expect(e.message, contains('Validación fallida'));
        }
      },
    );

    test('lanza AuthApiException genérica ante 500 sin problem+json', () async {
      final client = MockClient((request) async {
        return http.Response('boom', 500);
      });
      final repo = HttpAuthRepository(client: client, baseUrl: baseUrl);

      expect(
        () => repo.sendOtp('+59170123456'),
        throwsA(isA<AuthApiException>()),
      );
    });
  });

  group('HttpAuthRepository.verifyOtp', () {
    test('devuelve true ante 200 {phone_verified: true}', () async {
      final client = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/api/v1/auth/phone/verify'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, equals({'phone': '+59170123456', 'code': '123456'}));
        return http.Response(jsonEncode({'phone_verified': true}), 200);
      });
      final repo = HttpAuthRepository(client: client, baseUrl: baseUrl);

      final result = await repo.verifyOtp('+59170123456', '123456');

      expect(result, isNotNull);
    });

    test('devuelve false ante 422 (OTP inválido)', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'type': 'about:blank',
            'title': 'Validación fallida',
            'status': 422,
            'code': 'OTP_INVALID',
          }),
          422,
        );
      });
      final repo = HttpAuthRepository(client: client, baseUrl: baseUrl);

      final result = await repo.verifyOtp('+59170123456', '000000');

      expect(result, isNull);
    });
  });
}
