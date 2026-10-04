import 'package:paseo_shared/paseo_shared.dart';
import 'package:test/test.dart';

void main() {
  group('DTOs de catalogo: contrato de docs/openapi.yaml '
      '(RewardSummary, EstablishmentSummary, BranchSummary)', () {
    test('RewardSummary: round-trip con los campos exactos del contrato', () {
      final reward = RewardSummary(
        id: 'a0000000-0000-4000-8000-000000000001',
        name: 'Cafe con leche gratis',
        description: 'Un cafe con leche mediano.',
        rewardType: 'GIFT',
        costPoints: 200,
        stock: 10,
        available: true,
        validFrom: DateTime.parse('2026-10-01T00:00:00.000Z'),
        validTo: DateTime.parse('2026-12-31T00:00:00.000Z'),
        establishmentId: 'e0000000-0000-4000-8000-000000000001',
      );

      final json = reward.toJson();
      expect(json, {
        'id': 'a0000000-0000-4000-8000-000000000001',
        'name': 'Cafe con leche gratis',
        'description': 'Un cafe con leche mediano.',
        'reward_type': 'GIFT',
        'cost_points': 200,
        'stock': 10,
        'available': true,
        'valid_from': '2026-10-01T00:00:00.000Z',
        'valid_to': '2026-12-31T00:00:00.000Z',
        'establishment_id': 'e0000000-0000-4000-8000-000000000001',
      });
      // Sin campos administrativos ni nombres fuera del contrato.
      expect(json.keys, isNot(contains('type')));
      expect(json.keys, isNot(contains('value_bp')));
      expect(json.keys, isNot(contains('value_cents')));
      expect(json.keys, isNot(contains('approved_by')));

      expect(RewardSummary.fromJson(json), reward);
    });

    test('RewardSummary: stock null (sin limite) y vigencias nulas', () {
      const reward = RewardSummary(
        id: 'r-1',
        name: 'Descuento del 10%',
        description: 'En tu proxima compra.',
        rewardType: 'PERCENT',
        costPoints: 100,
        available: true,
        establishmentId: 'e-1',
      );

      final json = reward.toJson();
      expect(json['stock'], isNull);
      expect(json['valid_from'], isNull);
      expect(json['valid_to'], isNull);

      final back = RewardSummary.fromJson(json);
      expect(back.stock, isNull);
      expect(back.validFrom, isNull);
      expect(back.validTo, isNull);
    });

    test('RewardSummary equality', () {
      RewardSummary build(String id) => RewardSummary(
        id: id,
        name: 'R',
        description: 'D',
        rewardType: 'FIXED',
        costPoints: 300,
        available: false,
        establishmentId: 'e-1',
      );

      expect(build('a'), equals(build('a')));
      expect(build('a'), isNot(equals(build('b'))));
    });

    test('EstablishmentSummary: con sucursales (BranchSummary)', () {
      const establishment = EstablishmentSummary(
        id: 'e-1',
        name: 'Cafe Aranjuez',
        category: 'CAFE',
        branches: const [
          BranchSummary(id: 'b-1', name: 'Principal', address: 'Av. 100'),
          BranchSummary(id: 'b-2', name: 'Sur', address: 'Calle 25'),
        ],
      );

      final json = establishment.toJson();
      expect(json['id'], 'e-1');
      expect(json['name'], 'Cafe Aranjuez');
      expect(json['category'], 'CAFE');
      expect(json['branches'], [
        {'id': 'b-1', 'name': 'Principal', 'address': 'Av. 100'},
        {'id': 'b-2', 'name': 'Sur', 'address': 'Calle 25'},
      ]);
      // Nunca campos administrativos (spec 002, HU-09).
      expect(json.keys, isNot(contains('max_purchase_cents')));
      expect(json.keys, isNot(contains('compliance_status')));

      final back = EstablishmentSummary.fromJson(json);
      expect(back.branches, establishment.branches);
      expect(back.id, establishment.id);
    });
  });
}
