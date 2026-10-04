import 'package:paseo_api/domain/loyalty/identification.dart';

/// Firma y verifica los tokens de identificacion (HU-10, FR-003/FR-006).
///
/// El ticket de identificacion y el token QR comparten primitiva
/// (HMAC-SHA256) pero no formato ni TTL. `verify*` devuelve `null` cuando la
/// firma es invalida, el token esta vencido o su `kind` no corresponde; el
/// caso de uso traduce ese `null` al `code` del contrato
/// (`INVALID_IDENTIFICATION_TICKET` / `INVALID_QR_TOKEN`, FR-022).
abstract interface class TicketSigner {
  /// Firma un ticket de identificacion ligado al comercio y sucursal.
  String signTicket(IdentificationTicketClaims claims);

  /// Verifica un ticket; `null` si no es valido o esta vencido respecto de
  /// [now].
  IdentificationTicketClaims? verifyTicket(
    String token, {
    required DateTime now,
  });

  /// Firma el token QR de un cliente (lo valida esta feature, no lo emite).
  String signQr(QrTokenClaims claims);

  /// Verifica un token QR; `null` si no es valido o esta vencido respecto de
  /// [now].
  QrTokenClaims? verifyQr(String token, {required DateTime now});
}
