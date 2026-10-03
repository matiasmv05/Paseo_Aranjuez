import 'package:paseo_shared/paseo_shared.dart';
import 'package:test/test.dart';

/// Snapshot determinista del contrato: conjunto de `code` esperados,
/// alineado a mano con el schema `Problem` de `docs/openapi.yaml` y con los
/// reservados del documento 9-stack (ver `task-9-brief.md`).
const expectedCodes = {
  // openapi.yaml — schema Problem y ejemplos
  'VALIDATION_FAILED',
  'PHONE_NOT_SUPPORTED',
  'OTP_INVALID',
  'OTP_EXPIRED',
  'OTP_TOO_MANY_ATTEMPTS',
  'CREDENTIALS_INVALID',
  'UNAUTHENTICATED',
  'FORBIDDEN',
  'NOT_FOUND',
  'CONFLICT',
  'RATE_LIMITED',
  'TOKEN_INVALID',
  'TOKEN_REUSE_DETECTED',
  'PHONE_NOT_VERIFIED',
  'METHOD_NOT_ALLOWED',
  'SERVICE_UNAVAILABLE',
  'NO_APPLICABLE_RULE',
  'INSUFFICIENT_POINTS',
  'INSUFFICIENT_POINTS_FOR_REVERSAL',
  'REFUND_WINDOW_EXPIRED',
  'REFUND_ALREADY_RESOLVED',
  // Reservados (9-stack; aún no en openapi.yaml)
  'OTP_RATE_LIMITED',
  'DUPLICATE_INVOICE',
  'CUSTOMER_NOT_FOUND',
  'INVALID_ATTACHMENT',
  'ATTACHMENT_TOO_LARGE',
  'REFUND_ALREADY_REQUESTED',
  'PURCHASE_ALREADY_REFUNDED',
  'REDEMPTION_ALREADY_USED',
};

void main() {
  test('el conjunto de códigos coincide con el snapshot del contrato', () {
    final actual = ApiErrorCode.values.map((c) => c.wire).toSet();
    expect(actual, expectedCodes);
  });

  test('wire es único y fromWire hace round-trip', () {
    for (final code in ApiErrorCode.values) {
      expect(ApiErrorCode.fromWire(code.wire), code);
    }
    expect(ApiErrorCode.fromWire('NO_EXISTE'), isNull);
  });

  test('los reservados están marcados y los del contrato no', () {
    const reserved = {
      'OTP_RATE_LIMITED',
      'DUPLICATE_INVOICE',
      'CUSTOMER_NOT_FOUND',
      'INVALID_ATTACHMENT',
      'ATTACHMENT_TOO_LARGE',
      'REFUND_ALREADY_REQUESTED',
      'PURCHASE_ALREADY_REFUNDED',
      'REDEMPTION_ALREADY_USED',
    };
    for (final code in ApiErrorCode.values) {
      expect(code.reserved, reserved.contains(code.wire), reason: code.wire);
    }
  });
}
