import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/problem.dart';
import 'package:uuid/uuid.dart';

/// Middleware global (AGENTS.md §3/§9):
///
/// - Inyecta el readiness check vía `provider<Future<bool> Function()>`.
///   Implementación trivial que devuelve `true`; el wiring real contra
///   PostgreSQL llega en T030/T033 (adapters/out).
/// - Asigna un `x-correlation-id` por petición (uuid si falta) y lo
///   devuelve en la respuesta.
/// - Captura cualquier excepción no controlada →
///   500 `application/problem+json` con `code` estable.
/// - Log estructurado JSON a stdout SIN datos sensibles
///   (solo método, ruta, estado, duración y correlation id).
Handler middleware(Handler handler) {
  const uuid = Uuid();
  return handler
      .use(
        provider<Future<bool> Function()>(
          (_) =>
              () async => true,
        ),
      )
      .use(_correlationAndErrors(uuid));
}

Middleware _correlationAndErrors(Uuid uuid) {
  return (handler) {
    return (context) async {
      final request = context.request;
      final correlationId = request.headers['x-correlation-id'] ?? uuid.v4();
      final stopwatch = Stopwatch()..start();
      Response response;
      try {
        response = await handler(context);
        // Intencionalmente amplio (on Object): el middleware global debe
        // capturar cualquier error no controlado y responder problem+json.
      } on Object catch (_) {
        response = problemJson(
          status: HttpStatus.internalServerError,
          title: 'Internal Server Error',
          code: 'INTERNAL_ERROR',
          detail: 'Unexpected server error.',
          correlationId: correlationId,
        );
      }
      stopwatch.stop();
      stdout.writeln(
        jsonEncode(<String, Object?>{
          'ts': DateTime.now().toUtc().toIso8601String(),
          'correlation_id': correlationId,
          'method': request.method.name,
          'path': request.uri.path,
          'status': response.statusCode,
          'duration_ms': stopwatch.elapsedMilliseconds,
        }),
      );
      return response.copyWith(
        headers: {...response.headers, 'x-correlation-id': correlationId},
      );
    };
  };
}
