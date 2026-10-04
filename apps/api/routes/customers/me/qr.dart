import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/adapters/in/customer_qr.dart';
import 'package:paseo_api/adapters/in/errors.dart';
import 'package:paseo_api/problem.dart';
import 'package:paseo_api/application/customer/issue_customer_qr_ticket.dart';

/// GET /customers/me/qr: ticket QR firmado (≤ 5 min) para el cliente
/// autenticado. Sin datos personales en el ticket (AGENTS.md §8).
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return problemJson(
      status: HttpStatus.methodNotAllowed,
      title: 'Method Not Allowed',
      code: 'METHOD_NOT_ALLOWED',
    );
  }
  try {
    final issueQr = await context.read<Future<QrTicketIssuer>>();
    final ticket = await issueQr(
      authorizationHeader: context.request.headers['authorization'],
    );
    return Response.json(
      body: <String, Object?>{
        'qr_ticket': ticket,
        'expires_in': IssueCustomerQrTicket.lifetimeSeconds,
      },
    );
  } on Object catch (e) {
    return mapIdentityError(e) ??
        problemJson(
          status: HttpStatus.internalServerError,
          title: 'Internal Server Error',
          code: 'INTERNAL_ERROR',
        );
  }
}
