import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paseo_mobile/features/merchant/data/merchant_api_client.dart';

/// Identidad de comercio derivada de los claims del access token.
///
/// Se usa solo para mostrar el contexto en la UI (rol, comercio, sucursal).
/// La autorizacion real la aplica el servidor (AGENTS.md §2 regla 1).
final class MerchantIdentity {
  /// Crea la identidad con los claims minimos del panel.
  const MerchantIdentity({
    required this.userId,
    required this.role,
    this.establishmentId,
    this.branchId,
  });

  /// Claim `sub`: id del usuario (`seller_user_id` del contrato).
  final String userId;

  /// Claim `role`: `merchant_owner` o `merchant_cashier`.
  final String role;

  /// Claim `est`: id del comercio.
  final String? establishmentId;

  /// Claim `br`: id de la sucursal (solo cajeros).
  final String? branchId;

  /// `true` si el rol es de cajero.
  bool get isCashier => role == 'merchant_cashier';

  /// `true` si el rol es de dueno.
  bool get isOwner => role == 'merchant_owner';
}

/// Decodifica la parte publica del JWT (sin verificar la firma).
///
/// La firma la valida el servidor en cada peticion; aqui solo se lee el
/// payload para armar la sesion en memoria. Devuelve `null` si el token
/// no tiene la forma esperada.
MerchantIdentity? decodeMerchantIdentity(String accessToken) {
  final parts = accessToken.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final json = (jsonDecode(payload) as Map<Object?, Object?>)
        .cast<String, Object?>();
    final sub = json['sub'];
    final role = json['role'];
    if (sub is! String || role is! String) return null;
    return MerchantIdentity(
      userId: sub,
      role: role,
      establishmentId: json['est'] as String?,
      branchId: json['br'] as String?,
    );
  } on Object {
    return null;
  }
}

/// Estado de la sesion del panel del comercio (T102).
final class MerchantSessionState {
  /// Crea un estado de sesion.
  const MerchantSessionState({
    this.accessToken,
    this.identity,
    this.loading = false,
    this.errorMessage,
  });

  /// Estado inicial: sin sesion.
  const MerchantSessionState.signedOut()
    : accessToken = null,
      identity = null,
      loading = false,
      errorMessage = null;

  /// Access token en memoria; `null` si no hay sesion.
  final String? accessToken;

  /// Contexto del comercio (`est`/`br`/`role`/`seller_user_id`).
  final MerchantIdentity? identity;

  /// `true` mientras un login esta en curso.
  final bool loading;

  /// Ultimo error de login, ya traducido a texto visible.
  final String? errorMessage;

  /// `true` cuando hay token e identidad cargados.
  bool get isAuthenticated => accessToken != null && identity != null;
}

/// Cliente del API inyectable (se sobreescribe en pruebas).
///
/// En produccion usa el mismo origen de la app (`/api/v1/`).
final merchantApiProvider = Provider<MerchantApiClient>(
  (ref) => MerchantApiClient(baseUrl: MerchantApiClient.defaultBaseUrl),
);

/// Sesion del comercio: login/logout y contexto derivado del token.
final merchantSessionProvider =
    NotifierProvider<MerchantSession, MerchantSessionState>(
      MerchantSession.new,
    );

/// Gestiona el ciclo de sesion del panel del comercio.
final class MerchantSession extends Notifier<MerchantSessionState> {
  @override
  MerchantSessionState build() => const MerchantSessionState.signedOut();

  /// Autentica contra `/auth/login` y guarda el contexto del comercio.
  ///
  /// Devuelve `true` si la sesion quedo lista; en caso contrario expone el
  /// mensaje en `errorMessage`.
  Future<bool> login({required String email, required String password}) async {
    state = const MerchantSessionState(loading: true);
    final api = ref.read(merchantApiProvider);
    try {
      final tokens = await api.login(email: email, password: password);
      final identity = decodeMerchantIdentity(tokens.accessToken);
      if (identity == null) {
        api.accessToken = null;
        state = const MerchantSessionState(
          errorMessage: 'La sesion no es valida para el panel del comercio.',
        );
        return false;
      }
      state = MerchantSessionState(
        accessToken: tokens.accessToken,
        identity: identity,
      );
      return true;
    } on MerchantApiException catch (error) {
      state = MerchantSessionState(errorMessage: describeMerchantError(error));
      return false;
    } on Object {
      state = const MerchantSessionState(
        errorMessage: 'No se pudo conectar con el servidor.',
      );
      return false;
    }
  }

  /// Cierra la sesion y limpia el token en memoria.
  void logout() {
    ref.read(merchantApiProvider).accessToken = null;
    state = const MerchantSessionState.signedOut();
  }
}
