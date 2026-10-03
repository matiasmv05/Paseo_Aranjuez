import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/problem.dart';

/// GET /ready → 200 `{"status":"ready"}` si la comprobación de BD pasa;
/// 503 `application/problem+json` (`code: SERVICE_UNAVAILABLE`) si no.
///
/// El check se inyecta vía `provider<Future<bool> Function()>`
/// (ver `routes/_middleware.dart`). T030/T033 lo conectarán con el
/// adapter real de PostgreSQL; por ahora es una implementación trivial
/// que devuelve `true`.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return problemJson(
      status: HttpStatus.methodNotAllowed,
      title: 'Method Not Allowed',
      code: 'METHOD_NOT_ALLOWED',
    );
  }
  final check = context.read<Future<bool> Function()>();
  final ready = await check();
  if (!ready) {
    return problemJson(
      status: HttpStatus.serviceUnavailable,
      title: 'Service Unavailable',
      code: 'SERVICE_UNAVAILABLE',
      detail: 'Database check failed.',
    );
  }
  return Response.json(body: const {'status': 'ready'});
}
