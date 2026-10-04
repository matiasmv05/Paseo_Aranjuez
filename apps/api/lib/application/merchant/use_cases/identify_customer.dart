/// HU-10 (US1): identificar a un cliente por telefono o QR (FR-003/FR-006).
library;

import 'package:paseo_api/application/identity/ports.dart' show Clock;
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/domain/identity/errors.dart' show IdentityException;
import 'package:paseo_api/domain/identity/phone_bo.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;

/// Entrada de [IdentifyCustomer]: telefono o token QR (el `oneOf`).
sealed class IdentifyInput {
  /// Crea la entrada.
  const IdentifyInput();
}

/// Identificacion por telefono E.164 (`+591...`).
final class IdentifyByPhone extends IdentifyInput {
  /// Crea la variante PHONE.
  const IdentifyByPhone(this.phone);

  /// Telefono crudo pedido por el comercio.
  final String phone;
}

/// Identificacion por token QR (opaco y firmado, vida ~60 s).
final class IdentifyByQr extends IdentifyInput {
  /// Crea la variante QR.
  const IdentifyByQr(this.token);

  /// Token QR escaneado.
  final String token;
}

/// Resuelve al cliente y devuelve un ticket firmado con su nombre enmascarado.
///
/// El ticket queda atado al `establishmentId` y (si el llamador es cajero)
/// a su `branchId`; el comercio nunca recibe el `customer_id` ni el nombre
/// completo (FR-003/FR-007, §8).
final class IdentifyCustomer {
  /// Crea el caso de uso.
  const IdentifyCustomer({
    required EstablishmentRepository establishments,
    required TicketSigner signer,
    required Clock clock,
  }) : _establishments = establishments,
       _signer = signer,
       _clock = clock;

  final EstablishmentRepository _establishments;
  final TicketSigner _signer;
  final Clock _clock;

  /// Identifica al cliente y emite el ticket de identificacion.
  Future<contract.IdentifyResult> call({
    required MerchantContext context,
    required IdentifyInput input,
  }) async {
    final now = _clock.nowUtc();
    final customer = switch (input) {
      IdentifyByPhone(:final phone) => await _byPhone(phone),
      IdentifyByQr(:final token) => await _byQr(token, now),
    };
    if (customer == null) {
      throw LoyaltyException.customerNotFound();
    }
    if (!customer.phoneVerified) {
      // Sin telefono verificado no se identifica ni se acredita (§6, §8).
      throw LoyaltyException.phoneNotVerified();
    }

    final claims = IdentificationTicketClaims(
      customerId: customer.userId,
      establishmentId: context.establishmentId,
      branchId: context.isCashier ? context.branchId : null,
      issuedAt: now,
      expiresAt: now.add(IdentificationTicketClaims.ttl),
    );
    return contract.IdentifyResult(
      ticket: _signer.signTicket(claims),
      expiresAt: claims.expiresAt,
      customerName: maskCustomerName(customer.fullName),
    );
  }

  Future<CustomerRecord?> _byPhone(String raw) async {
    final String phone;
    try {
      phone = PhoneBO.parse(raw).value;
    } on IdentityException catch (error) {
      if (error.code == contract.ApiErrorCode.phoneNotSupported) {
        throw LoyaltyException.phoneNotSupported();
      }
      throw LoyaltyException.validation(error.message);
    }
    return _establishments.findCustomerByPhone(phone);
  }

  Future<CustomerRecord?> _byQr(String token, DateTime now) async {
    final claims = _signer.verifyQr(token, now: now);
    if (claims == null) {
      throw LoyaltyException.invalidQrToken();
    }
    return _establishments.findCustomerByUserId(claims.customerId);
  }
}
