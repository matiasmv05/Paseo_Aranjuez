import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/adapters/in/auth_use_cases.dart';
import 'package:paseo_api/adapters/in/errors.dart';
import 'package:paseo_api/domain/identity/client_app.dart';
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
  final client = ClientApp.fromHeader(
    context.request.headers['X-Paseo-Client'],
  );
  if (client == null) {
    return problemJson(
      status: HttpStatus.unauthorized,
      title: 'Unauthorized',
      code: 'UNAUTHENTICATED',
      detail: 'X-Paseo-Client invalido',
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
    final dto = LoginRequest.fromJson(body);
    final useCases = await context.read<Future<AuthUseCases>>();
    final session = await useCases.login.call(
      email: dto.email,
      password: dto.password,
      client: client,
    );
    final response = Response.json(
      body: TokenResponse(
        accessToken: session.accessToken,
        tokenType: 'Bearer',
        expiresIn: session.expiresIn,
        refreshToken: client.isWeb ? null : session.refreshToken,
      ).toJson(),
    );
    final cookieName = client.refreshCookieName;
    if (cookieName != null) {
      final cookie =
          '$cookieName=${session.refreshToken}; HttpOnly; Secure; SameSite=Strict; Path=/api/v1/auth; Max-Age=${30 * 24 * 3600}';
      return response.copyWith(
        headers: {...response.headers, 'Set-Cookie': cookie},
      );
    }
    return response;
  } on Object catch (e) {
    return mapIdentityError(e) ??
        problemJson(
          status: HttpStatus.internalServerError,
          title: 'Internal Server Error',
          code: 'INTERNAL_ERROR',
        );
  }
}
