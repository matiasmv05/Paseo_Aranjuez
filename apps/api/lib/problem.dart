import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

/// Construye una respuesta de error RFC 9457 (`application/problem+json`)
/// con un `code` estable para el cliente (AGENTS.md §9).
Response problemJson({
  required int status,
  required String title,
  required String code,
  String? detail,
  String? correlationId,
  Map<String, Object?> extra = const {},
}) {
  final body = <String, Object?>{
    'type': 'about:blank',
    'title': title,
    'status': status,
    'code': code,
    'detail': ?detail,
    'correlation_id': ?correlationId,
    ...extra,
  };
  return Response(
    statusCode: status,
    body: jsonEncode(body),
    headers: const {'content-type': 'application/problem+json; charset=utf-8'},
  );
}
