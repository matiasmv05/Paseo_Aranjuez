import 'package:flutter_test/flutter_test.dart';
import 'package:paseo_mobile/core/format.dart';

void main() {
  group('formatPoints', () {
    test('sin separador bajo mil y con separador de miles', () {
      expect(formatPoints(0), '0');
      expect(formatPoints(999), '999');
      expect(formatPoints(1250), '1.250');
      expect(formatPoints(1234567), '1.234.567');
    });

    test('negativos conservan el signo', () {
      expect(formatPoints(-500), '-500');
    });
  });

  group('formatSignedPoints', () {
    test('signo explícito en positivos y negativos', () {
      expect(formatSignedPoints(50), '+50');
      expect(formatSignedPoints(-50), '-50');
      expect(formatSignedPoints(0), '+0');
    });
  });

  group('formatDateTime / formatDate', () {
    test('formatea fecha y hora locales', () {
      final utc = DateTime.utc(2026, 1, 7, 15, 4);
      expect(formatDate(utc), contains('/01/2026'));
      expect(formatDateTime(utc), contains('/01/2026'));
      expect(formatDateTime(utc), contains(':'));
    });
  });
}
