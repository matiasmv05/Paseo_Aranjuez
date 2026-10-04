import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';

/// US1: reenvio del OTP (`POST /auth/phone/send-otp`, FR-004).
/// Cooldown de 60 s y tope diario por telefono.
final class ResendPhoneOtp {
  const new({
    required this._codes,
    required CustomerRepository customers,
    required this._hasher,
    required this._otpSender,
    required this._tokens,
    required this._ids,
    required this._clock,
    required this._audit,
    this.dailyLimit = 10,
  }) : _customers = customers;

  final VerificationCodeRepository _codes;
  final CustomerRepository _customers;
  final PasswordHasher _hasher;
  final OtpSender _otpSender;
  final TokenGenerator _tokens;
  final IdGenerator _ids;
  final Clock _clock;
  final AuditLogWriter _audit;

  /// Tope diario de OTPs por telefono (constante documentada; configurable
  /// via `system_settings` cuando exista).
  final int dailyLimit;

  Future<void> call({required String phone}) async {
    final parsedPhone = PhoneBO.parse(phone);
    final profile = await _customers.findByPhone(parsedPhone);
    // No revela existencia: sin cuenta, no hay reenvio (ni error distinto).
    if (profile == null) return;
    if (profile.phoneVerified) return;

    final now = _clock.nowUtc();
    final latest = await _codes.findLatest(
      target: parsedPhone.value,
      purpose: VerificationPurpose.phoneVerification,
    );
    if (latest != null &&
        !OtpChallenge.canResend(latest.challenge.createdAt, now)) {
      throw IdentityException.otpRateLimited();
    }
    final dayAgo = now.subtract(const Duration(days: 1));
    final issued = await _codes.countIssuedSince(
      target: parsedPhone.value,
      since: dayAgo,
    );
    if (issued >= dailyLimit) throw IdentityException.otpRateLimited();

    final otp = _tokens.randomOtp();
    await _codes.insert(
      id: _ids.newId(),
      target: parsedPhone.value,
      purpose: VerificationPurpose.phoneVerification,
      codeHash: await _hasher.hash(otp),
      challenge: OtpChallenge.issue(now),
    );
    await _otpSender.sendOtp(phone: parsedPhone, code: otp);
    await _audit.write(
      action: 'auth.phone.send-otp',
      entityType: 'customer',
      entityId: profile.userId,
      userId: profile.userId,
    );
  }
}
