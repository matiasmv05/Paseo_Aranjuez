import 'package:paseo_api/domain/points/points.dart';
import 'package:test/test.dart';

void main() {
  group('CreditCommand', () {
    test('válido con puntos > 0 y reference presente', () {
      expect(
        () => CreditCommand(points: 100, reference: 'purchase-123'),
        returnsNormally,
      );

      expect(
        () => CreditCommand(points: 1, reference: 'min-valid'),
        returnsNormally,
      );
    });

    test('puntos <= 0 lanza ArgumentError', () {
      expect(
        () => CreditCommand(points: 0, reference: 'purchase-123'),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => CreditCommand(points: -1, reference: 'purchase-123'),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => CreditCommand(points: -100, reference: 'purchase-123'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('reference vacía o null lanza ArgumentError', () {
      expect(
        () => CreditCommand(points: 100, reference: ''),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => CreditCommand(points: 100, reference: '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('properties son accesibles', () {
      final command = CreditCommand(points: 250, reference: 'purchase-456');

      expect(command.points, equals(250));
      expect(command.reference, equals('purchase-456'));
    });

    test('equality basada en points y reference', () {
      final command1 = CreditCommand(points: 100, reference: 'ref-1');
      final command2 = CreditCommand(points: 100, reference: 'ref-1');
      final command3 = CreditCommand(points: 200, reference: 'ref-1');
      final command4 = CreditCommand(points: 100, reference: 'ref-2');

      expect(command1, equals(command2));
      expect(command1.hashCode, equals(command2.hashCode));
      expect(command1, isNot(equals(command3)));
      expect(command1, isNot(equals(command4)));
    });
  });
}
