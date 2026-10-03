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
