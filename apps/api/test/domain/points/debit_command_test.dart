import 'package:paseo_api/domain/points/points.dart';
import 'package:test/test.dart';

void main() {
  group('DebitCommand', () {
    test('válido con puntos > 0 y reference presente', () {
      expect(
        () => DebitCommand(points: 50, reference: 'redeem-789'),
        returnsNormally,
      );

      expect(
        () => DebitCommand(points: 1, reference: 'min-valid'),
        returnsNormally,
      );
    });

    test('puntos <= 0 lanza ArgumentError', () {
      expect(
        () => DebitCommand(points: 0, reference: 'redeem-789'),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => DebitCommand(points: -1, reference: 'redeem-789'),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => DebitCommand(points: -50, reference: 'redeem-789'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('reference vacía o null lanza ArgumentError', () {
      expect(
        () => DebitCommand(points: 50, reference: ''),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => DebitCommand(points: 50, reference: '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('properties son accesibles', () {
      final command = DebitCommand(points: 75, reference: 'redeem-abc');

      expect(command.points, equals(75));
      expect(command.reference, equals('redeem-abc'));
    });

    test('equality basada en points y reference', () {
      final command1 = DebitCommand(points: 50, reference: 'ref-1');
      final command2 = DebitCommand(points: 50, reference: 'ref-1');
      final command3 = DebitCommand(points: 100, reference: 'ref-1');
      final command4 = DebitCommand(points: 50, reference: 'ref-2');

      expect(command1, equals(command2));
      expect(command1.hashCode, equals(command2.hashCode));
      expect(command1, isNot(equals(command3)));
      expect(command1, isNot(equals(command4)));
    });
  });
}
