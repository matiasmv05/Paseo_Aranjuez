import 'package:paseo_api/domain/identity/identity.dart';
import 'package:paseo_shared/paseo_shared.dart';
import 'package:test/test.dart';

void main() {
  group('PhoneBO.parse (FR-002, regex laxa)', () {
    final validos = ['+59160000000', '+59179991234', '+59112345678'];
    for (final v in validos) {
      test('acepta $v', () {
        expect(PhoneBO.parse(v).value, v);
      });
    }
    test('acepta con espacios alrededor (trim)', () {
      expect(PhoneBO.parse('  +59160000000 ').value, '+59160000000');
    });

    // (entrada, codigo esperado)
    final invalidos = <(String, ApiErrorCode)>[
      ('+34600000000', ApiErrorCode.phoneNotSupported), // otro prefijo
      ('60000000', ApiErrorCode.phoneNotSupported), // sin +591
      ('+5916000000', ApiErrorCode.validationFailed), // 7 digitos
      ('+591600000000', ApiErrorCode.validationFailed), // 9 digitos
      ('+5916000000a', ApiErrorCode.validationFailed), // no numerico
      ('+591 60000000', ApiErrorCode.validationFailed), // espacio interno
    ];
    for (final (input, code) in invalidos) {
      test('rechaza "$input" con ${code.wire}', () {
        expect(
          () => PhoneBO.parse(input),
          throwsA(isA<IdentityException>().having((e) => e.code, 'code', code)),
        );
      });
    }

    test('igualdad por valor', () {
      expect(PhoneBO.parse('+59160000000'), PhoneBO.parse('+59160000000'));
      expect(
        PhoneBO.parse('+59160000000'),
        isNot(PhoneBO.parse('+59160000001')),
      );
    });
  });
}
