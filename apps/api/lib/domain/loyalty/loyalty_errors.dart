/// Errores de dominio de fidelizacion, mapeables a `ApiErrorCode`.
library;

import 'package:paseo_shared/paseo_shared.dart' show ApiErrorCode;

/// Falla de negocio en una operacion de fidelizacion.
///
/// Reutiliza el mismo transporte que `IdentityException`: la capa de rutas
/// traduce [code] a un `Problem` con el HTTP status correspondiente.
final class LoyaltyException implements Exception {
  /// Crea una falla con un [code] del contrato.
  const LoyaltyException(this.code, this.message);

  /// No hay ninguna regla de conversion aplicable a la compra.
  factory LoyaltyException.noApplicableRule() => const LoyaltyException(
    ApiErrorCode.noApplicableRule,
    'no hay una regla de conversion aplicable a la compra',
  );

  /// El ticket de identificacion no es valido o expiro.
  factory LoyaltyException.invalidIdentificationTicket() =>
      const LoyaltyException(
        ApiErrorCode.invalidIdentificationTicket,
        'el ticket de identificacion no es valido o expiro',
      );

  /// El token QR no es valido o expiro.
  factory LoyaltyException.invalidQrToken() => const LoyaltyException(
    ApiErrorCode.invalidQrToken,
    'el token QR no es valido o expiro',
  );

  /// Ya existe una compra con el mismo `invoice_ref` en el comercio.
  factory LoyaltyException.duplicateInvoice() => const LoyaltyException(
    ApiErrorCode.duplicateInvoice,
    'ya existe una compra con esa factura en el comercio',
  );

  /// El cliente identificado no existe.
  factory LoyaltyException.customerNotFound() => const LoyaltyException(
    ApiErrorCode.customerNotFound,
    'no existe un cliente con esa identificacion',
  );

  /// El telefono del cliente no esta verificado.
  factory LoyaltyException.phoneNotVerified() => const LoyaltyException(
    ApiErrorCode.phoneNotVerified,
    'el telefono del cliente no esta verificado',
  );

  /// El telefono no tiene el formato soportado.
  factory LoyaltyException.phoneNotSupported() => const LoyaltyException(
    ApiErrorCode.phoneNotSupported,
    'numero de telefono no soportado',
  );

  /// Se excedio el limite de peticiones.
  factory LoyaltyException.rateLimited() => const LoyaltyException(
    ApiErrorCode.rateLimited,
    'demasiadas peticiones; intenta mas tarde',
  );

  /// Datos invalidos en la solicitud.
  factory LoyaltyException.validation(String message) =>
      LoyaltyException(ApiErrorCode.validationFailed, message);

  /// Codigo de error del contrato.
  final ApiErrorCode code;

  /// Mensaje en espanol apto para el usuario.
  final String message;

  @override
  String toString() => 'LoyaltyException(${code.wire}): $message';
}
