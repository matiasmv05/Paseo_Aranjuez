import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/adapters/in/errors.dart';
import 'package:paseo_api/adapters/in/merchant_use_cases.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/problem.dart';

/// T077: `GET /merchant/movements` (HU-13). Paginacion por cursor; valida
/// `limit` y delega en `listMovements`.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return problemJson(
      status: HttpStatus.methodNotAllowed,
      title: 'Method Not Allowed',
      code: 'METHOD_NOT_ALLOWED',
    );
  }
  final params = context.request.uri.queryParameters;
  final rawLimit = params['limit'];
  int? limit;
  if (rawLimit != null) {
    limit = int.tryParse(rawLimit);
    if (limit == null) {
      return problemJson(
        status: HttpStatus.unprocessableEntity,
        title: 'Unprocessable Entity',
        code: 'VALIDATION_FAILED',
        detail: 'limit debe ser un entero.',
      );
    }
  }
  try {
    final merchant = context.read<MerchantContext>();
    final deps = await context.read<Future<MerchantDependencies>>();
    final page = await deps.listMovements(
      context: merchant,
      limit: limit,
      cursor: params['cursor'],
    );
    return Response.json(body: page.toJson());
  } on Object catch (e) {
    return mapLoyaltyError(e) ??
        problemJson(
          status: HttpStatus.internalServerError,
          title: 'Internal Server Error',
          code: 'INTERNAL_ERROR',
        );
  }
}
