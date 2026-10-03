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
      detail: 'X-Paseo-Client requerido',
    );
  }
  if (client.isWeb) {
    final origin = context.request.headers['Origin'];
    final allowed = switch (client) {
      ClientApp.webMerchant => [
        _const('WEB_MERCHANT_ORIGIN', 'https://localhost'),
      ],
      ClientApp.webAdmin => [
        _const('WEB_ADMIN_ORIGIN', 'https://localhost:8443'),
      ],
      _ => <String>[],
    };
    if (origin == null || !allowed.contains(origin)) {
      return problemJson(
        status: HttpStatus.forbidden,
        title: 'Forbidden',
        code: 'FORBIDDEN',
        detail: 'Origin no permitido',
      );
    }
  }
  String? refreshToken;
  final body = await readJson(context);
  if (body != null) {
    refreshToken = body['refresh_token'] as String?;
  }
  if (refreshToken == null) {
    final cookieName = client.refreshCookieName;
    if (cookieName != null) {
      final cookies = context.request.headers['Cookie'] ?? '';
      for (final part in cookies.split(';')) {
        final kv = part.trim().split('=');
        if (kv.length == 2 && kv[0] == cookieName) refreshToken = kv[1];
      }
    }
  }
  if (refreshToken == null) {
    return problemJson(
      status: HttpStatus.unauthorized,
      title: 'Unauthorized',
      code: 'UNAUTHENTICATED',
      detail: 'refresh token ausente',
    );
  }
  try {
    final useCases = await context.read<Future<AuthUseCases>>();
    final session = await useCases.refreshSession.call(
      refreshToken: refreshToken,
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

String _const(String key, String fallback) =>
    Platform.environment[key]?.isEmpty ?? true
    ? fallback
    : Platform.environment[key]!;
