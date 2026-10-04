import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/adapters/in/di.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:paseo_shared/paseo_shared.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final claims = context.read<AuthClaims>();
  if (claims.customerId == null) {
    return Response(statusCode: HttpStatus.forbidden);
  }

  final params = context.request.uri.queryParameters;
  final limit = params['limit'] != null ? int.tryParse(params['limit']!) : null;
  final cursor = params['cursor'];

  try {
    final deps = await context.read<Future<AppDependencies>>();
    final page = await deps.getMovements.call(
      customerId: claims.customerId!,
      cursor: cursor,
      limit: limit,
    );

    return Response.json(
      body: {
        'items': page.items
            .map(
              (m) => Movement(
                id: m.id,
                type: m.type.name.toUpperCase(),
                deltaPoints: m.deltaPoints,
                occurredAt: m.occurredAt,
                origin: m.origin,
                referenceId: m.referenceId,
                balanceAfter: m.balanceAfter,
              ).toJson(),
            )
            .toList(),
        'next_cursor': page.nextCursor,
      },
    );
  } on FormatException {
    return Response.json(
      statusCode: HttpStatus.unprocessableEntity,
      body: {
        'type': 'about:blank',
        'title': 'Unprocessable Entity',
        'status': HttpStatus.unprocessableEntity,
        'code': 'VALIDATION_FAILED',
      },
    );
  }
}
