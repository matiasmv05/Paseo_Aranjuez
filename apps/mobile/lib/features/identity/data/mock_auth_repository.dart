import '../domain/auth_repository.dart';

/// Implementación simulada: OTP válido solo si el código es '123456'.
class MockAuthRepository implements AuthRepository {
  @override
  Future<void> sendOtp(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<bool> verifyOtp(String phone, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return code == '123456';
  }
}
