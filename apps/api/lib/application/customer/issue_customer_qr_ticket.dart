import 'package:paseo_api/application/identity/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';

/// Emite el ticket QR firmado del cliente autenticado (≤ 5 min, AGENTS.md §8).
///
/// - `400/401` no: header ausente o token inválido → `UNAUTHENTICATED`.
/// - rol distinto de `customer` o `cid` ausente → `FORBIDDEN`.
/// - El ticket no contiene datos personales: `sub == cid`, `aud == paseo-qr`.
final class IssueCustomerQrTicket {
  const IssueCustomerQrTicket({
    required TokenVerifier verifier,
    required TokenSigner signer,
    required Clock clock,
    required IdGenerator ids,
  }) : _verifier = verifier,
       _signer = signer,
       _clock = clock,
       _ids = ids;

  /// Vida del ticket QR en segundos (≤ 5 min según el contrato).
  static const lifetimeSeconds = 300;

  static const _bearerPrefix = 'Bearer ';

  final TokenVerifier _verifier;
  final TokenSigner _signer;
  final Clock _clock;
  final IdGenerator _ids;

  Future<String> call({required String? authorizationHeader}) async {
    final header = authorizationHeader;
    if (header == null || !header.startsWith(_bearerPrefix)) {
      throw IdentityException.unauthenticated();
    }
    final claims = _verifier.verify(header.substring(_bearerPrefix.length));
    final customerId = claims.customerId;
    if (claims.role != UserRole.customer ||
        customerId == null ||
        customerId.isEmpty) {
      throw IdentityException.forbidden();
    }
    final now = _clock.nowUtc();
    return _signer.sign(
      AuthClaims(
        issuer: claims.issuer,
        audience: 'paseo-qr',
        subject: customerId,
        issuedAt: now,
        expiresAt: now.add(const Duration(seconds: lifetimeSeconds)),
        jwtId: _ids.newId(),
        role: UserRole.customer,
        customerId: customerId,
        establishmentId: null,
        branchId: null,
        phoneVerified: claims.phoneVerified,
        emailVerified: claims.emailVerified,
        tokenVersion: claims.tokenVersion,
      ),
    );
  }
}
