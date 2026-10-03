import 'package:paseo_api/adapters/out/clock/system_clock.dart';
import 'package:paseo_api/adapters/out/postgres/postgres.dart';
import 'package:paseo_api/application/identity/use_cases/cleanup_expired_credentials.dart';

/// Worker standalone: job horario CleanupExpiredCredentials.
Future<void> main(List<String> args) async {
  final deps = await PgDatabase.open(PgConfig.fromEnvironment());
  final codes = PostgresVerificationCodeRepository(deps);
  final resets = PostgresPasswordResetRepository(deps);
  final refresh = PostgresRefreshTokenRepository(deps);
  const clock = SystemClock();
  final job = CleanupExpiredCredentials(
    verificationCodes: codes,
    passwordResets: resets,
    refreshTokens: refresh,
    clock: clock,
  );
  Future<void> tick() async {
    try {
      final r = await job();
      print(
        '[worker] cleanup ok: ${r.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
      );
    } on Object catch (e) {
      print('[worker] cleanup failed: $e');
    }
  }

  // Ejecuta al arrancar y luego cada hora.
  await tick();
  while (true) {
    await Future<void>.delayed(const Duration(hours: 1), tick);
  }
}
