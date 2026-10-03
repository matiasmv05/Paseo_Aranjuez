import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';

/// US1: registro de cliente (FR-001, FR-002).
/// Crea la cuenta con `pv=false`, envia OTP (SMS) y correo de verificacion.
final class RegisterCustomer {
  const RegisterCustomer({
    required UserRepository users,
    required CustomerRepository customers,
    required VerificationCodeRepository codes,
    required PasswordHasher hasher,
    required OtpSender otpSender,
    required EmailSender emailSender,
    required TokenGenerator tokens,
    required IdGenerator ids,
    required Clock clock,
    required AuditLogWriter audit,
    required TransactionRunner tx,
  }) : _users = users,
       _customers = customers,
       _codes = codes,
       _hasher = hasher,
       _otpSender = otpSender,
       _emailSender = emailSender,
       _tokens = tokens,
       _ids = ids,
       _clock = clock,
       _audit = audit,
       _tx = tx;

  static const emailVerificationTokenBytes = 32;

  final UserRepository _users;
  final CustomerRepository _customers;
  final VerificationCodeRepository _codes;
  final PasswordHasher _hasher;
  final OtpSender _otpSender;
  final EmailSender _emailSender;
  final TokenGenerator _tokens;
  final IdGenerator _ids;
  final Clock _clock;
  final AuditLogWriter _audit;
  final TransactionRunner _tx;

  /// Devuelve el `customer_id` creado.
  Future<String> call({
    required String email,
    required String phone,
    required String password,
    String? fullName,
  }) async {
    final parsedEmail = Email.parse(email);
    final parsedPhone = PhoneBO.parse(phone); // PHONE_NOT_SUPPORTED (FR-002)
    PasswordPolicy.validate(password);

    final passwordHash = await _hasher.hash(password);
    final userId = _ids.newId();
    // Una transaccion: si el telefono esta duplicado no queda un `users`
    // huerfano que bloquee el reintento con el mismo correo (R1).
    await _tx.run(() async {
      final user = await _users.insertIfAbsent(
        id: userId,
        email: parsedEmail,
        passwordHash: passwordHash,
        role: UserRole.customer,
      );
      if (user == null) {
        throw IdentityException.conflict('correo ya registrado');
      }
      final profile = CustomerProfile(
        userId: userId,
        phone: parsedPhone.value,
        fullName: fullName,
      );
      final inserted = await _customers.insertIfAbsent(profile);
      if (inserted == null) {
        throw IdentityException.conflict('telefono ya registrado');
      }
    });

    final now = _clock.nowUtc();

    // OTP por SMS (minimo obligatorio, FR-001). Solo hash en base.
    final otp = _tokens.randomOtp();
    await _codes.insert(
      id: _ids.newId(),
      target: parsedPhone.value,
      purpose: VerificationPurpose.phoneVerification,
      codeHash: await _hasher.hash(otp),
      challenge: OtpChallenge.issue(now),
    );
    await _otpSender.sendOtp(phone: parsedPhone, code: otp);

    // Correo de verificacion (habilita recuperacion; no bloquea acumulacion).
    final emailToken = _tokens.randomToken(emailVerificationTokenBytes);
    await _codes.insert(
      id: _ids.newId(),
      target: parsedEmail.value,
      purpose: VerificationPurpose.emailVerification,
      codeHash: _tokens.hashToken(emailToken),
      challenge: EmailVerification.issue(now),
    );
    await _emailSender.sendEmailVerification(
      email: parsedEmail,
      token: emailToken,
    );

    await _audit.write(
      action: 'auth.register',
      entityType: 'customer',
      entityId: userId,
      userId: userId,
    );
    return userId;
  }
}
