import 'package:paseo_mobile/core/api_client.dart';

/// Traduce un [ApiException] a un mensaje comprensible para el cliente.
///
/// El match es por `code` estable del contrato (RFC 9457, AGENTS.md §9);
/// cualquier cosa desconocida cae al mensaje genérico.
String describeError(Object error) {
  if (error is! ApiException) return 'Algo salió mal. Inténtalo de nuevo.';
  return switch (error.code) {
    'PHONE_NOT_VERIFIED' =>
      'Verifica tu número de teléfono para acumular y ver puntos.',
    'UNAUTHENTICATED' => 'Tu sesión expiró. Vuelve a iniciar sesión.',
    'FORBIDDEN' => 'No tienes permiso para ver esta información.',
    'VALIDATION_FAILED' => 'La solicitud no es válida.',
    'RATE_LIMITED' => 'Demasiados intentos. Espera un momento.',
    'NETWORK_ERROR' => 'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
    _ => 'Algo salió mal. Inténtalo de nuevo.',
  };
}
