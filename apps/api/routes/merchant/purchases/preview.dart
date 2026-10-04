import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/adapters/in/errors.dart';
import 'package:paseo_api/adapters/in/merchant_use_cases.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/problem.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;

/// T075: `POST /merchant/purchases/preview` (US3). No escribe nada; aplica el
/// rate limit por comercio antes de calcular los puntos.
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
    final request = contract.PreviewPurchaseRequest.fromJson(body);
    final merchant = context.read<MerchantContext>();
    final deps = await context.read<Future<MerchantDependencies>>();
    final allowed = await deps.rateLimiter.tryAcquire(
      establishmentId: merchant.establishmentId,
      action: MerchantAction.preview,
    );
    if (!allowed) {
      return problemJson(
        status: HttpStatus.tooManyRequests,
        title: 'Too Many Requests',
        code: 'RATE_LIMITED',
        detail: 'Rate limit exceeded. Retry later.',
      );
    }
    final result = await deps.previewPurchase(
      context: merchant,
      request: request,
    );
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
