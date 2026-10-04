/// Códigos estables de `application/problem+json` (RFC 9457).
///
/// El cliente programa contra estos `code` (AGENTS.md §9). La lista se
/// corresponde con el schema `Problem` de `docs/openapi.yaml`; los marcados
/// como `reserved` provienen del documento 9-stack (§9.4 y afines) y aún no
/// aparecen en el contrato.
library;

// Cada constante del enum es su propio `wire`; el valor habla por sí solo y
// se mantiene sincronizado con openapi.yaml por prueba de snapshot.
// ignore_for_file: public_member_api_docs

/// Códigos de error estables del contrato.
enum ApiErrorCode {
  // --- De `docs/openapi.yaml` (schema `Problem` y ejemplos) ---
  validationFailed('VALIDATION_FAILED'),
  phoneNotSupported('PHONE_NOT_SUPPORTED'),
  otpInvalid('OTP_INVALID'),
  otpExpired('OTP_EXPIRED'),
  otpTooManyAttempts('OTP_TOO_MANY_ATTEMPTS'),
  credentialsInvalid('CREDENTIALS_INVALID'),
  unauthenticated('UNAUTHENTICATED'),
  forbidden('FORBIDDEN'),
  notFound('NOT_FOUND'),
  conflict('CONFLICT'),
  rateLimited('RATE_LIMITED'),
  tokenInvalid('TOKEN_INVALID'),
  tokenReuseDetected('TOKEN_REUSE_DETECTED'),
  phoneNotVerified('PHONE_NOT_VERIFIED'),
  methodNotAllowed('METHOD_NOT_ALLOWED'),
  serviceUnavailable('SERVICE_UNAVAILABLE'),
  // Dominio (ya listados en el schema `Problem` de openapi).
  noApplicableRule('NO_APPLICABLE_RULE'),
  insufficientPoints('INSUFFICIENT_POINTS'),
  insufficientPointsForReversal('INSUFFICIENT_POINTS_FOR_REVERSAL'),
  refundWindowExpired('REFUND_WINDOW_EXPIRED'),
  refundAlreadyResolved('REFUND_ALREADY_RESOLVED'),

  // --- Del panel del comercio (Persona 3); ver tag `comercio` en openapi ---
  /// No hay cliente con ese teléfono (o el comercio es otro).
  customerNotFound('CUSTOMER_NOT_FOUND'),

  /// El token de QR no tiene firma válida o venció (~60 s).
  invalidQrToken('INVALID_QR_TOKEN'),

  /// El ticket de identificación venció (~5 min), es de otro comercio o fue
  /// manipulado.
  invalidIdentificationTicket('INVALID_IDENTIFICATION_TICKET'),

  /// `invoice_ref` ya usado dentro del mismo comercio.
  duplicateInvoice('DUPLICATE_INVOICE'),

  // --- Reservados: del documento 9-stack, aún no en openapi.yaml ---
  /// Reservado (9-stack, límite de OTP por teléfono/IP).
  otpRateLimited('OTP_RATE_LIMITED', reserved: true),
  invalidAttachment('INVALID_ATTACHMENT', reserved: true),
  attachmentTooLarge('ATTACHMENT_TOO_LARGE', reserved: true),
  refundAlreadyRequested('REFUND_ALREADY_REQUESTED', reserved: true),
  purchaseAlreadyRefunded('PURCHASE_ALREADY_REFUNDED', reserved: true),
  redemptionAlreadyUsed('REDEMPTION_ALREADY_USED', reserved: true);

  new(this.wire, {this.reserved = false});

  /// Valor exacto del campo `code` en el contrato.
  final String wire;

  /// `true` si proviene del documento 9-stack y aún no figura en openapi.
  final bool reserved;

  /// Busca por el valor del contrato; `null` si no existe.
  static ApiErrorCode? fromWire(String? wire) => _byWire[wire];

  static final Map<String, ApiErrorCode> _byWire = {
    for (final c in ApiErrorCode.values) c.wire: c,
  };
}
