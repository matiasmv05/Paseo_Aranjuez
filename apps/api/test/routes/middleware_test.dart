import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/_middleware.dart';

class _MockRequestContext extends Mock implements RequestContext;

RequestContext _context({Map<String, String> headers = const {}}) {
  final context = _MockRequestContext();
  when(() => context.request).thenReturn(
    Request('GET', Uri.parse('http://localhost/health'), headers: headers),
  );
  when(() => context.provide<Future<bool> Function()>(any()))
      .thenReturn(context);
  return context;
}

void main() {
  group('middleware global', () {
    test('propaga la respuesta y añade x-correlation-id', () async {
      final handler = middleware(
        (context) async => Response.json(body: {'status': 'ok'}),
      );

      final response = await handler(_context());

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.headers['x-correlation-id'], isNotNull);
    });

    test('respeta x-correlation-id entrante', () async {
      final handler = middleware(
        (context) async => Response.json(body: {'status': 'ok'}),
      );

      final response = await handler(
        _context(headers: {'x-correlation-id': 'corr-123'}),
      );

      expect(response.headers['x-correlation-id'], equals('corr-123'));
    });

    test(
      'excepción no controlada → 500 problem+json con code estable',
      () async {
        final handler = middleware((context) async => throw StateError('boom'));

        final response = await handler(_context());

        expect(response.statusCode, equals(HttpStatus.internalServerError));
        expect(
          response.headers['content-type'],
          contains('application/problem+json'),
        );
        final body = jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(body['code'], equals('INTERNAL_ERROR'));
        expect(body['type'], equals('about:blank'));
        expect(body['status'], equals(HttpStatus.internalServerError));
        expect(body['correlation_id'], isNotNull);
      },
    );
  });
}
