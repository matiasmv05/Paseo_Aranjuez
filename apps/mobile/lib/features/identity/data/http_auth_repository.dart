import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/auth_repository.dart';

/// Error devuelto por la API de identidad (RFC 9457: se expone sólo el `code`).
final class AuthApiException implements Exception {
  const AuthApiException(this.statusCode, this.message, {this.code});

  final int statusCode;
  final String message;
  final String? code;

  @override
  String toString() => 'AuthApiException($statusCode, $code, $message)';
}

/// Implementación HTTP de [AuthRepository] contra la API `/api/v1`.
final class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({http.Client? client, required this.baseUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl/api/v1$path');

  static const _jsonHeaders = {'content-type': 'application/json'};

  @override
  Future<void> sendOtp(String phone) async {
    final response = await _client.post(
      _uri('/auth/phone/send-otp'),
      headers: _jsonHeaders,
      body: jsonEncode({'phone': phone}),
    );
    if (response.statusCode == 200 || response.statusCode == 202) {
      return;
    }
    throw _toException(response);
  }

  @override
  Future<bool> verifyOtp(String phone, String code) async {
    final response = await _client.post(
      _uri('/auth/phone/verify'),
      headers: _jsonHeaders,
      body: jsonEncode({'phone': phone, 'code': code}),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['phone_verified'] == true;
    }
    if (response.statusCode == 422) {
      return false; // OTP inválido, vencido o sin intentos (code OTP_INVALID).
    }
    throw _toException(response);
  }

  AuthApiException _toException(http.Response response) {
    String? code;
    var message = 'Error del servidor (${response.statusCode})';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      code = body['code'] as String?;
      final title = body['title'] as String?;
      if (title != null) {
        message = title;
      }
    } catch (_) {
      // El cuerpo no es JSON: se conserva el mensaje genérico.
    }
    return AuthApiException(response.statusCode, message, code: code);
  }
}
