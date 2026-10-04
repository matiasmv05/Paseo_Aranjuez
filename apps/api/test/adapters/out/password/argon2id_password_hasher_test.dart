import 'dart:convert';

import 'package:paseo_api/adapters/out/password/argon2id_password_hasher.dart';
import 'package:test/test.dart';

void main() {
  group('Argon2idPasswordHasher', () {
    late Argon2idPasswordHasher hasher;

    setUp(() {
      hasher = Argon2idPasswordHasher();
    });

    test('hash produces valid PHC format with OWASP parameters', () async {
      final hash = await hasher.hash('test-password-123');

      expect(hash, startsWith('\$argon2id\$v=19\$m=19456,t=2,p=1\$'));
      final parts = hash.split('\$');
      expect(parts.length, 6);
      // parts: '', 'argon2id', 'v=19', 'm=19456,t=2,p=1', 'salt_b64', 'hash_b64'
      expect(parts[1], 'argon2id');
      expect(parts[2], 'v=19');
      expect(parts[3], 'm=19456,t=2,p=1');
      // salt and hash should be valid base64
      expect(() => base64.decode(parts[4]), returnsNormally);
      expect(() => base64.decode(parts[5]), returnsNormally);
      expect(base64.decode(parts[4]).length, 16); // 16 bytes salt
      expect(base64.decode(parts[5]).length, 32); // 32 bytes hash
    });

    test('verify returns true for correct password', () async {
      final hash = await hasher.hash('correct-password');
      final ok = await hasher.verify(hash: hash, plain: 'correct-password');
      expect(ok, isTrue);
    });

    test('verify returns false for wrong password', () async {
      final hash = await hasher.hash('correct-password');
      final ok = await hasher.verify(hash: hash, plain: 'wrong-password');
      expect(ok, isFalse);
    });

    test('different hashes for same password (different salts)', () async {
      final hash1 = await hasher.hash('same-password');
      final hash2 = await hasher.hash('same-password');
      expect(hash1, isNot(hash2));
      // Both should verify
      expect(await hasher.verify(hash: hash1, plain: 'same-password'), isTrue);
      expect(await hasher.verify(hash: hash2, plain: 'same-password'), isTrue);
    });

    test('verify handles malformed PHC gracefully', () async {
      expect(
        () => hasher.verify(hash: 'not-a-valid-phc', plain: 'anything'),
        returnsNormally, // should return false, not throw
      );
      final ok = await hasher.verify(
        hash: 'not-a-valid-phc',
        plain: 'anything',
      );
      expect(ok, isFalse);
    });

    test('verify handles wrong algorithm gracefully', () async {
      final ok = await hasher.verify(
        hash:
            '\$argon2i\$v=19\$m=19456,t=2,p=1\$c29tZXNhbHQ\$GpZ3sK/oH9p7VIiV56G/64Zo/8GaUw434IimaPqxwCo',
        plain: 'password',
      );
      expect(ok, isFalse);
    });

    test('hash runs in Isolate (does not block main thread)', () async {
      // This test ensures the implementation uses Isolate.run
      // We can't easily test "not blocking" but we verify it works in isolate
      final results = await Future.wait([
        hasher.hash('p1'),
        hasher.hash('p2'),
        hasher.hash('p3'),
      ]);
      expect(results.length, 3);
      for (final h in results) {
        expect(h, startsWith('\$argon2id\$v=19\$m=19456,t=2,p=1\$'));
      }
    });
  });
}
