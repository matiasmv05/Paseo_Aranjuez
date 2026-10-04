import 'package:paseo_shared/paseo_shared.dart';
import 'package:test/test.dart';

void main() {
  group(
    'DTOs de puntos: contrato de docs/openapi.yaml (Balance, Movement)',
    () {
      test('Balance: round-trip con balance_points y updated_at', () {
        final dateTime = DateTime.parse('2024-01-15T10:30:00.000Z');
        final balance = Balance(balancePoints: 1250, updatedAt: dateTime);

        final json = balance.toJson();
        expect(json['balance_points'], 1250);
        expect(json['updated_at'], '2024-01-15T10:30:00.000Z');
        expect(json.keys, isNot(contains('points')));
        expect(json.keys, isNot(contains('last_updated')));

        final back = Balance.fromJson(json);
        expect(back, balance);
      });

      test('Movement: round-trip con los campos exactos del contrato', () {
        final dateTime = DateTime.parse('2024-01-15T10:30:00.000Z');
        final movement = Movement(
          id: '70000000-0000-4000-8000-000000000001',
          type: 'CREDIT',
          deltaPoints: 150,
          occurredAt: dateTime,
          origin: 'purchase',
          referenceId: 'COMP-001',
          balanceAfter: 1400,
        );

        final json = movement.toJson();
        expect(json, {
          'id': '70000000-0000-4000-8000-000000000001',
          'type': 'CREDIT',
          'delta_points': 150,
          'occurred_at': '2024-01-15T10:30:00.000Z',
          'origin': 'purchase',
          'reference_id': 'COMP-001',
          'balance_after': 1400,
        });

        final back = Movement.fromJson(json);
        expect(back, movement);
      });

      test('Movement: type admite los 5 valores del enum del contrato', () {
        final dateTime = DateTime.parse('2024-01-15T10:30:00.000Z');
        for (final type in [
          'CREDIT',
          'REDEEM',
          'ADJUST',
          'BONUS',
          'REVERSAL',
        ]) {
          final json = {
            'id': 'id-1',
            'type': type,
            'delta_points': -75,
            'occurred_at': '2024-01-15T10:30:00.000Z',
            'origin': 'reversal',
            'reference_id': 'ref-1',
            'balance_after': 1325,
          };
          expect(Movement.fromJson(json).type, type);
        }
        final _ = dateTime;
      });

      test('Movement equality', () {
        final dateTime = DateTime.parse('2024-01-15T10:30:00.000Z');
        Movement build(String id) => Movement(
          id: id,
          type: 'CREDIT',
          deltaPoints: 100,
          occurredAt: dateTime,
          origin: 'purchase',
          referenceId: 'REF-001',
          balanceAfter: 1000,
        );

        expect(build('a'), equals(build('a')));
        expect(build('a'), isNot(equals(build('b'))));
        expect(build('a').hashCode, equals(build('a').hashCode));
      });
    },
  );
}
