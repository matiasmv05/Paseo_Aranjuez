import 'package:flutter/foundation.dart';

import 'data/token_storage.dart';
import 'domain/auth_repository.dart';

/// Estados del flujo de identidad (registro + verificación OTP + sesión).
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

final class IdentityAuthenticated extends IdentityState {
  const IdentityAuthenticated();
}

final class IdentityUnauthenticated extends IdentityState {
  const IdentityUnauthenticated();
}

/// Controlador de estado del flujo de identidad.
class IdentityNotifier extends ValueNotifier<IdentityState> {
  IdentityNotifier(this._repository, {TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? InMemoryTokenStorage(),
      super(const IdentityInitial());

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;

  /// Token de sesión almacenado (para llamadas autenticadas al API).
  Future<String?> currentAccessToken() => _tokenStorage.getToken();

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
      final token = await _repository.verifyOtp(phone, code);
      if (token == null) {
        value = const IdentityFailure('Código OTP inválido');
        return;
      }
      await _tokenStorage.saveToken(token);
      value = const OtpVerified();
    } catch (e) {
      value = IdentityFailure(e.toString());
    }
  }

  Future<void> checkAuthStatus() async {
    final token = await _tokenStorage.getToken();
    value = token != null && token.isNotEmpty
        ? const IdentityAuthenticated()
        : const IdentityUnauthenticated();
  }

  Future<void> signOut() async {
    await _tokenStorage.deleteToken();
    value = const IdentityUnauthenticated();
  }
}
