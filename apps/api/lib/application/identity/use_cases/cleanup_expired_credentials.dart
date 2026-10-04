import 'package:paseo_api/application/identity/ports.dart';

/// Worker: borra OTPs, reset tokens y refresh tokens expirados (T033).
final class CleanupExpiredCredentials {
  const new({
    required this.verificationCodes,
    required this.passwordResets,
    required this.refreshTokens,
    required this.clock,
  });

  final VerificationCodeRepository verificationCodes;
  final PasswordResetRepository passwordResets;
  final RefreshTokenRepository refreshTokens;
  final Clock clock;

  /// Ejecuta el barrido. Devuelve cuántos registros eliminó por tabla.
  Future<Map<String, int>> call() async {
    final now = clock.nowUtc();
    final vc = await verificationCodes.deleteExpired(now);
    final pr = await passwordResets.deleteExpired(now);
    final rt = await refreshTokens.deleteExpired(now);
    return {
      'verification_codes': vc,
      'password_resets': pr,
      'refresh_tokens': rt,
    };
  }
}
