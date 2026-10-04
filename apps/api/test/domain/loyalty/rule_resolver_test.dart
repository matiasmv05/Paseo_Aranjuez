import 'package:paseo_api/domain/loyalty/loyalty.dart';
import 'package:paseo_shared/paseo_shared.dart' show ApiErrorCode;
import 'package:test/test.dart';

void main() {
  const resolver = RuleResolver();
  final now = DateTime.utc(2025, 1, 1);

  PointsRule rule({
    required PointsRuleScope scope,
    String id = 'rule',
    PointsRuleType type = PointsRuleType.base,
    int priority = 100,
    DateTime? validFrom,
    DateTime? validTo,
  }) => PointsRule(
    id: id,
    scope: scope,
    type: type,
    priority: priority,
    pointsAwarded: 10,
    amountPerTierCents: 10000,
    multiplierBp: 10000,
    maxPointsPerPurchase: null,
    minPurchaseCents: 0,
    rounding: Rounding.floor,
    validFrom: validFrom ?? DateTime.utc(2020),
    validTo: validTo,
  );

  group('RuleResolver.resolve (FR-013, AGENTS.md §7)', () {
    test('prefiere ESTABLISHMENT sobre CATEGORY y GLOBAL', () {
      final resolved = resolver.resolve(
        rules: [
          rule(scope: PointsRuleScope.global, id: 'g'),
          rule(scope: PointsRuleScope.category, id: 'c'),
          rule(scope: PointsRuleScope.establishment, id: 'e'),
        ],
        now: now,
      );
      expect(resolved.base.id, 'e');
    });

    test('prefiere CATEGORY sobre GLOBAL', () {
      final resolved = resolver.resolve(
        rules: [
          rule(scope: PointsRuleScope.global, id: 'g'),
          rule(scope: PointsRuleScope.category, id: 'c'),
        ],
        now: now,
      );
      expect(resolved.base.id, 'c');
    });

    test(
      'la precedencia de alcance gana a una priority menor de otro alcance',
      () {
        final resolved = resolver.resolve(
          rules: [
            rule(scope: PointsRuleScope.global, id: 'g', priority: 1),
            rule(scope: PointsRuleScope.establishment, id: 'e', priority: 99),
          ],
          now: now,
        );
        expect(resolved.base.id, 'e');
      },
    );

    test('desempata por priority ascendente dentro del mismo alcance', () {
      final resolved = resolver.resolve(
        rules: [
          rule(scope: PointsRuleScope.global, id: 'b', priority: 50),
          rule(scope: PointsRuleScope.global, id: 'a', priority: 10),
          rule(scope: PointsRuleScope.global, id: 'c', priority: 90),
        ],
        now: now,
      );
      expect(resolved.base.id, 'a');
    });

    test('ignora reglas no vigentes', () {
      final resolved = resolver.resolve(
        rules: [
          rule(
            scope: PointsRuleScope.establishment,
            id: 'vencida',
            validTo: DateTime.utc(2024),
          ),
          rule(scope: PointsRuleScope.global, id: 'vigente'),
        ],
        now: now,
      );
      expect(resolved.base.id, 'vigente');
    });

    test('una regla que vence justo en now ya no aplica', () {
      expect(
        () => resolver.resolve(
          rules: [rule(scope: PointsRuleScope.global, validTo: now)],
          now: now,
        ),
        throwsA(
          isA<LoyaltyException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.noApplicableRule,
          ),
        ),
      );
    });

    test('lanza NO_APPLICABLE_RULE sin ninguna regla', () {
      expect(
        () => resolver.resolve(rules: const [], now: now),
        throwsA(
          isA<LoyaltyException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.noApplicableRule,
          ),
        ),
      );
    });

    test('elige a lo sumo una campana, la de menor priority', () {
      final resolved = resolver.resolve(
        rules: [
          rule(scope: PointsRuleScope.global, id: 'base'),
          rule(
            scope: PointsRuleScope.global,
            id: 'camp-alta',
            type: PointsRuleType.campaign,
            priority: 5,
          ),
          rule(
            scope: PointsRuleScope.global,
            id: 'camp-baja',
            type: PointsRuleType.campaign,
            priority: 90,
          ),
        ],
        now: now,
      );
      expect(resolved.campaign?.id, 'camp-alta');
    });

    test('sin campana vigente devuelve campaign == null', () {
      final resolved = resolver.resolve(
        rules: [rule(scope: PointsRuleScope.global, id: 'base')],
        now: now,
      );
      expect(resolved.campaign, isNull);
    });
  });
}
