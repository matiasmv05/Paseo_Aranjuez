import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:paseo_shared/paseo_shared.dart' as contract;

/// Error de la API con el `code` estable del contrato (RFC 9457).
///
/// El cliente programa contra [code] (AGENTS.md §9): el texto de [detail]
/// es informativo y puede cambiar sin aviso.
final class MerchantApiException implements Exception {
  /// Crea la excepcion a partir de una respuesta `application/problem+json`.
  const MerchantApiException({
    required this.statusCode,
    required this.code,
    this.detail,
    this.correlationId,
  });

  /// Codigo HTTP de la respuesta.
  final int statusCode;

  /// Codigo estable del contrato; `null` si el cuerpo no era un `Problem`.
  final contract.ApiErrorCode? code;

  /// Detalle legible devuelto por el servidor (puede ser `null`).
  final String? detail;

  /// Identificador de correlacion para soporte (sin PII).
  final String? correlationId;

  @override
  String toString() =>
      'MerchantApiException($statusCode, ${code?.wire}): $detail';
}

/// Traduce el `code` de un [MerchantApiException] a un mensaje visible.
///
/// Centraliza el mapeo `problem+json` -> texto de UI (T108); la UI nunca
/// interpreta el `code` por su cuenta.
String describeMerchantError(MerchantApiException error) {
  return switch (error.code) {
    contract.ApiErrorCode.phoneNotSupported =>
      'Solo se aceptan telefonos bolivianos (+591).',
    contract.ApiErrorCode.customerNotFound =>
      'No hay un cliente registrado con ese dato.',
    contract.ApiErrorCode.phoneNotVerified =>
      'El cliente todavia no verifico su telefono.',
    contract.ApiErrorCode.invalidQrToken =>
      'El codigo QR vencio o no es valido.',
    contract.ApiErrorCode.invalidIdentificationTicket =>
      'La identificacion vencio. Vuelve a identificar al cliente.',
    contract.ApiErrorCode.duplicateInvoice =>
      'Ese numero de factura ya fue registrado en el comercio.',
    contract.ApiErrorCode.noApplicableRule =>
      'No hay una regla de puntos aplicable a esta compra.',
    contract.ApiErrorCode.rateLimited =>
      'Demasiadas solicitudes. Espera un momento e intenta de nuevo.',
    contract.ApiErrorCode.unauthenticated =>
      'La sesion vencio. Vuelve a iniciar sesion.',
    contract.ApiErrorCode.forbidden =>
      'No tienes permiso para realizar esta accion.',
    contract.ApiErrorCode.validationFailed =>
      'Revisa los datos ingresados e intenta de nuevo.',
    contract.ApiErrorCode.credentialsInvalid =>
      'Correo o contrasena incorrectos.',
    _ => 'No se pudo completar la operacion.',
  };
}

/// Cliente REST del panel del comercio (T101).
///
/// Habla el contrato de `docs/openapi.yaml` a traves de `paseo_shared`:
/// envia `X-Paseo-Client: paseo-web-merchant`, `Authorization: Bearer` y,
/// en el registro de compra, `Idempotency-Key`. El access token vive solo
/// en memoria (AGENTS.md §6).
final class MerchantApiClient {
  /// Crea el cliente con una URL base absoluta y un `http.Client` opcional.
  ///
  /// [baseUrl] debe terminar en `/api/v1/` (con barra final) para que
  /// `resolve` deje las rutas en `/api/v1/<recurso>`.
  MerchantApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.clientApp = 'paseo-web-merchant',
  }) : _http = httpClient ?? http.Client();

  /// URL base del API, p. ej. `https://paseo.local/api/v1/`.
  final Uri baseUrl;

  /// Cabecera `X-Paseo-Client` (audiencia de la sesion web comercio).
  final String clientApp;

  final http.Client _http;

  /// Access token en memoria; `null` cuando no hay sesion.
  String? accessToken;

  /// `true` si hay un access token cargado.
  bool get hasSession => accessToken != null;

  /// URL base por defecto: override por `--dart-define=API_BASE_URL=...` o,
  /// en la web, el mismo origen que sirve la app (`/api/v1/`, Caddy).
  static Uri get defaultBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return Uri.parse(override);
    return Uri.base.resolve('/api/v1/');
  }

  /// Genera una `Idempotency-Key` unica por intento de registro.
  ///
  /// No usa UUID: en la web basta con tiempo de alta resolucion + azar
  /// para no repetir la clave entre reintentos del mismo formulario.
  static String newIdempotencyKey() {
    final millis = DateTime.now().microsecondsSinceEpoch;
    final salt = Random().nextInt(1 << 32).toRadixString(16);
    return 'web-merchant-$millis-$salt';
  }

  /// `POST /auth/login` (X-Paseo-Client: web comercio).
  Future<contract.TokenResponse> login({
    required String email,
    required String password,
  }) async {
    final body = contract.LoginRequest(email: email, password: password);
    final response = await _http.post(
      baseUrl.resolve('auth/login'),
      headers: _headers(json: true),
      body: jsonEncode(body.toJson()),
    );
    final json = _decode(response, expected: 200);
    final tokens = contract.TokenResponse.fromJson(json);
    accessToken = tokens.accessToken;
    return tokens;
  }

  /// `POST /merchant/customers/identify` (HU-10).
  Future<contract.IdentifyResult> identify(
    contract.IdentifyRequest request,
  ) async {
    final response = await _post(
      'merchant/customers/identify',
      request.toJson(),
    );
    final json = _decode(response, expected: 200);
    return contract.IdentifyResult.fromJson(json);
  }

  /// `POST /merchant/purchases/preview` (US3). No escribe nada.
  Future<contract.PreviewPurchaseResult> preview(
    contract.PreviewPurchaseRequest request,
  ) async {
    final response = await _post(
      'merchant/purchases/preview',
      request.toJson(),
    );
    final json = _decode(response, expected: 200);
    return contract.PreviewPurchaseResult.fromJson(json);
  }

  /// `POST /merchant/purchases` (HU-11). Devuelve `200` o `201` segun el
  /// reintento; ambos cuerpos son un `Purchase`.
  Future<contract.Purchase> registerPurchase(
    contract.RegisterPurchaseRequest request, {
    required String idempotencyKey,
  }) async {
    final response = await _http.post(
      baseUrl.resolve('merchant/purchases'),
      headers: _headers(json: true, idempotencyKey: idempotencyKey),
      body: jsonEncode(request.toJson()),
    );
    final json = _decode(response, expected: {200, 201});
    return contract.Purchase.fromJson(json);
  }

  /// `GET /merchant/movements` (HU-13), paginado por cursor.
  Future<contract.MovementPage> movements({int? limit, String? cursor}) async {
    final query = <String, String>{
      'limit': ?limit?.toString(),
      'cursor': ?cursor,
    };
    final uri = baseUrl
        .resolve('merchant/movements')
        .replace(queryParameters: query.isEmpty ? null : query);
    final response = await _http.get(uri, headers: _headers());
    final json = _decode(response, expected: 200);
    return contract.MovementPage.fromJson(json);
  }

  Future<http.Response> _post(String path, Map<String, Object?> body) {
    return _http.post(
      baseUrl.resolve(path),
      headers: _headers(json: true),
      body: jsonEncode(body),
    );
  }

  Map<String, String> _headers({bool json = false, String? idempotencyKey}) {
    return {
      if (json) 'content-type': 'application/json; charset=utf-8',
      'X-Paseo-Client': clientApp,
      if (accessToken != null) 'authorization': 'Bearer $accessToken',
      'idempotency-key': ?idempotencyKey,
    };
  }

  Map<String, Object?> _decode(
    http.Response response, {
    required Object expected,
  }) {
    final ok = expected is Set<int>
        ? expected.contains(response.statusCode)
        : response.statusCode == expected;
    if (!ok) throw _problem(response);
    if (response.bodyBytes.isEmpty) return const {};
    return _asObject(jsonDecode(utf8.decode(response.bodyBytes)));
  }

  MerchantApiException _problem(http.Response response) {
    Map<String, Object?>? body;
    try {
      body = _asObject(jsonDecode(utf8.decode(response.bodyBytes)));
    } on Object {
      body = null;
    }
    return MerchantApiException(
      statusCode: response.statusCode,
      code: contract.ApiErrorCode.fromWire(body?['code'] as String?),
      detail: body?['detail'] as String?,
      correlationId: body?['correlation_id'] as String?,
    );
  }

  static Map<String, Object?> _asObject(Object? value) =>
      (value! as Map<Object?, Object?>).cast<String, Object?>();
}
