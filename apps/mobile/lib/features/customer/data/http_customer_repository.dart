import 'dart:convert';

import 'package:http/http.dart' as http;

import 'customer_repository.dart';

/// Implementación HTTP del perfil del cliente contra la API `/api/v1`.
final class HttpCustomerRepository implements CustomerRepository {
  HttpCustomerRepository({http.Client? client, required this.baseUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  @override
  Future<String> fetchQrTicket(String accessToken) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/customers/me/qr'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['qr_ticket'] as String;
    }
    throw _toException(response);
  }

  CustomerApiException _toException(http.Response response) {
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
      // El cuerpo no es JSON: mensaje genérico.
    }
    return CustomerApiException(response.statusCode, message, code: code);
  }
}
