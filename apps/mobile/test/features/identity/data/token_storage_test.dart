import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paseo_mobile/features/identity/data/token_storage.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SecureTokenStorage', () {
    late MockSecureStorage raw;
    late SecureTokenStorage storage;

    setUp(() {
      raw = MockSecureStorage();
      storage = SecureTokenStorage(storage: raw);
    });

    test('saveToken escribe el token bajo la key de sesión', () async {
      when(
        () => raw.write(key: 'paseo.jwt', value: 'jwt-token-123'),
      ).thenAnswer((_) async {});

      await storage.saveToken('jwt-token-123');

      verify(
        () => raw.write(key: 'paseo.jwt', value: 'jwt-token-123'),
      ).called(1);
    });

    test('getToken lee el token guardado', () async {
      when(
        () => raw.read(key: 'paseo.jwt'),
      ).thenAnswer((_) async => 'jwt-token-123');

      final token = await storage.getToken();

      expect(token, equals('jwt-token-123'));
      verify(() => raw.read(key: 'paseo.jwt')).called(1);
    });

    test('getToken devuelve null cuando no hay token', () async {
      when(() => raw.read(key: 'paseo.jwt')).thenAnswer((_) async => null);

      expect(await storage.getToken(), isNull);
    });

    test('deleteToken borra el token guardado', () async {
      when(() => raw.delete(key: 'paseo.jwt')).thenAnswer((_) async {});

      await storage.deleteToken();

      verify(() => raw.delete(key: 'paseo.jwt')).called(1);
    });
  });
}
