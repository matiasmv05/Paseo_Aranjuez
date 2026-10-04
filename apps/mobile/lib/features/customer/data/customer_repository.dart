/// Puerto del perfil del cliente: obtiene el ticket QR firmado
/// desde `GET /api/v1/customers/me/qr`.
abstract class CustomerRepository {
  /// Devuelve el ticket QR firmado; lanza [CustomerApiException] en error.
  Future<String> fetchQrTicket(String accessToken);
}

/// Error devuelto por la API de cliente (solo `code`, nunca PII).
final class CustomerApiException implements Exception {
  const CustomerApiException(this.statusCode, this.message, {this.code});

  final int statusCode;
  final String message;
  final String? code;

  @override
  String toString() => 'CustomerApiException($statusCode, $code, $message)';
}
