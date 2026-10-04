/// HU-11 (US3): previsualizar los puntos de una compra (FR-012/FR-013).
///
/// No escribe nada: no pide `invoice_ref` ni `Idempotency-Key`. Usa el mismo
/// motor (`RuleResolver` + `PointsCalculator`) que el registro, para que el
/// preview y la compra nunca discrepen (§7).
library;

import 'package:paseo_api/application/identity/ports.dart' show Clock;
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;

/// Calcula los puntos de una compra sin persistirla.
final class PreviewPurchase {
  /// Crea el caso de uso.
  const PreviewPurchase({
    required TicketSigner signer,
    required PointsRuleRepository rules,
    required RuleResolver resolver,
    required PointsCalculator calculator,
    required Clock clock,
  }) : _signer = signer,
       _rules = rules,
       _resolver = resolver,
       _calculator = calculator,
       _clock = clock;

  final TicketSigner _signer;
  final PointsRuleRepository _rules;
  final RuleResolver _resolver;
  final PointsCalculator _calculator;
  final Clock _clock;

  /// Verifica el ticket, resuelve reglas y devuelve el desglose completo.
  Future<contract.PreviewPurchaseResult> call({
    required MerchantContext context,
    required contract.PreviewPurchaseRequest request,
  }) async {
    final now = _clock.nowUtc();
    _verifyTicket(request.ticket, context, now);
    validatePurchaseAmounts(
      grossCents: request.grossCents,
      discountCents: request.discountCents,
      netCents: request.netCents,
    );

    final resolved = await _resolve(context, now);
    final outcome = _calculator.calculate(
      netCents: Cents(request.netCents),
      base: resolved.base,
      campaign: resolved.campaign,
    );

    return contract.PreviewPurchaseResult(
      points: outcome.points,
      ruleId: resolved.base.id,
      campaignRuleId: resolved.campaign?.id,
      breakdown: contract.CalculationBreakdown(
        pointsBase: outcome.pointsBase,
        multiplierBp: outcome.multiplierBp,
        pointsAfterMultiplier: outcome.pointsAfterMultiplier,
        pointsBeforeCap: outcome.pointsBeforeCap,
        capApplied: outcome.capApplied,
        belowMinPurchase: outcome.belowMinPurchase,
        rounding: contract.Rounding.fromWire(outcome.rounding.wire),
      ),
    );
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
}
