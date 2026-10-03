import 'package:paseo_api/domain/identity/identity.dart';
import 'package:paseo_shared/paseo_shared.dart';
import 'package:test/test.dart';

void main() {
  group('Email', () {
    test('normaliza a minusculas y trim', () {
      expect(Email.parse('  Ana@Example.COM ').value, 'ana@example.com');
    });
    final invalidos = ['', 'sin-arroba', 'a@b', '@b.com', 'a b@c.com'];
    for (final v in invalidos) {
      test('rechaza "$v" con VALIDATION_FAILED', () {
        expect(
          () => Email.parse(v),
          throwsA(
            isA<IdentityException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.validationFailed,
            ),
          ),
        );
      });
    }
  });

  group('PasswordPolicy', () {
    test('menor a 8 -> VALIDATION_FAILED', () {
      expect(
        () => PasswordPolicy.validate('corta1'),
        throwsA(isA<IdentityException>()),
      );
    });
    test('8 o mas -> ok', () {
      expect(
        () => PasswordPolicy.validate('larga-suficiente'),
        returnsNormally,
      );
    });
  });
}
