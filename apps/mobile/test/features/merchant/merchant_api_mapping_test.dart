import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paseo_mobile/features/merchant/data/merchant_api_client.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;

void main() {
  group('describeMerchantError', () {
    MerchantApiException errorFor(contract.ApiErrorCode code) =>
        MerchantApiException(statusCode: 422, code: code);

    test('traduce los codes del panel del comercio a texto visible', () {
      expect(
        describeMerchantError(
          errorFor(contract.ApiErrorCode.phoneNotSupported),
        ),
        'Solo se aceptan telefonos bolivianos (+591).',
      );
      expect(
        describeMerchantError(errorFor(contract.ApiErrorCode.customerNotFound)),
        'No hay un cliente registrado con ese dato.',
      );
      expect(
        describeMerchantError(
          errorFor(contract.ApiErrorCode.invalidIdentificationTicket),
        ),
        'La identificacion vencio. Vuelve a identificar al cliente.',
      );
      expect(
        describeMerchantError(errorFor(contract.ApiErrorCode.duplicateInvoice)),
        'Ese numero de factura ya fue registrado en el comercio.',
      );
      expect(
        describeMerchantError(errorFor(contract.ApiErrorCode.noApplicableRule)),
        'No hay una regla de puntos aplicable a esta compra.',
      );
      expect(
        describeMerchantError(errorFor(contract.ApiErrorCode.rateLimited)),
        'Demasiadas solicitudes. Espera un momento e intenta de nuevo.',
      );
    });

    test('cae a un mensaje generico cuando el code falta', () {
      expect(
        describeMerchantError(
          const MerchantApiException(statusCode: 500, code: null),
        ),
        'No se pudo completar la operacion.',
      );
    });
  });

  group('MerchantApiClient', () {
    test('convierte un problem+json en MerchantApiException', () async {
      final client = MerchantApiClient(
        baseUrl: Uri.parse('http://test.local/api/v1/'),
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'type': 'about:blank',
              'title': 'No encontrado',
              'status': 404,
              'code': 'CUSTOMER_NOT_FOUND',
              'detail': 'sin cliente',
              'correlation_id': 'abc-123',
            }),
            404,
            headers: {'content-type': 'application/problem+json'},
          ),
        ),
      );

      await expectLater(
        client.identify(
          const contract.IdentifyByPhoneRequest(phone: '+59170000001'),
        ),
        throwsA(
          isA<MerchantApiException>()
              .having((error) => error.statusCode, 'statusCode', 404)
              .having(
                (error) => error.code,
                'code',
                contract.ApiErrorCode.customerNotFound,
              )
              .having((error) => error.detail, 'detail', 'sin cliente')
              .having(
                (error) => error.correlationId,
                'correlationId',
                'abc-123',
              ),
        ),
      );
    });

    test('un error sin Problem deja el code en null', () async {
      final client = MerchantApiClient(
        baseUrl: Uri.parse('http://test.local/api/v1/'),
        httpClient: MockClient(
          (request) async => http.Response('<html>500</html>', 500),
        ),
      );

      await expectLater(
        client.movements(),
        throwsA(
          isA<MerchantApiException>().having(
            (error) => error.code,
            'code',
            isNull,
          ),
        ),
      );
    });
  });
}
