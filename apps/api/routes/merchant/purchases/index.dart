import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/adapters/in/errors.dart';
import 'package:paseo_api/adapters/in/merchant_use_cases.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/problem.dart';
import 'package:paseo_shared/paseo_shared.dart' as contract;

/// T076: `POST /merchant/purchases` (HU-11). Exige `Idempotency-Key`, aplica
/// rate limit y devuelve 201 en la creacion o 200 en el reintento.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return problemJson(
      status: HttpStatus.methodNotAllowed,
      title: 'Method Not Allowed',
      code: 'METHOD_NOT_ALLOWED',
    );
  }
  final idempotencyKey = context.request.headers['idempotency-key'];
  if (idempotencyKey == null || idempotencyKey.trim().isEmpty) {
    return problemJson(
      status: HttpStatus.unprocessableEntity,
      title: 'Unprocessable Entity',
      code: 'VALIDATION_FAILED',
      detail: 'Falta el encabezado Idempotency-Key.',
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
    final request = contract.RegisterPurchaseRequest.fromJson(body);
    final merchant = context.read<MerchantContext>();
    final deps = await context.read<Future<MerchantDependencies>>();
    final allowed = await deps.rateLimiter.tryAcquire(
      establishmentId: merchant.establishmentId,
      action: MerchantAction.registerPurchase,
    );
    if (!allowed) {
      return problemJson(
        status: HttpStatus.tooManyRequests,
        title: 'Too Many Requests',
        code: 'RATE_LIMITED',
        detail: 'Rate limit exceeded. Retry later.',
      );
    }
    final outcome = await deps.registerPurchase(
      context: merchant,
      request: request,
      idempotencyKey: idempotencyKey,
    );
    return Response.json(
      statusCode: outcome.created ? HttpStatus.created : HttpStatus.ok,
      body: outcome.purchase.toJson(),
    );
  } on Object catch (e) {
    return mapLoyaltyError(e) ??
        problemJson(
          status: HttpStatus.internalServerError,
          title: 'Internal Server Error',
          code: 'INTERNAL_ERROR',
        );
  }
}
