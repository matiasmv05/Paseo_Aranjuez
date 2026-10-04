/// Compra del comercio y sus invariantes (`FR-009`, `FR-016`).
library;

import 'package:paseo_api/domain/loyalty/loyalty_errors.dart';

/// Datos validados de una compra antes de persistirla.
///
/// El caso de uso arma el borrador con el neto ya calculado; el repositorio
/// lo inserta y devuelve una [Purchase] con `id` y `created_at` de la base.
final class PurchaseDraft {
  /// Valida y crea el borrador.
  ///
  /// Lanza [LoyaltyException.validation] si los montos son negativos, si
  /// `net != gross - discount`, si `invoice_ref` viene vacio o si falta la
  /// clave de idempotencia.
  factory PurchaseDraft({
    required String establishmentId,
    required String branchId,
    required String customerId,
    required String sellerUserId,
    required int grossCents,
    required int discountCents,
    required int netCents,
    required String invoiceRef,
    required String ruleId,
    required String? campaignRuleId,
    required Map<String, Object?> ruleSnapshot,
    required String idempotencyKey,
    required int pointsCredited,
  }) {
    _validateAmounts(grossCents, discountCents, netCents);
    if (pointsCredited < 0) {
      throw LoyaltyException.validation(
        'points_credited no puede ser negativo',
      );
    }
    final ref = invoiceRef.trim();
    if (ref.isEmpty) {
      throw LoyaltyException.validation('invoice_ref es obligatorio');
    }
    if (idempotencyKey.trim().isEmpty) {
      throw LoyaltyException.validation('Idempotency-Key es obligatoria');
    }
    return PurchaseDraft._(
      establishmentId: establishmentId,
      branchId: branchId,
      customerId: customerId,
      sellerUserId: sellerUserId,
      grossCents: grossCents,
      discountCents: discountCents,
      netCents: netCents,
      invoiceRef: ref,
      ruleId: ruleId,
      campaignRuleId: campaignRuleId,
      ruleSnapshot: ruleSnapshot,
      idempotencyKey: idempotencyKey,
      pointsCredited: pointsCredited,
    );
  }

  const PurchaseDraft._({
    required this.establishmentId,
    required this.branchId,
    required this.customerId,
    required this.sellerUserId,
    required this.grossCents,
    required this.discountCents,
    required this.netCents,
    required this.invoiceRef,
    required this.ruleId,
    required this.campaignRuleId,
    required this.ruleSnapshot,
    required this.idempotencyKey,
    required this.pointsCredited,
  });

  /// Comercio que registra la compra.
  final String establishmentId;

  /// Sucursal donde ocurrio.
  final String branchId;

  /// Cliente identificado.
  final String customerId;

  /// Cajero/dueno que registra.
  final String sellerUserId;

  /// Monto bruto en centavos.
  final int grossCents;

  /// Descuento en centavos.
  final int discountCents;

  /// Monto neto en centavos (`gross - discount`).
  final int netCents;

  /// Referencia de factura normalizada.
  final String invoiceRef;

  /// Regla base aplicada.
  final String ruleId;

  /// Campana aplicada, si hubo.
  final String? campaignRuleId;

  /// Fotografia de las reglas usadas.
  final Map<String, Object?> ruleSnapshot;

  /// Clave de idempotencia de la peticion.
  final String idempotencyKey;

  /// Puntos otorgados.
  final int pointsCredited;
}

/// Compra persistida (lectura).
final class Purchase {
  /// Valida y crea la compra con los datos de la base.
  factory Purchase({
    required String id,
    required String establishmentId,
    required String branchId,
    required String customerId,
    required String sellerUserId,
    required int grossCents,
    required int discountCents,
    required int netCents,
    required String invoiceRef,
    required String ruleId,
    required String? campaignRuleId,
    required Map<String, Object?> ruleSnapshot,
    required String idempotencyKey,
    required int pointsCredited,
    required DateTime createdAt,
  }) {
    _validateAmounts(grossCents, discountCents, netCents);
    final ref = invoiceRef.trim();
    if (ref.isEmpty) {
      throw LoyaltyException.validation('invoice_ref es obligatorio');
    }
    return Purchase._(
      id: id,
      establishmentId: establishmentId,
      branchId: branchId,
      customerId: customerId,
      sellerUserId: sellerUserId,
      grossCents: grossCents,
      discountCents: discountCents,
      netCents: netCents,
      invoiceRef: ref,
      ruleId: ruleId,
      campaignRuleId: campaignRuleId,
      ruleSnapshot: ruleSnapshot,
      idempotencyKey: idempotencyKey,
      pointsCredited: pointsCredited,
      createdAt: createdAt,
    );
  }

  const Purchase._({
    required this.id,
    required this.establishmentId,
    required this.branchId,
    required this.customerId,
    required this.sellerUserId,
    required this.grossCents,
    required this.discountCents,
    required this.netCents,
    required this.invoiceRef,
    required this.ruleId,
    required this.campaignRuleId,
    required this.ruleSnapshot,
    required this.idempotencyKey,
    required this.pointsCredited,
    required this.createdAt,
  });

  /// Identificador de la compra.
  final String id;

  /// Comercio.
  final String establishmentId;

  /// Sucursal.
  final String branchId;

  /// Cliente.
  final String customerId;

  /// Cajero/dueno.
  final String sellerUserId;

  /// Monto bruto en centavos.
  final int grossCents;

  /// Descuento en centavos.
  final int discountCents;

  /// Monto neto en centavos.
  final int netCents;

  /// Referencia de factura.
  final String invoiceRef;

  /// Regla base aplicada.
  final String ruleId;

  /// Campana aplicada, si hubo.
  final String? campaignRuleId;

  /// Fotografia de las reglas usadas.
  final Map<String, Object?> ruleSnapshot;

  /// Clave de idempotencia.
  final String idempotencyKey;

  /// Puntos otorgados.
  final int pointsCredited;

  /// Momento de registro.
  final DateTime createdAt;
}

void _validateAmounts(int gross, int discount, int net) {
  if (gross < 0 || discount < 0 || net < 0) {
    throw LoyaltyException.validation('los montos no pueden ser negativos');
  }
  if (net != gross - discount) {
    throw LoyaltyException.validation(
      'net_cents debe ser gross_cents - discount_cents',
    );
  }
}
