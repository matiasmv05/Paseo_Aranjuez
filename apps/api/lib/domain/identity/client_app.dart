/// Aplicacion cliente de la sesion (`X-Paseo-Client`). Define `aud` del JWT
/// y, para las webs, el nombre propio de la cookie de refresh
/// (SEC-003: nunca compartida entre webs).
enum ClientApp {
  mobile(audience: 'paseo-mobile', refreshCookieName: null),
  webMerchant(
    audience: 'paseo-web-merchant',
    refreshCookieName: '__Secure-rt_merchant',
  ),
  webAdmin(audience: 'paseo-web-admin', refreshCookieName: '__Secure-rt_admin');

  new({required this.audience, required this.refreshCookieName});

  /// Claim `aud` del access token; tambien el `audience` del refresh.
  final String audience;

  /// Nombre de la cookie `HttpOnly; Secure; SameSite=Strict` del refresh
  /// para webs; `null` en `paseo-mobile` (refresh va en el cuerpo).
  final String? refreshCookieName;

  bool get isWeb => refreshCookieName != null;

  static ClientApp? fromHeader(String? value) => switch (value) {
    'paseo-mobile' => ClientApp.mobile,
    'paseo-web-merchant' => ClientApp.webMerchant,
    'paseo-web-admin' => ClientApp.webAdmin,
    _ => null,
  };
}
