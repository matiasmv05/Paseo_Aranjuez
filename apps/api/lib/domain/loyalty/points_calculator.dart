/// Calculo de puntos de una compra (`FR-012`, `FR-013`).
///
/// Formula entera, sin `double`:
///   puntos_base = redondeo(net_cents * points_awarded / amount_per_tier_cents)
///   tras_multiplicador = redondeo(puntos_base * multiplier_bp / 10000)
///   puntos = min(tras_multiplicador, max_points_per_purchase)
/// con los tramos redondeados como declara cada regla. Si la regla base no
/// tiene tope, no se recorta.
library;

import 'package:paseo_api/domain/loyalty/cents.dart';
import 'package:paseo_api/domain/loyalty/points_rule.dart';
import 'package:paseo_api/domain/loyalty/rounding.dart';

/// Resultado del calculo, con los intermedios para el desglose del contrato
/// (`CalculationBreakdown`).
final class PointsOutcome {
  /// Crea el resultado completo.
  const PointsOutcome({
    required this.points,
    required this.pointsBase,
    required this.multiplierBp,
    required this.pointsAfterMultiplier,
    required this.pointsBeforeCap,
    required this.capApplied,
    required this.belowMinPurchase,
    required this.rounding,
  });

  /// Puntos efectivamente otorgados.
  final int points;

  /// Puntos del tramo, antes del multiplicador.
  final int pointsBase;

  /// Multiplicador aplicado en puntos basicos, tal como vino en la regla
  /// (`0` = sin multiplicador).
  final int multiplierBp;

  /// Puntos despues del multiplicador.
  final int pointsAfterMultiplier;

  /// Puntos antes del recorte por tope (igual a [pointsAfterMultiplier]).
  final int pointsBeforeCap;

  /// `true` si el tope recorto los puntos.
  final bool capApplied;

  /// `true` si la compra no alcanzo el minimo; [points] es `0`.
  final bool belowMinPurchase;

  /// Redondeo de la regla base.
  final Rounding rounding;
}

/// Calculadora determinista de puntos.
final class PointsCalculator {
  /// Crea la calculadora.
  const PointsCalculator();

  /// Calcula los puntos de una compra de [netCents].
  ///
  /// La [base] define tramos, minimo, redondeo y tope; la [campaign]
  /// opcional aporta su multiplicador y su redondeo para el segundo paso.
  /// El tope efectivo es el menor de los topes definidos (base y campana).
  PointsOutcome calculate({
    required Cents netCents,
    required PointsRule base,
    PointsRule? campaign,
  }) {
    final net = netCents.value;
    final belowMinPurchase = net < base.minPurchaseCents;

    final pointsBase = base.rounding.divide(
      net * base.pointsAwarded,
      base.amountPerTierCents,
    );

    final multiplierBp = campaign?.multiplierBp ?? base.multiplierBp;
    final effectiveBp = multiplierBp == 0 ? 10000 : multiplierBp;
    final multiplierRounding = campaign?.rounding ?? base.rounding;
    final afterMultiplier = multiplierRounding.divide(
      pointsBase * effectiveBp,
      10000,
    );

    final cap = _effectiveCap(base, campaign);
    var points = afterMultiplier;
    var capApplied = false;
    if (cap != null && points > cap) {
      points = cap;
      capApplied = true;
    }
    if (belowMinPurchase) {
      points = 0;
    }

    return PointsOutcome(
      points: points,
      pointsBase: pointsBase,
      multiplierBp: multiplierBp,
      pointsAfterMultiplier: afterMultiplier,
      pointsBeforeCap: afterMultiplier,
      capApplied: capApplied,
      belowMinPurchase: belowMinPurchase,
      rounding: base.rounding,
    );
  }

  int? _effectiveCap(PointsRule base, PointsRule? campaign) {
    final caps = [
      base.maxPointsPerPurchase,
      campaign?.maxPointsPerPurchase,
    ].whereType<int>();
    if (caps.isEmpty) {
      return null;
    }
    return caps.reduce((a, b) => a < b ? a : b);
  }
}
