/// Puerto del flujo de identidad: envío y verificación de OTP.
abstract class AuthRepository {
  Future<void> sendOtp(String phone);

  /// Devuelve el token de sesión si el OTP es válido; `null` si no.
  Future<String?> verifyOtp(String phone, String code);
}
