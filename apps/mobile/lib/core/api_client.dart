import 'dart:convert';

import 'package:http/http.dart' as http;

/// Excepción tipada de la API Paseo (RFC 9457, AGENTS.md §9).
///
/// El cliente programa contra [code], el código estable del
/// `application/problem+json`; [title] y [detail] son solo para humanos.
/// [statusCode] vale 0 cuando no hubo respuesta HTTP (fallo de transporte).
final class ApiException implements Exception {
  /// Crea la excepción con el [statusCode] HTTP y el [code] del `Problem`.
  const new({
    required this.statusCode,
    required this.code,
    this.title,
    this.detail,
  });

  /// Fallo de transporte: no hubo respuesta HTTP utilizable.
  const new network(String message)
    : this(statusCode: 0, code: 'NETWORK_ERROR', detail: message);

  /// Respuesta HTTP sin cuerpo JSON interpretable (o `Problem` sin `code`).
  const new invalidResponse(int statusCode)
    : this(statusCode: statusCode, code: 'INVALID_RESPONSE');

  /// Código de estado HTTP (0 = fallo de red).
  final int statusCode;

  /// Código estable del contrato (`PHONE_NOT_VERIFIED`, `FORBIDDEN`,
  /// `UNAUTHENTICATED`, `VALIDATION_FAILED`, `NETWORK_ERROR`, …).
  final String code;

  /// Título legible para humanos.
  final String? title;

  /// Detalle legible para humanos.
  final String? detail;

  @override
  String toString() => 'ApiException($statusCode, $code)';
}

/// Cliente HTTP mínimo de la API Paseo del cliente móvil (AGENTS.md §9).
///
/// - Base URL por `--dart-define=PASEO_API_BASE`
///   (default `http://localhost:8080/api/v1`).
/// - Bearer token por `--dart-define=PASEO_TOKEN` (hasta que exista el login
///   móvil de la feature 001).
/// - Traduce `application/problem+json` a [ApiException]. Sin lógica de
///   negocio: el servidor es la fuente de verdad (regla 2.1).
final class ApiClient {
  /// Crea el cliente. En desarrollo los parámetros llegan por
  /// `--dart-define`; los inyectables existen para los tests.
  new({http.Client? httpClient, String? baseUrl, String? accessToken})
    : _httpClient = httpClient ?? http.Client(),
      _baseUrl = _normalizeBase(
        baseUrl ??
            const String.fromEnvironment(
              'PASEO_API_BASE',
              defaultValue: 'http://localhost:8080/api/v1',
            ),
      ),
      _accessToken = accessToken ?? const String.fromEnvironment('PASEO_TOKEN');

  final http.Client _httpClient;
  final String _baseUrl;
  final String _accessToken;

  /// GET de un recurso JSON. [path] es relativo a la base (empieza con `/`).
  ///
  /// Lanza [ApiException] ante error de la API o de transporte.
  Future<Map<String, Object?>> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: queryParameters);
    final http.Response response;
    try {
      response = await _httpClient.get(uri, headers: _headers);
    } on http.ClientException catch (e) {
      throw ApiException.network(e.message);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, Object?>) return decoded;
      } on FormatException {
        // Cuerpo no JSON: se reporta como respuesta inválida.
      }
      throw ApiException.invalidResponse(response.statusCode);
    }
    throw _problemFrom(response);
  }

  /// Libera el cliente HTTP subyacente.
  void close() => _httpClient.close();

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'X-Paseo-Client': 'paseo-mobile',
    if (_accessToken.isNotEmpty) 'Authorization': 'Bearer $_accessToken',
  };

  static String _normalizeBase(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  static ApiException _problemFrom(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, Object?>) {
        final code = decoded['code'];
        final title = decoded['title'];
        final detail = decoded['detail'];
        if (code is String) {
          return ApiException(
            statusCode: response.statusCode,
            code: code,
            title: title is String ? title : null,
            detail: detail is String ? detail : null,
          );
        }
      }
    } on FormatException {
      // Cuerpo no JSON: se cae al genérico por status.
    }
    return ApiException(
      statusCode: response.statusCode,
      code: 'HTTP_${response.statusCode}',
    );
  }
}
