import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/adapters/in/errors.dart';
import 'package:paseo_api/adapters/in/merchant_use_cases.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/application/merchant/use_cases/identify_customer.dart';
import 'package:paseo_api/problem.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;

/// T074: `POST /merchant/customers/identify` (HU-10). Ruta fina: valida el
/// cuerpo, delega en `identifyCustomer` y mapea errores a RFC 9457.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return problemJson(
      status: HttpStatus.methodNotAllowed,
      title: 'Method Not Allowed',
      code: 'METHOD_NOT_ALLOWED',
    );
  }
  final body = await readJson(context);
  if (body == null) {
    return problemJson(
      status: HttpStatus.unprocessableEntity,
      title: 'Unprocessable Entity',
      code: 'VALIDATION_FAILED',
    );
  }
  try {
    final request = contract.IdentifyRequest.fromJson(body);
    final merchant = context.read<MerchantContext>();
    final deps = await context.read<Future<MerchantDependencies>>();
    final input = switch (request) {
      contract.IdentifyByPhoneRequest(:final phone) => IdentifyByPhone(phone),
      contract.IdentifyByQrRequest(:final qrToken) => IdentifyByQr(qrToken),
    };
    final result = await deps.identifyCustomer(context: merchant, input: input);
    return Response.json(body: result.toJson());
  } on Object catch (e) {
    return mapLoyaltyError(e) ??
        problemJson(
          status: HttpStatus.internalServerError,
          title: 'Internal Server Error',
          code: 'INTERNAL_ERROR',
        );
  }
}
