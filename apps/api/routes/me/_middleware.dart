import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/adapters/in/middleware/authz.dart';

Handler middleware(Handler handler) {
  // Solo los clientes con telefono verificado pueden consultar su saldo y movimientos (spec T013)
  return handler.use(customerAuth(requirePhoneVerified: true));
}
