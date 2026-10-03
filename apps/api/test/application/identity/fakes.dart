import 'package:mocktail/mocktail.dart';
import 'package:paseo_api/application/identity/ports.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockCustomerRepository extends Mock implements CustomerRepository {}

class MockVerificationCodeRepository extends Mock
    implements VerificationCodeRepository {}

class MockPasswordResetRepository extends Mock
    implements PasswordResetRepository {}

class MockRefreshTokenRepository extends Mock
    implements RefreshTokenRepository {}

class MockAuditLogWriter extends Mock implements AuditLogWriter {}

class MockPasswordHasher extends Mock implements PasswordHasher {}

class MockTokenSigner extends Mock implements TokenSigner {}

class MockOtpSender extends Mock implements OtpSender {}

class MockEmailSender extends Mock implements EmailSender {}

class MockClock extends Mock implements Clock {}

class MockIdGenerator extends Mock implements IdGenerator {}

class MockTokenGenerator extends Mock implements TokenGenerator {}

/// TransactionRunner trivial (sin rollback): ejecuta el cuerpo tal cual.
final class PassThroughTx implements TransactionRunner {
  @override
  Future<T> run<T>(Future<T> Function() body) => body();
}

/// Almacen en memoria con snapshot/restore para simular rollback.
abstract interface class RollbackStore<T> {
  T snapshot();
  void restore(T state);
}

/// TransactionRunner con rollback simulado: si el cuerpo lanza, restaura
/// el snapshot de cada almacen registrado.
final class FakeTransactionRunner implements TransactionRunner {
  final _stores = <RollbackStore<Object?>>[];

  void register(RollbackStore<Object?> store) => _stores.add(store);

  var committed = false;
  var rolledBack = false;

  @override
  Future<T> run<T>(Future<T> Function() body) async {
    final snapshots = [for (final s in _stores) (s, s.snapshot())];
    try {
      final result = await body();
      committed = true;
      return result;
    } catch (_) {
      for (final (store, snap) in snapshots) {
        store.restore(snap);
      }
      rolledBack = true;
      rethrow;
    }
  }
}

/// Reloj fijo para tests.
final class FixedClock implements Clock {
  FixedClock(this.now);

  final DateTime now;

  @override
  DateTime nowUtc() => now;
}

/// Generadores secuenciales deterministas.
final class SequentialIds implements IdGenerator {
  int _n = 0;

  @override
  String newId() => 'id-${++_n}';
}

/// TokenGenerator falso: tokens predecibles y hash con prefijo.
final class FakeTokenGenerator implements TokenGenerator {
  int _n = 0;

  String lastOtp = '';

  @override
  String randomToken(int bytes) {
    assert(bytes >= 32, 'tokens de al menos 32 bytes');
    return 'tok-${++_n}';
  }

  @override
  String randomOtp() => lastOtp = '123456';

  @override
  String hashToken(String token) => 'sha:$token';
}

/// Hasher falso: hash reversible para poder verificar.
final class FakeHasher implements PasswordHasher {
  @override
  Future<String> hash(String plain) async => 'phc:$plain';

  @override
  Future<bool> verify({required String hash, required String plain}) async =>
      hash == 'phc:$plain';
}
