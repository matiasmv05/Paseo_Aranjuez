import 'package:paseo_shared/paseo_shared.dart';
import 'package:test/test.dart';

void main() {
  group('DTOs de Redemptions y Gamificación (Persona 5)', () {
    test('RedemptionIssueRequest & Response round-trip', () {
      final req = RedemptionIssueRequest.fromJson({'reward_id': 'ben-01'});
      expect(req.rewardId, 'ben-01');
      expect(req.toJson(), {'reward_id': 'ben-01'});

      final resp = RedemptionIssueResponse.fromJson({
        'id': 'red-101',
        'code': 'PA-483921',
        'reward_id': 'ben-01',
        'points_spent': 500,
        'status': 'ISSUED',
        'expires_at': '2026-10-04T23:59:59Z',
      });
      expect(resp.code, 'PA-483921');
      expect(resp.pointsSpent, 500);
      expect(resp.toJson()['code'], 'PA-483921');
    });

    test('RedemptionValidateRequest & Response round-trip', () {
      final req = RedemptionValidateRequest.fromJson({'code': 'PA-483921'});
      expect(req.code, 'PA-483921');

      final resp = RedemptionValidateResponse.fromJson({
        'redemption_id': 'red-101',
        'reward_title': '20% en Café Aranjuez',
        'customer_masked_name': 'Val*** R.',
        'status': 'ISSUED',
        'can_redeem': true,
        'establishment_id': 'est-01',
      });
      expect(resp.canRedeem, isTrue);
      expect(resp.customerMaskedName, 'Val*** R.');
      expect(resp.toJson()['can_redeem'], isTrue);
    });

    test('RedemptionCompleteRequest & Response round-trip', () {
      final req = RedemptionCompleteRequest.fromJson({'code': 'PA-483921'});
      expect(req.code, 'PA-483921');

      final resp = RedemptionCompleteResponse.fromJson({
        'redemption_id': 'red-101',
        'status': 'USED',
        'completed_at': '2026-10-04T12:00:00Z',
      });
      expect(resp.status, 'USED');
      expect(resp.toJson()['status'], 'USED');
    });

    test('CustomerTierDto round-trip', () {
      final tier = CustomerTierDto.fromJson({
        'tier': 'ORO',
        'points': 2450,
        'next_tier': 'PLATINUM',
        'points_to_next_tier': 550,
        'progress_percentage': 81.6,
        'multiplier': 1.2,
        'benefits': ['1.2x en puntos', 'Fila preferencial'],
      });
      expect(tier.tier, 'ORO');
      expect(tier.points, 2450);
      expect(tier.progressPercentage, 81.6);
      expect(tier.benefits.length, 2);
      expect(tier.toJson()['next_tier'], 'PLATINUM');
    });

    test('PromotionProposalRequest & Response round-trip', () {
      final req = PromotionProposalRequest.fromJson({
        'title': '2x1 en cafés seleccionados',
        'description': 'Por aniversario de sucursal',
        'badge': 'Promoción',
        'valid_until': '2026-10-31',
      });
      expect(req.title, '2x1 en cafés seleccionados');

      final resp = PromotionProposalResponse.fromJson({
        'id': 'prom-prop-1',
        'title': '2x1 en cafés seleccionados',
        'status': 'PENDING_APPROVAL',
        'submitted_at': '2026-10-04T10:00:00Z',
      });
      expect(resp.status, 'PENDING_APPROVAL');
      expect(resp.toJson()['status'], 'PENDING_APPROVAL');
    });
  });
}
