import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/ready.dart';

class _MockRequestContext extends Mock implements RequestContext;

void main() {
  group('GET /ready', () {
    test('200 {"status":"ready"} cuando el check devuelve true', () async {
      final context = _MockRequestContext();
      when(() => context.request)
          .thenReturn(Request('GET', Uri.parse('http://localhost/ready')));
      when(() => context.read<Future<bool> Function()>())
          .thenReturn(() async => true);

      final response = await onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body, equals({'status': 'ready'}));
    });

    test(
      '503 problem+json (SERVICE_UNAVAILABLE) cuando el check falla',
      () async {
        final context = _MockRequestContext();
        when(() => context.request)
            .thenReturn(Request('GET', Uri.parse('http://localhost/ready')));
        when(() => context.read<Future<bool> Function()>())
            .thenReturn(() async => false);

        final response = await onRequest(context);

        expect(response.statusCode, equals(HttpStatus.serviceUnavailable));
        expect(
          response.headers['content-type'],
          contains('application/problem+json'),
        );
        final body = jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(body['code'], equals('SERVICE_UNAVAILABLE'));
        expect(body['status'], equals(HttpStatus.serviceUnavailable));
      },
    );
  });
}
