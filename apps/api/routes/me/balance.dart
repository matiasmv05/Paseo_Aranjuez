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

  final deps = await context.read<Future<AppDependencies>>();

  final result = await deps.getBalance.call(customerId: claims.customerId!);

  return Response.json(
    body: Balance(
      balancePoints: result.balance,
      updatedAt: result.updatedAt ?? DateTime.now().toUtc(),
    ).toJson(),
  );
}
