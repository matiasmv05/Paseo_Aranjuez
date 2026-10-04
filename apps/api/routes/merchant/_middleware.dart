import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/adapters/in/di.dart';
import 'package:paseo_api/adapters/in/merchant_use_cases.dart';
import 'package:paseo_api/adapters/in/middleware/merchant_auth_middleware.dart';

/// Rutas del panel del comercio (T073): wiring de dependencias + autenticacion
/// de personal (audiencia, rol, estado y telefono verificado leidos de BD).
///
/// El logging global ya no incluye PII: solo metodo, ruta, estado y
/// `correlation_id` (AGENTS.md §8/§9).
Handler middleware(Handler handler) {
  return handler
      .use(
        provider<Future<MerchantDependencies>>(
          (_) => AppDependencies.open().then((deps) => deps.merchant),
        ),
      )
      .use(merchantAuth());
}
