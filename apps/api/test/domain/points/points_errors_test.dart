import 'package:paseo_api/domain/points/points.dart';
import 'package:paseo_shared/paseo_shared.dart';
import 'package:test/test.dart';

void main() {
  group('PointsException', () {
    test(
      'insufficientPoints usa el codigo del contrato INSUFFICIENT_POINTS',
      () {
        final error = PointsException.insufficientPoints();

        expect(error.code, equals(ApiErrorCode.insufficientPoints));
        expect(error.code.wire, equals('INSUFFICIENT_POINTS'));
        expect(error.toString(), contains('INSUFFICIENT_POINTS'));
        expect(error.message, contains('saldo insuficiente'));
      },
    );

    test(
      'conflict (p. ej. idempotencia) usa el codigo del contrato CONFLICT',
      () {
        final error = PointsException.conflict(
          'clave de idempotencia en conflicto',
        );

        expect(error.code, equals(ApiErrorCode.conflict));
        expect(error.code.wire, equals('CONFLICT'));
        expect(error.message, equals('clave de idempotencia en conflicto'));
        expect(error.toString(), contains('CONFLICT'));
      },
    );

    test('phoneNotVerified usa el codigo del contrato PHONE_NOT_VERIFIED', () {
      final error = PointsException.phoneNotVerified();

      expect(error.code, equals(ApiErrorCode.phoneNotVerified));
      expect(error.code.wire, equals('PHONE_NOT_VERIFIED'));
    });
  });
}
