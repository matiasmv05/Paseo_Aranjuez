import 'package:paseo_shared/paseo_shared.dart';
import 'package:test/test.dart';

void main() {
  group('DTOs de auth: round-trip JSON', () {
    test('RegisterRequest', () {
      const r = RegisterRequest(
        email: 'cliente@ejemplo.bo',
        phone: '+59171234567',
        password: 'secreto123',
        fullName: 'Ana Pérez',
      );
      final json = r.toJson();
      expect(json['full_name'], 'Ana Pérez');
      final back = RegisterRequest.fromJson(json);
      expect(back.email, r.email);
      expect(back.phone, r.phone);
      expect(back.password, r.password);
      expect(back.fullName, r.fullName);
    });

    test('RegisterRequest sin full_name omite el campo', () {
      const r = RegisterRequest(
        email: 'a@b.co',
        phone: '+59161234567',
        password: 'secreto123',
      );
      expect(r.toJson().containsKey('full_name'), isFalse);
    });

    test('RegisterResponse', () {
      const r = RegisterResponse(
        customerId: '0d1b2f3c-4a5e-4f6a-8b9c-1d2e3f4a5b6c',
        phoneVerified: false,
        emailVerificationSent: true,
      );
      final back = RegisterResponse.fromJson(r.toJson());
      expect(back.toJson(), r.toJson());
      expect(
        back.toJson().keys,
        containsAll([
          'customer_id',
          'phone_verified',
          'email_verification_sent',
        ]),
      );
    });

    test('OtpVerifyRequest / OtpVerifyResponse', () {
      final req = OtpVerifyRequest.fromJson(
        const OtpVerifyRequest(phone: '+59171234567', code: '123456').toJson(),
      );
      expect(req.code, '123456');
      final res = OtpVerifyResponse.fromJson(
        const OtpVerifyResponse(phoneVerified: true).toJson(),
      );
      expect(res.phoneVerified, isTrue);
    });

    test('SendOtpRequest', () {
      final r = SendOtpRequest.fromJson(
        const SendOtpRequest(phone: '+59171234567').toJson(),
      );
      expect(r.phone, '+59171234567');
    });

    test('LoginRequest', () {
      final r = LoginRequest.fromJson(
        const LoginRequest(email: 'a@b.co', password: 'x12345678').toJson(),
      );
      expect(r.email, 'a@b.co');
      expect(r.password, 'x12345678');
    });

    test('RefreshRequest usa refresh_token', () {
      final r = RefreshRequest.fromJson(
        const RefreshRequest(refreshToken: 'rt').toJson(),
      );
      expect(r.refreshToken, 'rt');
      expect(r.toJson(), {'refresh_token': 'rt'});
    });

    test('TokenResponse con y sin refresh_token', () {
      const full = TokenResponse(
        accessToken: 'at',
        tokenType: 'Bearer',
        expiresIn: 900,
        refreshToken: 'rt',
      );
      final back = TokenResponse.fromJson(full.toJson());
      expect(back.accessToken, 'at');
      expect(back.tokenType, 'Bearer');
      expect(back.expiresIn, 900);
      expect(back.refreshToken, 'rt');

      const web = TokenResponse(
        accessToken: 'at',
        tokenType: 'Bearer',
        expiresIn: 900,
      );
      expect(web.toJson().containsKey('refresh_token'), isFalse);
      expect(TokenResponse.fromJson(web.toJson()).refreshToken, isNull);
    });

    test('VerifyEmailRequest', () {
      final r = VerifyEmailRequest.fromJson(
        const VerifyEmailRequest(token: 'tok').toJson(),
      );
      expect(r.token, 'tok');
    });

    test('ForgotPasswordRequest', () {
      final r = ForgotPasswordRequest.fromJson(
        const ForgotPasswordRequest(email: 'a@b.co').toJson(),
      );
      expect(r.email, 'a@b.co');
    });

    test('ResetPasswordRequest usa new_password', () {
      final r = ResetPasswordRequest.fromJson(
        const ResetPasswordRequest(
          token: 'tok',
          newPassword: 'n12345678',
        ).toJson(),
      );
      expect(r.newPassword, 'n12345678');
      expect(r.toJson(), {'token': 'tok', 'new_password': 'n12345678'});
    });
  });
}
