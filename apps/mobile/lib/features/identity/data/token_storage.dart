import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Puerto para persistir el token JWT de la sesión del cliente.
abstract class TokenStorage {
  Future<void> saveToken(String token);

  Future<String?> getToken();

  Future<void> deleteToken();
}

/// Implementación con el almacenamiento seguro del dispositivo
/// (Keychain / Keystore / etc. vía `flutter_secure_storage`).
final class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _keyToken = 'paseo.jwt';

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  @override
  Future<String?> getToken() => _storage.read(key: _keyToken);

  @override
  Future<void> deleteToken() => _storage.delete(key: _keyToken);
}

/// Implementación en memoria (desarrollo/tests sin plataforma nativa).
final class InMemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> deleteToken() async {
    _token = null;
  }
}
