import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:paseo_api/application/identity/ports.dart';

/// Argon2id password hasher using `cryptography` 2.9.0.
/// Runs in Isolate per SEC-001. PHC format with OWASP parameters:
/// m=19456 KiB (19 MiB), t=2, p=1, salt 16 bytes, hash 32 bytes.
final class Argon2idPasswordHasher implements PasswordHasher {
  static const _memoryKib = 19456; // 19 MiB
  static const _iterations = 2;
  static const _parallelism = 1;
  static const _saltLength = 16;
  static const _hashLength = 32;
  static const _phcPrefix = '\$argon2id\$v=19\$m=19456,t=2,p=1';

  final Argon2id _argon2id = Argon2id(
    memory: _memoryKib,
    iterations: _iterations,
    parallelism: _parallelism,
    hashLength: _hashLength,
  );

  @override
  Future<String> hash(String plain) async {
    return Isolate.run<String>(() async {
      final salt = _generateSalt();
      final secretKey = await _argon2id.deriveKey(
        secretKey: SecretKey(utf8.encode(plain)),
        nonce: salt,
      );
      final hashBytes = Uint8List.fromList(await secretKey.extractBytes());
      return _encodePHC(salt, hashBytes);
    });
  }

  @override
  Future<bool> verify({required String hash, required String plain}) async {
    return Isolate.run<bool>(() async {
      try {
        final (salt, expectedHash) = _decodePHC(hash);
        final secretKey = await _argon2id.deriveKey(
          secretKey: SecretKey(utf8.encode(plain)),
          nonce: salt,
        );
        final actualHash = Uint8List.fromList(await secretKey.extractBytes());
        return _constantTimeEquals(expectedHash, actualHash);
      } on FormatException {
        return false;
      }
    });
  }

  /// Generate cryptographically secure random salt.
  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => random.nextInt(256)),
    );
  }

  /// Encode salt and hash into PHC string format.
  String _encodePHC(Uint8List salt, Uint8List hash) {
    final saltB64 = base64.encode(salt);
    final hashB64 = base64.encode(hash);
    return '$_phcPrefix\$${saltB64}\$${hashB64}';
  }

  /// Decode PHC string into (salt, hash) bytes.
  /// Expected format: $argon2id$v=19$m=19456,t=2,p=1$salt_b64$hash_b64
  (Uint8List, Uint8List) _decodePHC(String phc) {
    if (!phc.startsWith('\$argon2id\$v=19\$m=19456,t=2,p=1\$')) {
      throw const FormatException(
        'Invalid PHC format: wrong algorithm or parameters',
      );
    }
    final parts = phc.split('\$');
    if (parts.length != 6) {
      throw const FormatException('Invalid PHC format: expected 6 parts');
    }
    final saltBytes = base64.decode(parts[4]);
    final hashBytes = base64.decode(parts[5]);
    if (saltBytes.length != _saltLength) {
      throw const FormatException('Invalid salt length');
    }
    if (hashBytes.length != _hashLength) {
      throw const FormatException('Invalid hash length');
    }
    return (saltBytes, hashBytes);
  }

  /// Constant-time comparison to prevent timing attacks.
  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
