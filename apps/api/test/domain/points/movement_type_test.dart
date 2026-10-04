import 'package:paseo_api/domain/points/points.dart';
import 'package:test/test.dart';

void main() {
  group('MovementType', () {
    test('contiene exactamente 5 tipos según especificación', () {
      const types = MovementType.values;
      expect(types.length, equals(5));
      expect(types.contains(MovementType.credit), isTrue);
      expect(types.contains(MovementType.redeem), isTrue);
      expect(types.contains(MovementType.adjust), isTrue);
      expect(types.contains(MovementType.bonus), isTrue);
      expect(types.contains(MovementType.reversal), isTrue);
    });

    test('serialización a string mantiene nombres exactos', () {
      expect(MovementType.credit.name, equals('credit'));
      expect(MovementType.redeem.name, equals('redeem'));
      expect(MovementType.adjust.name, equals('adjust'));
      expect(MovementType.bonus.name, equals('bonus'));
      expect(MovementType.reversal.name, equals('reversal'));
    });

    test('deserialización desde string funciona correctamente', () {
      expect(MovementType.values.byName('credit'), equals(MovementType.credit));
      expect(MovementType.values.byName('redeem'), equals(MovementType.redeem));
      expect(MovementType.values.byName('adjust'), equals(MovementType.adjust));
      expect(MovementType.values.byName('bonus'), equals(MovementType.bonus));
      expect(
        MovementType.values.byName('reversal'),
        equals(MovementType.reversal),
      );
    });

    test('deserialización con string inválido lanza ArgumentError', () {
      expect(
        () => MovementType.values.byName('invalid'),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => MovementType.values.byName('CREDIT'),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => MovementType.values.byName(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toString devuelve el nombre del tipo', () {
      expect(MovementType.credit.toString(), contains('credit'));
      expect(MovementType.redeem.toString(), contains('redeem'));
      expect(MovementType.adjust.toString(), contains('adjust'));
      expect(MovementType.bonus.toString(), contains('bonus'));
      expect(MovementType.reversal.toString(), contains('reversal'));
    });

    test('index asignado correctamente', () {
      expect(MovementType.credit.index, equals(0));
      expect(MovementType.redeem.index, equals(1));
      expect(MovementType.adjust.index, equals(2));
      expect(MovementType.bonus.index, equals(3));
      expect(MovementType.reversal.index, equals(4));
    });

    test('wire: valor exacto de points_ledger.type (MAYUSCULAS)', () {
      expect(MovementType.credit.wire, 'CREDIT');
      expect(MovementType.redeem.wire, 'REDEEM');
      expect(MovementType.adjust.wire, 'ADJUST');
      expect(MovementType.bonus.wire, 'BONUS');
      expect(MovementType.reversal.wire, 'REVERSAL');
    });

    test('parseWire: round-trip desde el valor del ledger', () {
      for (final t in MovementType.values) {
        expect(MovementType.parseWire(t.wire), t);
      }
      expect(
        () => MovementType.parseWire('OTRO'),
        throwsA(isA<FormatException>()),
      );
    });

    test('origin: mapeo del contrato Movement.origin (HU-05)', () {
      expect(MovementType.credit.origin, 'purchase');
      expect(MovementType.redeem.origin, 'redemption');
      expect(MovementType.adjust.origin, 'adjustment');
      expect(MovementType.bonus.origin, 'adjustment');
      expect(MovementType.reversal.origin, 'reversal');
    });
  });
}
