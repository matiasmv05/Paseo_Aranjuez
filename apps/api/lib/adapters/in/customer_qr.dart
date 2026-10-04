/// Firma del puerto de entrada para emitir el ticket QR del cliente.
/// Lanza `IdentityException.unauthenticated` si el header falta o el
/// access token es inválido; `forbidden` si no hay `cid`.
typedef QrTicketIssuer = Future<String> Function({String? authorizationHeader});
