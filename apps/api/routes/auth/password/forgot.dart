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
    );
  }
  try {
    final dto = ForgotPasswordRequest.fromJson(body);
    final useCases = await context.read<Future<AuthUseCases>>();
    await useCases.forgotPassword.call(email: dto.email);
    return Response.json(
      statusCode: HttpStatus.accepted,
      body: const {'status': 'accepted'},
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
