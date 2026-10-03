import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/problem.dart';

/// GET /health → 200 `{"status":"ok"}`.
Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return problemJson(
      status: HttpStatus.methodNotAllowed,
      title: 'Method Not Allowed',
      code: 'METHOD_NOT_ALLOWED',
    );
  }
  return Response.json(body: const {'status': 'ok'});
}
