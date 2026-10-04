import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/adapters/in/customer_qr.dart';
import 'package:paseo_api/adapters/in/di.dart';
import 'package:paseo_api/application/customer/issue_customer_qr_ticket.dart';

/// Rutas del cliente autenticado (`/customers/*`):
/// wiring del emisor de tickets QR con los singleton de [AppDependencies].
Handler middleware(Handler handler) {
  return handler.use(
    provider<Future<QrTicketIssuer>>((_) async {
      final deps = await AppDependencies.open();
      final issueQr = IssueCustomerQrTicket(
        verifier: deps.verifier,
        signer: deps.signer,
        clock: deps.clock,
        ids: deps.ids,
      );
      return ({String? authorizationHeader}) =>
          issueQr(authorizationHeader: authorizationHeader);
    }),
  );
}
