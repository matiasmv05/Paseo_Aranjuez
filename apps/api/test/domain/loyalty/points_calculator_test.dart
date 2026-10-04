import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:test/test.dart';

void main() {
  const calculator = PointsCalculator();
  final anyDate = DateTime.utc(2024);

  PointsRule baseRule({
    int pointsAwarded = 10,
    int amountPerTierCents = 10000,
    int multiplierBp = 10000,
    int? maxPointsPerPurchase,
    int minPurchaseCents = 0,
    Rounding rounding = Rounding.floor,
  }) => PointsRule(
    id: 'base',
    scope: PointsRuleScope.global,
    type: PointsRuleType.base,
    priority: 100,
    pointsAwarded: pointsAwarded,
    amountPerTierCents: amountPerTierCents,
    multiplierBp: multiplierBp,
    maxPointsPerPurchase: maxPointsPerPurchase,
    minPurchaseCents: minPurchaseCents,
    rounding: rounding,
    validFrom: anyDate,
  );

  PointsRule campaign({
    int multiplierBp = 20000,
    Rounding rounding = Rounding.floor,
    int? maxPointsPerPurchase,
  }) => PointsRule(
    id: 'camp',
    scope: PointsRuleScope.global,
    type: PointsRuleType.campaign,
    priority: 100,
    pointsAwarded: 10,
    amountPerTierCents: 10000,
    multiplierBp: multiplierBp,
    maxPointsPerPurchase: maxPointsPerPurchase,
    minPurchaseCents: 0,
    rounding: rounding,
    validFrom: anyDate,
  );

  group('PointsCalculator.calculate (FR-012)', () {
    test('un tramo completo otorga points_awarded', () {
      final out = calculator.calculate(
        netCents: Cents(10000),
        base: baseRule(),
      );
      expect(out.pointsBase, 10);
      expect(out.points, 10);
      expect(out.belowMinPurchase, isFalse);
    });

    // (net, FLOOR, ROUND, CEIL) sobre 10 pts / 10000
    final redondeos = <(int, int, int, int)>[
      (15000, 15, 15, 15),
      (19999, 19, 20, 20),
      (9999, 9, 10, 10),
      (1000, 1, 1, 1),
      (0, 0, 0, 0),
    ];
    for (final (net, floor, round, ceil) in redondeos) {
      test('net=$net con FLOOR/ROUND/CEIL', () {
        int points(Rounding mode) => calculator
            .calculate(
              netCents: Cents(net),
              base: baseRule(rounding: mode),
            )
            .points;
        expect(points(Rounding.floor), floor);
        expect(points(Rounding.round), round);
        expect(points(Rounding.ceil), ceil);
      });
    }

    test('redondeo de .5 exacto: medio hacia arriba con ROUND', () {
      final rule = baseRule(pointsAwarded: 1, amountPerTierCents: 1000);
      int points(Rounding mode) => calculator
          .calculate(netCents: Cents(500), base: rule.copyWith(mode))
          .points;
      expect(points(Rounding.floor), 0);
      expect(points(Rounding.round), 1);
      expect(points(Rounding.ceil), 1);
    });

    test('bajo el minimo de compra otorga 0 y lo marca', () {
      final out = calculator.calculate(
        netCents: Cents(9999),
        base: baseRule(minPurchaseCents: 10000),
      );
      expect(out.belowMinPurchase, isTrue);
      expect(out.points, 0);
    });

    test('recorta en el tope y marca cap_applied', () {
      final out = calculator.calculate(
        netCents: Cents(100000),
        base: baseRule(maxPointsPerPurchase: 3),
      );
      expect(out.pointsBeforeCap, 100);
      expect(out.points, 3);
      expect(out.capApplied, isTrue);
    });

    test('la campana multiplica en puntos basicos', () {
      final out = calculator.calculate(
        netCents: Cents(10000),
        base: baseRule(),
        campaign: campaign(multiplierBp: 20000),
      );
      expect(out.pointsBase, 10);
      expect(out.multiplierBp, 20000);
      expect(out.pointsAfterMultiplier, 20);
      expect(out.points, 20);
    });

    test('multiplier_bp == 0 significa sin multiplicador', () {
      final out = calculator.calculate(
        netCents: Cents(10000),
        base: baseRule(),
        campaign: campaign(multiplierBp: 0),
      );
      expect(out.multiplierBp, 0);
      expect(out.points, 10);
    });

    test('el segundo paso usa el redondeo de la campana', () {
      final out = calculator.calculate(
        netCents: Cents(1),
        base: baseRule(
          pointsAwarded: 1,
          amountPerTierCents: 1,
          rounding: Rounding.floor,
        ),
        campaign: campaign(multiplierBp: 15000, rounding: Rounding.round),
      );
      expect(out.pointsBase, 1);
      expect(out.pointsAfterMultiplier, 2);
    });

    test('el tope efectivo es el menor entre base y campana', () {
      final out = calculator.calculate(
        netCents: Cents(100000),
        base: baseRule(maxPointsPerPurchase: 10),
        campaign: campaign(multiplierBp: 10000, maxPointsPerPurchase: 4),
      );
      expect(out.points, 4);
      expect(out.capApplied, isTrue);
    });
  });
}

extension on PointsRule {
  PointsRule copyWith(Rounding rounding) => PointsRule(
    id: id,
    scope: scope,
    type: type,
    priority: priority,
    pointsAwarded: pointsAwarded,
    amountPerTierCents: amountPerTierCents,
    multiplierBp: multiplierBp,
    maxPointsPerPurchase: maxPointsPerPurchase,
    minPurchaseCents: minPurchaseCents,
    rounding: rounding,
    validFrom: validFrom,
    validTo: validTo,
  );
}
