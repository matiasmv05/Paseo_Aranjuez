import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/adapters/in/di.dart';
import 'package:paseo_api/adapters/in/middleware/authz.dart';
import 'package:paseo_shared/paseo_shared.dart';

Future<Response> onRequest(RequestContext context) async {
  return await customerAuth()((ctx) async {
    if (ctx.request.method != HttpMethod.get) {
      return Response(statusCode: HttpStatus.methodNotAllowed);
    }

    final deps = await ctx.read<Future<AppDependencies>>();
    final establishments = await deps.listEstablishments.call();

    return Response.json(
      body: establishments
          .map(
            (e) => EstablishmentSummary(
              id: e.id,
              name: e.name,
              category: e.category,
              branches: e.branches
                  .map(
                    (b) => BranchSummary(
                      id: b.id,
                      name: b.name,
                      address: b.address,
                    ),
                  )
                  .toList(),
            ).toJson(),
          )
          .toList(),
    );
  })(context);
}
