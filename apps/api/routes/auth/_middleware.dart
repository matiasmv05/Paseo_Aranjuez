import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/adapters/in/auth_use_cases.dart';
import 'package:paseo_api/adapters/in/di.dart';
import 'package:paseo_api/adapters/in/middleware/rate_limit_middleware.dart';

/// Rutas de auth: rate limit + wiring de casos de uso.
/// Cambiar JWT_SECRET en .env (nunca commitear).
Handler middleware(Handler handler) {
  return handler
      .use(provider<Future<AuthUseCases>>((_) => AppDependencies.open()))
      .use(rateLimiter());
}
