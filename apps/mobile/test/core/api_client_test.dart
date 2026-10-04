import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paseo_mobile/core/api_client.dart';

void main() {
  group('ApiClient (T016)', () {
    test(
      'envía Authorization/X-Paseo-Client, adjunta query y decodifica',
      () async {
        Uri? capturedUri;
        Map<String, String>? capturedHeaders;
        final httpClient = MockClient((request) async {
          capturedUri = request.url;
          capturedHeaders = request.headers;
          return http.Response(
            '{"balance_points": 1250, "updated_at": "2026-10-03T12:00:00Z"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final client = ApiClient(
          httpClient: httpClient,
          baseUrl: 'http://localhost:8080/api/v1/',
          accessToken: 'tok-123',
        );

        final json = await client.getJson(
          '/me/movements',
          queryParameters: {'limit': '20', 'cursor': 'abc'},
        );

        expect(json['balance_points'], 1250);
        expect(capturedUri?.path, '/api/v1/me/movements');
        expect(capturedUri?.queryParameters['limit'], '20');
        expect(capturedUri?.queryParameters['cursor'], 'abc');
        expect(capturedHeaders?['Authorization'], 'Bearer tok-123');
        expect(capturedHeaders?['X-Paseo-Client'], 'paseo-mobile');
        expect(capturedHeaders?['Accept'], 'application/json');
      },
    );

    test('sin token no envía Authorization', () async {
      Map<String, String>? capturedHeaders;
      final httpClient = MockClient((request) async {
        capturedHeaders = request.headers;
        return http.Response('{}', 200);
      });
      final client = ApiClient(
        httpClient: httpClient,
        baseUrl: 'http://localhost:8080/api/v1',
        accessToken: '',
      );

      await client.getJson('/me/balance');

      expect(capturedHeaders?.containsKey('Authorization'), isFalse);
    });

    test('problem+json se traduce a ApiException con code estable', () async {
      final httpClient = MockClient(
        (request) async => http.Response(
          '{"type": "about:blank", "title": "Teléfono no verificado",'
          ' "status": 403, "code": "PHONE_NOT_VERIFIED"}',
          403,
          headers: {'content-type': 'application/problem+json'},
        ),
      );
      final client = ApiClient(
        httpClient: httpClient,
        baseUrl: 'http://localhost:8080/api/v1',
        accessToken: 'tok',
      );

      await expectLater(
        client.getJson('/me/balance'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.code, 'code', 'PHONE_NOT_VERIFIED'),
        ),
      );
    });

    test(
      'error HTTP sin problem+json usa código genérico HTTP_<status>',
      () async {
        final httpClient = MockClient(
          (request) async => http.Response('', 500),
        );
        final client = ApiClient(
          httpClient: httpClient,
          baseUrl: 'http://localhost:8080/api/v1',
          accessToken: 'tok',
        );

        await expectLater(
          client.getJson('/rewards'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 500)
                .having((e) => e.code, 'code', 'HTTP_500'),
          ),
        );
      },
    );

    test('200 con cuerpo no JSON es INVALID_RESPONSE', () async {
      final httpClient = MockClient(
        (request) async => http.Response('no-json', 200),
      );
      final client = ApiClient(
        httpClient: httpClient,
        baseUrl: 'http://localhost:8080/api/v1',
        accessToken: 'tok',
      );

      await expectLater(
        client.getJson('/rewards'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'INVALID_RESPONSE'),
        ),
      );
    });

    test('fallo de transporte es NETWORK_ERROR (statusCode 0)', () async {
      final httpClient = MockClient(
        (request) async => throw http.ClientException('sin DNS'),
      );
      final client = ApiClient(
        httpClient: httpClient,
        baseUrl: 'http://localhost:8080/api/v1',
        accessToken: 'tok',
      );

      await expectLater(
        client.getJson('/me/balance'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 0)
              .having((e) => e.code, 'code', 'NETWORK_ERROR'),
        ),
      );
    });
  });
}
