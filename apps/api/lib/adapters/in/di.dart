import 'dart:io';

import 'package:paseo_api/adapters/in/auth_use_cases.dart';
import 'package:paseo_api/adapters/in/merchant_use_cases.dart';
import 'package:paseo_api/adapters/out/auth/identification_signer.dart';
import 'package:paseo_api/adapters/out/auth/jwt_token_signer.dart';
import 'package:paseo_api/adapters/out/auth/jwt_token_verifier.dart';
import 'package:paseo_api/adapters/out/clock/system_clock.dart';
import 'package:paseo_api/adapters/out/email/console_email_sender.dart';
import 'package:paseo_api/adapters/out/email/smtp_email_sender.dart';
import 'package:paseo_api/adapters/out/otp/console_otp_sender.dart';
import 'package:paseo_api/adapters/out/password/argon2id_password_hasher.dart';
import 'package:paseo_api/adapters/out/postgres/postgres.dart';
import 'package:paseo_api/adapters/out/rate_limit/establishment_rate_limiter.dart';
import 'package:paseo_api/adapters/out/tokens/crypto_token_generator.dart';
import 'package:paseo_api/adapters/out/tokens/uuid_id_generator.dart';
import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/application/identity/use_cases/forgot_password.dart';
import 'package:paseo_api/application/identity/use_cases/login.dart';
import 'package:paseo_api/application/identity/use_cases/logout.dart';
import 'package:paseo_api/application/identity/use_cases/refresh_session.dart';
import 'package:paseo_api/application/identity/use_cases/register_customer.dart';
import 'package:paseo_api/application/identity/use_cases/resend_phone_otp.dart';
import 'package:paseo_api/application/identity/use_cases/reset_password.dart';
import 'package:paseo_api/application/identity/use_cases/verify_email.dart';
import 'package:paseo_api/application/identity/use_cases/verify_phone_otp.dart';
import 'package:paseo_api/application/merchant/use_cases/identify_customer.dart';
import 'package:paseo_api/application/merchant/use_cases/list_movements.dart';
import 'package:paseo_api/application/merchant/use_cases/preview_purchase.dart';
import 'package:paseo_api/application/merchant/use_cases/register_purchase.dart';
import 'package:paseo_api/domain/loyalty/points_calculator.dart';
import 'package:paseo_api/domain/loyalty/rule_resolver.dart';

/// Grafo de dependencias de la API construido a partir del entorno.
/// Un singleton por proceso (single isolate de dart_frog).
final class AppDependencies implements AuthUseCases, MerchantUseCases {
  AppDependencies._({
    required this.db,
    required this.users,
    required this.customers,
    required this.codes,
    required this.resets,
    required this.refreshTokens,
    required this.audit,
    required this.establishments,
    required this.pointsRules,
    required this.purchases,
    required this.movements,
    required this.ticketSigner,
    required this.verifier,
    required this.rateLimiter,
    required this.merchant,
    required this.tx,
    required this.hasher,
    required this.signer,
    required this.otpSender,
    required this.emailSender,
    required this.tokens,
    required this.ids,
    required this.clock,
    required this.registerCustomer,
    required this.verifyPhoneOtp,
    required this.resendPhoneOtp,
    required this.verifyEmail,
    required this.login,
    required this.refreshSession,
    required this.logout,
    required this.forgotPassword,
    required this.resetPassword,
  });

  static AppDependencies? _instance;

  /// Construye (una vez) el grafo completo conectando a PostgreSQL.
  static Future<AppDependencies> open() async {
    final existing = _instance;
    if (existing != null) return existing;

    final db = await PgDatabase.open(PgConfig.fromEnvironment());
    final users = PostgresUserRepository(db);
    final customers = PostgresCustomerRepository(db);
    final codes = PostgresVerificationCodeRepository(db);
    final resets = PostgresPasswordResetRepository(db);
    final refreshTokens = PostgresRefreshTokenRepository(db);
    final audit = PostgresAuditLogWriter(db);
    final tx = PostgresTransactionRunner(db);

    final hasher = Argon2idPasswordHasher();
    const tokens = CryptoTokenGenerator();
    const ids = UuidIdGenerator();
    const clock = SystemClock();
    final env = Platform.environment;
    final signer = JwtTokenSigner(
      secret: env['JWT_SECRET'] ?? '',
      kid: env['JWT_KID'] ?? 'dev-key-1',
    );
    final OtpSender otpSender = switch (env['OTP_SENDER'] ?? 'console') {
      'console' => ConsoleOtpSender(),
      _ => throw StateError(
        'OTP_SENDER no soportado (por decidir; AGENTS.md §15)',
      ),
    };
    final EmailSender emailSender = switch (env['EMAIL_SENDER'] ?? 'console') {
      'console' => ConsoleEmailSender(),
      'smtp' => SmtpEmailSender(config: SmtpConfig.fromEnv()),
      _ => throw StateError('EMAIL_SENDER desconocido'),
    };
    final registerCustomer = RegisterCustomer(
      users: users,
      customers: customers,
      codes: codes,
      hasher: hasher,
      otpSender: otpSender,
      emailSender: emailSender,
      tokens: tokens,
      ids: ids,
      clock: clock,
      audit: audit,
      tx: tx,
    );
    final verifyPhoneOtp = VerifyPhoneOtp(
      customers: customers,
      codes: codes,
      hasher: hasher,
      clock: clock,
      audit: audit,
    );
    final resendPhoneOtp = ResendPhoneOtp(
      codes: codes,
      customers: customers,
      hasher: hasher,
      otpSender: otpSender,
      tokens: tokens,
      ids: ids,
      clock: clock,
      audit: audit,
    );
    final verifyEmail = VerifyEmail(
      users: users,
      codes: codes,
      tokens: tokens,
      clock: clock,
      audit: audit,
    );
    final login = Login(
      users: users,
      customers: customers,
      refreshTokens: refreshTokens,
      hasher: hasher,
      signer: signer,
      tokens: tokens,
      ids: ids,
      clock: clock,
      audit: audit,
    );
    final refreshSession = RefreshSession(
      users: users,
      customers: customers,
      refreshTokens: refreshTokens,
      signer: signer,
      tokens: tokens,
      ids: ids,
      clock: clock,
      login: login,
    );
    final logout = Logout(
      refreshTokens: refreshTokens,
      tokens: tokens,
      clock: clock,
      audit: audit,
    );
    final forgotPassword = ForgotPassword(
      users: users,
      resets: resets,
      emailSender: emailSender,
      tokens: tokens,
      ids: ids,
      clock: clock,
      audit: audit,
    );
    final resetPassword = ResetPassword(
      users: users,
      resets: resets,
      refreshTokens: refreshTokens,
      hasher: hasher,
      tokens: tokens,
      clock: clock,
      audit: audit,
      tx: tx,
    );

    // Panel del comercio (HU-10/11/13, feature 003).
    final establishments = PostgresEstablishmentRepository(db);
    final pointsRules = PostgresPointsRuleRepository(db);
    final purchases = PostgresPurchaseRepository(db);
    final movements = PostgresMovementRepository(db);
    final ticketSigner = IdentificationSigner(
      secret: env['IDENTIFICATION_SECRET'] ?? '',
    );
    final verifier = JwtTokenVerifier(secret: env['JWT_SECRET'] ?? '');
    final rateLimiter = EstablishmentRateLimiter(clock: clock);
    const resolver = RuleResolver();
    const calculator = PointsCalculator();
    final identifyCustomer = IdentifyCustomer(
      establishments: establishments,
      signer: ticketSigner,
      clock: clock,
    );
    final previewPurchase = PreviewPurchase(
      signer: ticketSigner,
      rules: pointsRules,
      resolver: resolver,
      calculator: calculator,
      clock: clock,
    );
    final registerPurchase = RegisterPurchase(
      signer: ticketSigner,
      rules: pointsRules,
      resolver: resolver,
      calculator: calculator,
      purchases: purchases,
      clock: clock,
    );
    final listMovements = ListMovements(movements: movements);
    final merchant = MerchantDependencies(
      identifyCustomer: identifyCustomer.call,
      previewPurchase: previewPurchase.call,
      registerPurchase: registerPurchase.call,
      listMovements: listMovements.call,
      verifier: verifier,
      users: users,
      establishments: establishments,
      rateLimiter: rateLimiter,
      clock: clock,
    );

    return _instance = AppDependencies._(
      db: db,
      users: users,
      customers: customers,
      codes: codes,
      resets: resets,
      refreshTokens: refreshTokens,
      audit: audit,
      establishments: establishments,
      pointsRules: pointsRules,
      purchases: purchases,
      movements: movements,
      ticketSigner: ticketSigner,
      verifier: verifier,
      rateLimiter: rateLimiter,
      merchant: merchant,
      tx: tx,
      hasher: hasher,
      signer: signer,
      otpSender: otpSender,
      emailSender: emailSender,
      tokens: tokens,
      ids: ids,
      clock: clock,
      registerCustomer: registerCustomer.call,
      verifyPhoneOtp: verifyPhoneOtp.call,
      resendPhoneOtp: resendPhoneOtp.call,
      verifyEmail: verifyEmail.call,
      login: login.call,
      refreshSession: refreshSession.call,
      logout: logout.call,
      forgotPassword: forgotPassword.call,
      resetPassword: resetPassword.call,
    );
  }

  final PgDatabase db;
  final PostgresUserRepository users;
  final PostgresCustomerRepository customers;
  final PostgresVerificationCodeRepository codes;
  final PostgresPasswordResetRepository resets;
  final PostgresRefreshTokenRepository refreshTokens;
  final PostgresAuditLogWriter audit;
  final PostgresEstablishmentRepository establishments;
  final PostgresPointsRuleRepository pointsRules;
  final PostgresPurchaseRepository purchases;
  final PostgresMovementRepository movements;
  final IdentificationSigner ticketSigner;
  final TokenVerifier verifier;
  final EstablishmentRateLimiter rateLimiter;
  final MerchantDependencies merchant;
  final PostgresTransactionRunner tx;
  final PasswordHasher hasher;
  final TokenSigner signer;
  final OtpSender otpSender;
  final EmailSender emailSender;
  final TokenGenerator tokens;
  final IdGenerator ids;
  final Clock clock;

  @override
  final RegisterFn registerCustomer;
  @override
  final VerifyPhoneFn verifyPhoneOtp;
  @override
  final SendOtpFn resendPhoneOtp;
  @override
  final VerifyEmailFn verifyEmail;
  @override
  final LoginFn login;
  @override
  final RefreshFn refreshSession;
  @override
  final LogoutFn logout;
  @override
  final ForgotFn forgotPassword;
  @override
  final ResetFn resetPassword;

  @override
  IdentifyFn get identifyCustomer => merchant.identifyCustomer;

  @override
  PreviewFn get previewPurchase => merchant.previewPurchase;

  @override
  RegisterPurchaseFn get registerPurchase => merchant.registerPurchase;

  @override
  ListMovementsFn get listMovements => merchant.listMovements;
}
