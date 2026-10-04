/// HU-11 (US2): registrar una compra y acreditar puntos (FR-009/FR-016).
///
/// Recibe **solo el ticket** (nunca un telefono ni un `customer_id`, FR-007).
/// Idempotente por `(establishment_id, idempotency_key)` y unico por
/// `(establishment_id, invoice_ref)` (§9, FR-016).
library;

import 'package:paseo_api/application/identity/ports.dart' show Clock;
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;

/// Resultado del registro: la compra y si se creo en esta llamada.
///
/// `created == false` es un replay idempotente y la ruta responde `200`;
/// `true` es una creacion nueva y responde `201` (§9).
final class RegisterPurchaseOutcome {
  /// Crea el resultado.
  const RegisterPurchaseOutcome({
    required this.purchase,
    required this.created,
  });

  /// Compra tal como la expone el contrato.
  final contract.Purchase purchase;

  /// `true` si se inserto ahora; `false` si es replay de la misma clave.
  final bool created;
}

/// Registra la compra, calcula los puntos y persiste el credito.
final class RegisterPurchase {
  /// Crea el caso de uso.
  const RegisterPurchase({
    required TicketSigner signer,
    required PointsRuleRepository rules,
    required RuleResolver resolver,
    required PointsCalculator calculator,
    required PurchaseRepository purchases,
    required Clock clock,
  }) : _signer = signer,
       _rules = rules,
       _resolver = resolver,
       _calculator = calculator,
       _purchases = purchases,
       _clock = clock;

  final TicketSigner _signer;
  final PointsRuleRepository _rules;
  final RuleResolver _resolver;
  final PointsCalculator _calculator;
  final PurchaseRepository _purchases;
  final Clock _clock;

  /// Verifica el ticket, aplica idempotencia y persiste la compra.
  Future<RegisterPurchaseOutcome> call({
    required MerchantContext context,
    required contract.RegisterPurchaseRequest request,
    required String idempotencyKey,
  }) async {
    final now = _clock.nowUtc();
    final claims = _verifyTicket(request.ticket, context, now);
    final establishmentId = context.establishmentId;

    // Replay: mismo key, misma respuesta original sin volver a mover el
    // ledger (§9). Se consulta antes de calcular.
    final replay = await _purchases.findByIdempotencyKey(
      establishmentId: establishmentId,
      idempotencyKey: idempotencyKey,
    );
    if (replay != null) {
      return RegisterPurchaseOutcome(purchase: _toDto(replay), created: false);
    }

    validatePurchaseAmounts(
      grossCents: request.grossCents,
      discountCents: request.discountCents,
      netCents: request.netCents,
    );
    final invoiceRef = request.invoiceRef.trim();
    if (invoiceRef.isEmpty) {
      throw LoyaltyException.validation('invoice_ref es obligatorio');
    }
    final branchId = _branchFor(context, claims);

    final duplicate = await _purchases.findByInvoiceRef(
      establishmentId: establishmentId,
      invoiceRef: invoiceRef,
    );
    if (duplicate != null) {
      throw LoyaltyException.duplicateInvoice();
    }

    final resolved = await _resolve(context, now);
    final outcome = _calculator.calculate(
      netCents: Cents(request.netCents),
      base: resolved.base,
      campaign: resolved.campaign,
    );

    final draft = PurchaseDraft(
      establishmentId: establishmentId,
      branchId: branchId,
      customerId: claims.customerId,
      sellerUserId: context.userId,
      grossCents: request.grossCents,
      discountCents: request.discountCents,
      netCents: request.netCents,
      invoiceRef: invoiceRef,
      ruleId: resolved.base.id,
      campaignRuleId: resolved.campaign?.id,
      ruleSnapshot: resolved.toSnapshot(),
      idempotencyKey: idempotencyKey,
      pointsCredited: outcome.points,
    );

    final Purchase purchase;
    try {
      purchase = await _purchases.insert(draft);
    } on PurchaseUniqueViolation catch (violation) {
      switch (violation.field) {
        case PurchaseUniqueField.idempotencyKey:
          // Carrera con otro request identico: devolver el ganador (200).
          final existing = await _purchases.findByIdempotencyKey(
            establishmentId: establishmentId,
            idempotencyKey: idempotencyKey,
          );
          if (existing == null) {
            rethrow;
          }
          return RegisterPurchaseOutcome(
            purchase: _toDto(existing),
            created: false,
          );
        case PurchaseUniqueField.invoiceRef:
          throw LoyaltyException.duplicateInvoice();
      }
    }
    return RegisterPurchaseOutcome(purchase: _toDto(purchase), created: true);
  }

  IdentificationTicketClaims _verifyTicket(
    String token,
    MerchantContext context,
    DateTime now,
  ) {
    final claims = _signer.verifyTicket(token, now: now);
    if (claims == null || claims.establishmentId != context.establishmentId) {
      throw LoyaltyException.invalidIdentificationTicket();
    }
    if (context.isCashier && claims.branchId != context.branchId) {
      throw LoyaltyException.invalidIdentificationTicket();
    }
    return claims;
  }

  Future<ResolvedRules> _resolve(MerchantContext context, DateTime now) async {
    final rules = await _rules.findApplicableRules(
      establishmentId: context.establishmentId,
      now: now,
    );
    return _resolver.resolve(rules: rules, now: now);
  }

  String _branchFor(
    MerchantContext context,
    IdentificationTicketClaims claims,
  ) {
    // El cajero ya quedo atado a su sucursal en el ticket; el dueno la toma
    // de su contexto. Sin sucursal no se puede atribuir la venta (§10.1).
    final branchId = claims.branchId ?? context.branchId;
    if (branchId == null) {
      throw LoyaltyException.validation('no hay sucursal asociada a la venta');
    }
    return branchId;
  }

  contract.Purchase _toDto(Purchase purchase) => contract.Purchase(
    id: purchase.id,
    invoiceRef: purchase.invoiceRef,
    grossCents: purchase.grossCents,
    discountCents: purchase.discountCents,
    netCents: purchase.netCents,
    pointsCredited: purchase.pointsCredited,
    ruleId: purchase.ruleId,
    campaignRuleId: purchase.campaignRuleId,
    createdAt: purchase.createdAt,
  );
}
