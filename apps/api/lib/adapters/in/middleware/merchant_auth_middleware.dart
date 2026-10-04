import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/adapters/in/merchant_use_cases.dart';
import 'package:paseo_api/application/merchant/ports.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:paseo_api/problem.dart';

/// Autentica al personal del comercio y provee un [MerchantContext] (T070, §6).
///
/// Exige `aud = paseo-web-merchant` y `role` en {`merchant_owner`,
/// `merchant_cashier`}. Como los claims pueden tener hasta 15 min de desfase,
/// relee `users.status` y `users.token_version` en la base; el `est`/`br`
/// verificados se contrastan con `establishment_staff`. Cualquier rol que no
/// sea de comercio se rechaza con 403 (FR-024).
Middleware merchantAuth() {
  return (handler) {
    return (context) async {
      final deps = await context.read<Future<MerchantDependencies>>();

      final token = _bearer(context.request.headers['authorization']);
      if (token == null) return _unauthorized();

      final claims = deps.verifier.verify(token, now: deps.clock.nowUtc());
      if (claims == null || claims.audience != ClientApp.webMerchant.audience) {
        return _unauthorized();
      }

      final role = _merchantRole(claims.role);
      final establishmentId = claims.establishmentId;
      if (role == null || establishmentId == null) return _forbidden();

      // Claims con hasta 15 min de desfase: revalidar contra la base (§6).
      final user = await deps.users.findById(claims.subject);
      if (user == null ||
          user.status != UserStatus.active ||
          user.tokenVersion != claims.tokenVersion) {
        return _unauthorized();
      }
      if (!user.phoneVerified) return _phoneNotVerified();

      // El comercio/sucursal del claim deben coincidir con la pertenencia
      // vigente en la base (evita tokens de un comercio ajeno, regla 2.7).
      final matched = await deps.establishments.findContext(claims.subject);
      if (matched == null ||
          matched.establishmentId != establishmentId ||
          matched.role != role) {
        return _forbidden();
      }
      final branchId = claims.branchId ?? matched.branchId;
      if (role == MerchantRole.cashier && branchId == null) return _forbidden();

      final resolved = MerchantContext(
        establishmentId: establishmentId,
        establishmentName: matched.establishmentName,
        userId: claims.subject,
        role: role,
        branchId: branchId,
        branchName: matched.branchName,
      );
      return handler(context.provide<MerchantContext>(() => resolved));
    };
  };
}

String? _bearer(String? header) {
  if (header == null) return null;
  final parts = header.split(' ');
  if (parts.length != 2 || parts[0].toLowerCase() != 'bearer') return null;
  final token = parts[1].trim();
  return token.isEmpty ? null : token;
}

MerchantRole? _merchantRole(UserRole role) => switch (role) {
  UserRole.merchantOwner => MerchantRole.owner,
  UserRole.merchantCashier => MerchantRole.cashier,
  UserRole.customer || UserRole.admin => null,
};

Response _unauthorized() => problemJson(
  status: HttpStatus.unauthorized,
  title: 'Sin sesion',
  code: 'UNAUTHENTICATED',
);

Response _forbidden() => problemJson(
  status: HttpStatus.forbidden,
  title: 'Sin permiso',
  code: 'FORBIDDEN',
);

Response _phoneNotVerified() => problemJson(
  status: HttpStatus.forbidden,
  title: 'Telefono no verificado',
  code: 'PHONE_NOT_VERIFIED',
);
