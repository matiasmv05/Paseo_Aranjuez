import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paseo_api/adapters/in/auth_use_cases.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:test/test.dart';

import '../../routes/auth/register.dart' as route;

class _MockContext extends Mock implements RequestContext {}

class _FakeAuthUseCases extends Mock implements AuthUseCases {}

RequestContext _ctx(Object body, AuthUseCases useCases) {
  final ctx = _MockContext();
  when(() => ctx.request).thenReturn(
    Request(
      'POST',
      Uri.parse('http://localhost/auth/register'),
      headers: {'content-type': 'application/json', 'x-correlation-id': 'c1'},
      body: jsonEncode(body),
    ),
  );
  when(
    () => ctx.read<Future<AuthUseCases>>(),
  ).thenAnswer((_) async => useCases);
  return ctx;
}

void main() {
  group('POST /auth/register', () {
    test('201 on success', () async {
      final useCases = _FakeAuthUseCases();
      when(() => useCases.registerCustomer).thenReturn(
        ({
          required String email,
          required String phone,
          required String password,
          String? fullName,
        }) async => 'customer-1',
      );

      final res = await route.onRequest(
        _ctx({
          'email': 'a@b.com',
          'phone': '+59160000000',
          'password': 'password123',
        }, useCases),
      );

      expect(res.statusCode, HttpStatus.created);
      final json = jsonDecode(await res.body()) as Map<String, dynamic>;
      expect(json['customer_id'], 'customer-1');
      expect(json['phone_verified'], isFalse);
    });

    test('422 on invalid JSON body', () async {
      final useCases = _FakeAuthUseCases();
      final res = await route.onRequest(_ctx('not-json', useCases));
      expect(res.statusCode, HttpStatus.unprocessableEntity);
    });

    test('409 on duplicate email (CONFLICT)', () async {
      final useCases = _FakeAuthUseCases();
      when(() => useCases.registerCustomer).thenReturn(
        ({
          required String email,
          required String phone,
          required String password,
          String? fullName,
        }) async => throw IdentityException.conflict('correo ya registrado'),
      );

      final res = await route.onRequest(
        _ctx({
          'email': 'a@b.com',
          'phone': '+59160000000',
          'password': 'password123',
        }, useCases),
      );

      expect(res.statusCode, HttpStatus.conflict);
      final json = jsonDecode(await res.body()) as Map<String, dynamic>;
      expect(json['code'], 'CONFLICT');
    });

    test('405 on GET', () async {
      final useCases = _FakeAuthUseCases();
      final ctx = _MockContext();
      when(
        () => ctx.request,
      ).thenReturn(Request('GET', Uri.parse('http://localhost/auth/register')));
      when(
        () => ctx.read<Future<AuthUseCases>>(),
      ).thenAnswer((_) async => useCases);

      final res = await route.onRequest(ctx);
      expect(res.statusCode, HttpStatus.methodNotAllowed);
    });
  });
}
