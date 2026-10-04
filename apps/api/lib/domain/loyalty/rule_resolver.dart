/// Seleccion de la regla base y de la campana aplicable a una compra.
library;

import 'package:paseo_api/domain/loyalty/loyalty_errors.dart';
import 'package:paseo_api/domain/loyalty/points_rule.dart';

/// Reglas resueltas para una compra: una base obligatoria y una campana
/// opcional que multiplica (`FR-013`).
final class ResolvedRules {
  /// Crea el resultado con la [base] y la [campaign] (o `null`).
  const ResolvedRules({required this.base, this.campaign});

  /// Regla base que define los tramos.
  final PointsRule base;

  /// Campana que multiplica, si hay una activa.
  final PointsRule? campaign;

  /// Fotografia de las reglas aplicadas para `purchases.rule_snapshot`.
  ///
  /// Congela la base y, si hubo, la campana (`FR-014`, `R-05`).
  Map<String, Object?> toSnapshot() => {
    'base': base.toSnapshot(),
    if (campaign != null) 'campaign': campaign!.toSnapshot(),
  };
}

/// Elige la regla base y la campana entre un conjunto candidato.
///
/// El repositorio entrega ya las reglas relevantes al comercio/categoria
/// (establecimiento + categoria + globales). El resolver solo filtra por
/// vigencia y aplica precedencia y desempate.
final class RuleResolver {
  /// Crea el resolver.
  const RuleResolver();

  /// Resuelve [rules] a la base y campana vigentes en [now].
  ///
  /// - Base: primera [PointsRuleScope] con candidatas (el orden del enum es
  ///   `ESTABLISHMENT > CATEGORY > GLOBAL`); dentro del alcance, menor
  ///   [PointsRule.priority] y, a igualdad, menor `id`.
  /// - Campana: como maximo una, tambien por menor `priority` y luego `id`.
  ///
  /// Lanza [LoyaltyException.noApplicableRule] si no hay base vigente.
  ResolvedRules resolve({
    required Iterable<PointsRule> rules,
    required DateTime now,
  }) {
    final active = rules.where((rule) => rule.isActiveAt(now)).toList();
    final base = _pickBase(active);
    if (base == null) {
      throw LoyaltyException.noApplicableRule();
    }
    return ResolvedRules(base: base, campaign: _pickCampaign(active));
  }

  PointsRule? _pickBase(List<PointsRule> active) {
    for (final scope in PointsRuleScope.values) {
      final candidates =
          active
              .where(
                (rule) =>
                    rule.type == PointsRuleType.base && rule.scope == scope,
              )
              .toList()
            ..sort(_byPriorityThenId);
      if (candidates.isNotEmpty) {
        return candidates.first;
      }
    }
    return null;
  }

  PointsRule? _pickCampaign(List<PointsRule> active) {
    final campaigns =
        active.where((rule) => rule.type == PointsRuleType.campaign).toList()
          ..sort(_byPriorityThenId);
    return campaigns.isEmpty ? null : campaigns.first;
  }

  static int _byPriorityThenId(PointsRule a, PointsRule b) {
    final byPriority = a.priority.compareTo(b.priority);
    return byPriority != 0 ? byPriority : a.id.compareTo(b.id);
  }
}
