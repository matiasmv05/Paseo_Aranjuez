/// DTOs de autenticación alineados con `docs/openapi.yaml`.
///
/// Contrato en `snake_case`; campos Dart en camelCase. Sin lógica de
/// dominio: solo serialización.
library;

// Los DTOs son contenedores planos; los nombres ya se documentan en
// openapi.yaml y replicarlos campo a campo no aporta.
// ignore_for_file: public_member_api_docs

/// `RegisterRequest`: correo + teléfono + contraseña (AGENTS.md §8).
final class RegisterRequest {
  const new({
    required this.email,
    required this.phone,
    required this.password,
    this.fullName,
  });

  factory fromJson(Map<String, Object?> json) => RegisterRequest(
    email: json['email']! as String,
    phone: json['phone']! as String,
    password: json['password']! as String,
    fullName: json['full_name'] as String?,
  );

  final String email;

  /// Teléfono boliviano en E.164 (`+591...`).
  final String phone;
  final String password;

  /// Nombre visible opcional; el comercio lo recibe enmascarado.
  final String? fullName;

  Map<String, Object?> toJson() => {
    'email': email,
    'phone': phone,
    'password': password,
    if (fullName != null) 'full_name': fullName,
  };
}

/// Respuesta 201 de `POST /auth/register`.
final class RegisterResponse {
  const new({
    required this.customerId,
    required this.phoneVerified,
    required this.emailVerificationSent,
  });

  factory fromJson(Map<String, Object?> json) => RegisterResponse(
    customerId: json['customer_id']! as String,
    phoneVerified: json['phone_verified']! as bool,
    emailVerificationSent: json['email_verification_sent']! as bool,
  );

  final String customerId;
  final bool phoneVerified;
  final bool emailVerificationSent;

  Map<String, Object?> toJson() => {
    'customer_id': customerId,
    'phone_verified': phoneVerified,
    'email_verification_sent': emailVerificationSent,
  };
}

/// `OtpVerifyRequest` de `POST /auth/phone/verify`.
final class OtpVerifyRequest {
  const new({required this.phone, required this.code});

  factory fromJson(Map<String, Object?> json) => OtpVerifyRequest(
    phone: json['phone']! as String,
    code: json['code']! as String,
  );

  final String phone;

  /// OTP de 6 dígitos.
  final String code;

  Map<String, Object?> toJson() => {'phone': phone, 'code': code};
}

/// Respuesta 200 de `POST /auth/phone/verify`.
final class OtpVerifyResponse {
  const new({required this.phoneVerified});

  factory fromJson(Map<String, Object?> json) =>
      OtpVerifyResponse(phoneVerified: json['phone_verified']! as bool);

  final bool phoneVerified;

  Map<String, Object?> toJson() => {'phone_verified': phoneVerified};
}

/// Cuerpo de `POST /auth/phone/send-otp`.
final class SendOtpRequest {
  const new({required this.phone});

  factory fromJson(Map<String, Object?> json) =>
      SendOtpRequest(phone: json['phone']! as String);

  final String phone;

  Map<String, Object?> toJson() => {'phone': phone};
}

/// `LoginRequest` de `POST /auth/login`.
final class LoginRequest {
  const new({required this.email, required this.password});

  factory fromJson(Map<String, Object?> json) => LoginRequest(
    email: json['email']! as String,
    password: json['password']! as String,
  );

  final String email;
  final String password;

  Map<String, Object?> toJson() => {'email': email, 'password': password};
}

/// Cuerpo opcional de `POST /auth/refresh` (solo `paseo-mobile`; las webs
/// usan su cookie).
final class RefreshRequest {
  const new({required this.refreshToken});

  factory fromJson(Map<String, Object?> json) =>
      RefreshRequest(refreshToken: json['refresh_token']! as String);

  final String refreshToken;

  Map<String, Object?> toJson() => {'refresh_token': refreshToken};
}

/// `TokenResponse` de `POST /auth/login` y `POST /auth/refresh`.
final class TokenResponse {
  const new({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    this.refreshToken,
  });

  factory fromJson(Map<String, Object?> json) => TokenResponse(
    accessToken: json['access_token']! as String,
    tokenType: json['token_type']! as String,
    expiresIn: json['expires_in']! as int,
    refreshToken: json['refresh_token'] as String?,
  );

  final String accessToken;

  /// Siempre `Bearer` (enum del contrato).
  final String tokenType;

  /// Segundos de vida del access token (≤ 900).
  final int expiresIn;

  /// Solo para `paseo-mobile`; las webs reciben su cookie `HttpOnly`.
  final String? refreshToken;

  Map<String, Object?> toJson() => {
    'access_token': accessToken,
    'token_type': tokenType,
    'expires_in': expiresIn,
    if (refreshToken != null) 'refresh_token': refreshToken,
  };
}

/// Cuerpo de `POST /auth/verify-email`.
final class VerifyEmailRequest {
  const new({required this.token});

  factory fromJson(Map<String, Object?> json) =>
      VerifyEmailRequest(token: json['token']! as String);

  final String token;

  Map<String, Object?> toJson() => {'token': token};
}

/// Cuerpo de `POST /auth/password/forgot` (siempre responde 202).
final class ForgotPasswordRequest {
  const new({required this.email});

  factory fromJson(Map<String, Object?> json) =>
      ForgotPasswordRequest(email: json['email']! as String);

  final String email;

  Map<String, Object?> toJson() => {'email': email};
}

/// Cuerpo de `POST /auth/password/reset`.
final class ResetPasswordRequest {
  const new({required this.token, required this.newPassword});

  factory fromJson(Map<String, Object?> json) => ResetPasswordRequest(
    token: json['token']! as String,
    newPassword: json['new_password']! as String,
  );

  final String token;
  final String newPassword;

  Map<String, Object?> toJson() => {
    'token': token,
    'new_password': newPassword,
  };
}
