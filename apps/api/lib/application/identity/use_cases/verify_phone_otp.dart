import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';

/// US1: verificacion del telefono con OTP (FR-004).
final class VerifyPhoneOtp {
  const new({
    required this._customers,
    required VerificationCodeRepository codes,
    required this._hasher,
    required this._clock,
    required this._audit,
  }) : _codes = codes;

  final CustomerRepository _customers;
  final VerificationCodeRepository _codes;
  final PasswordHasher _hasher;
  final Clock _clock;
  final AuditLogWriter _audit;

  /// Marca `pv=true`. Lanza `OTP_INVALID | OTP_EXPIRED |
  /// OTP_TOO_MANY_ATTEMPTS | VALIDATION_FAILED`.
  Future<void> call({required String phone, required String code}) async {
    final parsedPhone = PhoneBO.parse(phone);
    if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      throw IdentityException.validation('codigo de 6 digitos');
    }
    final now = _clock.nowUtc();
    final record = await _codes.findActive(
      target: parsedPhone.value,
      purpose: VerificationPurpose.phoneVerification,
      now: now,
    );
    final challenge = record?.challenge;
    if (record == null || challenge is! OtpChallenge) {
      throw IdentityException.otpInvalid();
    }

    final matches = await _hasher.verify(hash: record.codeHash, plain: code);
    if (!matches) {
      // Incrementa intentos (o lanza OTP_TOO_MANY_ATTEMPTS/OTP_EXPIRED).
      await _codes.updateChallenge(
        record.id,
        challenge.verify(now, matches: false),
      );
      throw IdentityException.otpInvalid();
    }
    await _codes.updateChallenge(
      record.id,
      challenge.verify(now, matches: true),
    );

    final profile = await _customers.findByPhone(parsedPhone);
    if (profile == null) throw IdentityException.otpInvalid();
    await _customers.markPhoneVerified(userId: profile.userId, at: now);
    await _audit.write(
      action: 'auth.phone.verify',
      entityType: 'customer',
      entityId: profile.userId,
      userId: profile.userId,
    );
  }
}
