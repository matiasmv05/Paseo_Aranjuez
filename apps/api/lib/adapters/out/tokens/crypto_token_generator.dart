import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:paseo_api/application/identity/ports.dart';

/// Tokens aleatorios (criptograficos) + hash SHA-256 hex (determinista).
final class CryptoTokenGenerator implements TokenGenerator {
  const CryptoTokenGenerator();

  @override
  String randomToken(int bytes) {
    final rng = Random.secure();
    final data = List<int>.generate(bytes, (_) => rng.nextInt(256));
    return base64Url.encode(data).replaceAll('=', '');
  }

  @override
  String randomOtp() {
    final rng = Random.secure();
    return List<int>.generate(6, (_) => rng.nextInt(10)).join();
  }

  @override
  String hashToken(String token) {
    return sha256.convert(utf8.encode(token)).toString();
  }
}
