/// Regla de conversion de puntos (entidad `points_rules`, V005).
library;

import 'package:paseo_api/domain/loyalty/rounding.dart';

/// Alcance de una regla; el orden del enum es el de precedencia.
///
/// `ESTABLISHMENT` gana sobre `CATEGORY`, que gana sobre `GLOBAL`
/// (`AGENTS.md` §7). El resolver depende de este orden.
enum PointsRuleScope {
  establishment('ESTABLISHMENT'),
  category('CATEGORY'),
  global('GLOBAL');

  const PointsRuleScope(this.wire);

  /// Valor textual del contrato.
  final String wire;

  /// Devuelve el alcance de [value] o lanza [FormatException].
  static PointsRuleScope fromWire(String value) => values.firstWhere(
    (scope) => scope.wire == value,
    orElse: () => throw FormatException('scope desconocido: $value'),
  );
}

/// Tipo de regla. Solo una `BASE` aplica la conversion; una `CAMPAIGN`
/// opcional la multiplica (`FR-013`).
enum PointsRuleType {
  base('BASE'),
  campaign('CAMPAIGN');

  const PointsRuleType(this.wire);

  /// Valor textual del contrato.
  final String wire;

  /// Devuelve el tipo de [value] o lanza [FormatException].
  static PointsRuleType fromWire(String value) => values.firstWhere(
    (type) => type.wire == value,
    orElse: () => throw FormatException('type desconocido: $value'),
  );
}

/// Una regla de conversion, con la vigencia y los parametros que la toman
/// aplicable a una compra.
final class PointsRule {
  const PointsRule({
    required this.id,
    required this.scope,
    required this.type,
    required this.priority,
    required this.pointsAwarded,
    required this.amountPerTierCents,
    required this.multiplierBp,
    required this.maxPointsPerPurchase,
    required this.minPurchaseCents,
    required this.rounding,
    required this.validFrom,
    this.establishmentId,
    this.categoryId,
    this.validTo,
  });

  /// Identificador de la regla.
  final String id;

  /// Alcance: comercio, categoria o global.
  final PointsRuleScope scope;

  /// Tipo: base o campana.
  final PointsRuleType type;

  /// Prioridad de desempate; a menor numero, mayor precedencia.
  final int priority;

  /// Puntos por tramo cumplido (`points_awarded`).
  final int pointsAwarded;

  /// Tamano del tramo en centavos (`amount_per_tier_cents`), `> 0`.
  final int amountPerTierCents;

  /// Multiplicador en puntos basicos (10000 = x1). `0` = `AGENTS.md` §7.
  final int multiplierBp;

  /// Tope de puntos por compra; `null` = sin tope.
  final int? maxPointsPerPurchase;

  /// Compra minima en centavos para otorgar puntos.
  final int minPurchaseCents;

  /// Modo de redondeo de los tramos.
  final Rounding rounding;

  /// Inicio de vigencia (inclusive).
  final DateTime validFrom;

  /// Fin de vigencia (exclusive); `null` = sin fin.
  final DateTime? validTo;

  /// Comercio al que aplica si [scope] es `ESTABLISHMENT`.
  final String? establishmentId;

  /// Categoria a la que aplica si [scope] es `CATEGORY`.
  final String? categoryId;

  /// `true` si la regla esta vigente en [now].
  ///
  /// `valid_from` es inclusive y `valid_to` exclusive: una regla que termina
  /// justo en [now] ya no aplica.
  bool isActiveAt(DateTime now) =>
      !validFrom.isAfter(now) && (validTo == null || validTo!.isAfter(now));

  /// Fotografia de parametros para `purchases.rule_snapshot` (JSONB).
  ///
  /// Congela la regla tal como se aplico, para poder auditar la conversion
  /// aunque la regla cambie despues (`FR-014`, `R-05`).
  Map<String, Object?> toSnapshot() => {
    'id': id,
    'scope': scope.wire,
    'type': type.wire,
    'priority': priority,
    'points_awarded': pointsAwarded,
    'amount_per_tier_cents': amountPerTierCents,
    'multiplier_bp': multiplierBp,
    'max_points_per_purchase': maxPointsPerPurchase,
    'min_purchase_cents': minPurchaseCents,
    'rounding': rounding.wire,
    'valid_from': validFrom.toUtc().toIso8601String(),
    'valid_to': validTo?.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) => other is PointsRule && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PointsRule($id, ${scope.wire}, ${type.wire}, priority=$priority)';
}
