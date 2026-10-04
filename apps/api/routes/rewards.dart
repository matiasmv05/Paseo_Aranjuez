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
    final rewards = await deps.listRewards.call();

    return Response.json(
      body: rewards
          .map(
            (r) => RewardSummary(
              id: r.id,
              name: r.name,
              description: r.description,
              rewardType: r.rewardType,
              costPoints: r.costPoints,
              available: r.available,
              establishmentId: r.establishmentId,
              stock: r.stock,
              validFrom: r.validFrom,
              validTo: r.validTo,
            ).toJson(),
          )
          .toList(),
    );
  })(context);
}
