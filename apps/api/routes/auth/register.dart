import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/adapters/in/auth_use_cases.dart';
import 'package:paseo_api/adapters/in/errors.dart';
import 'package:paseo_api/problem.dart';
import 'package:paseo_shared/paseo_shared.dart';

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
      detail: 'JSON requerido',
    );
  }
  try {
    final dto = RegisterRequest.fromJson(body);
    final useCases = await context.read<Future<AuthUseCases>>();
    final customerId = await useCases.registerCustomer.call(
      email: dto.email,
      phone: dto.phone,
      password: dto.password,
      fullName: dto.fullName,
    );
    return Response.json(
      statusCode: HttpStatus.created,
      body: RegisterResponse(
        customerId: customerId,
        phoneVerified: false,
        emailVerificationSent: true,
      ).toJson(),
    );
  } on Object catch (e) {
    return mapIdentityError(e) ??
        problemJson(
          status: HttpStatus.internalServerError,
          title: 'Internal Server Error',
          code: 'INTERNAL_ERROR',
        );
  }
}
