import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/client_app.dart';

typedef RegisterFn =
    Future<String> Function({
      required String email,
      required String phone,
      required String password,
      String? fullName,
    });
typedef VerifyPhoneFn =
    Future<void> Function({required String phone, required String code});
typedef SendOtpFn = Future<void> Function({required String phone});
typedef VerifyEmailFn = Future<void> Function({required String token});
typedef LoginFn =
    Future<IssuedSession> Function({
      required String email,
      required String password,
      required ClientApp client,
    });
typedef RefreshFn =
    Future<IssuedSession> Function({required String refreshToken});
typedef LogoutFn = Future<void> Function({required String refreshToken});
typedef ForgotFn = Future<void> Function({required String email});
typedef ResetFn =
    Future<void> Function({required String token, required String newPassword});

/// Casos de uso de identidad disponibles para las rutas (AGENTS.md §3).
/// Las rutas son finas: leen este provider, validan DTO, llaman UN caso de
/// uso y mapean el resultado a RFC 9457. Implementado por `AppDependencies`.
abstract interface class AuthUseCases {
  RegisterFn get registerCustomer;
  VerifyPhoneFn get verifyPhoneOtp;
  SendOtpFn get resendPhoneOtp;
  VerifyEmailFn get verifyEmail;
  LoginFn get login;
  RefreshFn get refreshSession;
  LogoutFn get logout;
  ForgotFn get forgotPassword;
  ResetFn get resetPassword;
}
