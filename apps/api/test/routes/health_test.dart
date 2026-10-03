import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/health.dart';

class _MockRequestContext extends Mock implements RequestContext;

void main() {
  group('GET /health', () {
    test('responde 200 {"status":"ok"}', () async {
      final context = _MockRequestContext();
      when(() => context.request)
          .thenReturn(Request('GET', Uri.parse('http://localhost/health')));

      final response = onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.headers['content-type'], contains('application/json'));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body, equals({'status': 'ok'}));
    });

    test('responde 405 problem+json con otro método', () async {
      final context = _MockRequestContext();
      when(() => context.request)
          .thenReturn(Request('POST', Uri.parse('http://localhost/health')));

      final response = onRequest(context);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      expect(
        response.headers['content-type'],
        contains('application/problem+json'),
      );
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('METHOD_NOT_ALLOWED'));
    });
  });
}
