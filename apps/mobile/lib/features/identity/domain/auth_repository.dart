/// Puerto del flujo de identidad: envío y verificación de OTP.
abstract class AuthRepository {
  Future<void> sendOtp(String phone);

  Future<bool> verifyOtp(String phone, String code);
}
