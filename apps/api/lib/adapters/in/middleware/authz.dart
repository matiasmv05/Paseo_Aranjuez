import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/adapters/out/auth/jwt_token_verifier.dart';
import 'package:paseo_api/domain/identity/identity.dart';
import 'package:paseo_api/problem.dart';

Middleware customerAuth({bool requirePhoneVerified = false}) {
  return (handler) {
    return (context) async {
      final authHeader = context.request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return problemJson(
          status: HttpStatus.unauthorized,
          title: 'Unauthorized',
          code: 'UNAUTHENTICATED',
        );
      }
      final token = authHeader.substring(7);

      final secret = Platform.environment['JWT_SECRET'] ?? '';
      final verifier = JwtTokenVerifier(secret: secret);

      final claims = verifier.verify(token, now: DateTime.now().toUtc());
      if (claims == null || claims.audience != ClientApp.mobile.audience) {
        return problemJson(
          status: HttpStatus.unauthorized,
          title: 'Unauthorized',
          code: 'UNAUTHENTICATED',
        );
      }

      if (claims.role != UserRole.customer) {
        return problemJson(
          status: HttpStatus.forbidden,
          title: 'Forbidden',
          code: 'FORBIDDEN',
        );
      }

      if (requirePhoneVerified && !claims.phoneVerified) {
        return problemJson(
          status: HttpStatus.forbidden,
          title: 'Forbidden',
          code: 'PHONE_NOT_VERIFIED',
        );
      }

      return handler(context.provide<AuthClaims>(() => claims));
    };
  };
}
