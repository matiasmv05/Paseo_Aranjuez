import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paseo_api/adapters/in/middleware/rate_limit_middleware.dart';
import 'package:test/test.dart';

class _MockContext extends Mock implements RequestContext;

RequestContext _ctx({
  String path = '/auth/login',
  Map<String, String>? headers,
}) {
  final ctx = _MockContext();
  when(() => ctx.request).thenReturn(
    Request('POST', Uri.parse('http://localhost$path'), headers: headers ?? {}),
  );
  return ctx;
}

void main() {
  group('rateLimiter', () {
    test('allows requests under limit', () async {
      final handler = rateLimiter(
        limits: {'login': 3},
        window: const Duration(minutes: 1),
      )((c) async => Response.json(body: {'ok': true}));

      final res = await handler(_ctx());
      expect(res.statusCode, equals(HttpStatus.ok));
    });

    test('returns 429 after limit exceeded', () async {
      final handler = rateLimiter(
        limits: {'login': 2},
        window: const Duration(minutes: 1),
      )((c) async => Response.json(body: {'ok': true}));

      expect((await handler(_ctx())).statusCode, equals(HttpStatus.ok));
      expect((await handler(_ctx())).statusCode, equals(HttpStatus.ok));

      final res = await handler(_ctx());
      expect(res.statusCode, equals(HttpStatus.tooManyRequests));
      final body = jsonDecode(await res.body()) as Map<String, dynamic>;
      expect(body['code'], equals('RATE_LIMITED'));
    });

    test('different IPs are not mixed', () async {
      final handler = rateLimiter(
        limits: {'login': 2},
        window: const Duration(minutes: 1),
      )((c) async => Response.json(body: {'ok': true}));

      expect(
        (await handler(_ctx(headers: {'x-forwarded-for': '10.0.0.1'})))
            .statusCode,
        HttpStatus.ok,
      );
      expect(
        (await handler(_ctx(headers: {'x-forwarded-for': '10.0.0.1'})))
            .statusCode,
        HttpStatus.ok,
      );
      expect(
        (await handler(_ctx(headers: {'x-forwarded-for': '10.0.0.1'})))
            .statusCode,
        HttpStatus.tooManyRequests,
      );
      expect(
        (await handler(_ctx(headers: {'x-forwarded-for': '10.0.0.2'})))
            .statusCode,
        HttpStatus.ok,
      );
    });

    test('non-auth routes are not rate limited', () async {
      final handler = rateLimiter(
        limits: {'login': 1},
        window: const Duration(minutes: 1),
      )((c) async => Response.json(body: {'ok': true}));

      expect((await handler(_ctx(path: '/health'))).statusCode, HttpStatus.ok);
      expect((await handler(_ctx(path: '/health'))).statusCode, HttpStatus.ok);
    });
  });
}
