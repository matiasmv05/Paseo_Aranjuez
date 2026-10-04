import 'package:flutter/foundation.dart';

import 'domain/auth_repository.dart';

/// Estados del flujo de identidad (registro + verificación OTP).
sealed class IdentityState {
  const IdentityState();
}

final class IdentityInitial extends IdentityState {
  const IdentityInitial();
}

final class IdentityLoading extends IdentityState {
  const IdentityLoading();
}

final class OtpSentSuccess extends IdentityState {
  const OtpSentSuccess();
}

final class OtpVerified extends IdentityState {
  const OtpVerified();
}

final class IdentityFailure extends IdentityState {
  const IdentityFailure(this.message);

  final String message;
}

/// Controlador de estado del flujo de identidad.
class IdentityNotifier extends ValueNotifier<IdentityState> {
  IdentityNotifier(this._repository) : super(const IdentityInitial());

  final AuthRepository _repository;

  Future<void> sendOtp(String phone) async {
    value = const IdentityLoading();
    try {
      await _repository.sendOtp(phone);
      value = const OtpSentSuccess();
    } catch (e) {
      value = IdentityFailure(e.toString());
    }
  }

  Future<void> verifyOtp(String phone, String code) async {
    value = const IdentityLoading();
    try {
      final isValid = await _repository.verifyOtp(phone, code);
      value = isValid
          ? const OtpVerified()
          : const IdentityFailure('Código OTP inválido');
    } catch (e) {
      value = IdentityFailure(e.toString());
    }
  }
}
