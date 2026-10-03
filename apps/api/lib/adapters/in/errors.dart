import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:paseo_api/domain/identity/errors.dart';
import 'package:paseo_api/problem.dart';
import 'package:paseo_shared/paseo_shared.dart';

/// Mapea `IdentityException` a problem+json (AGENTS.md §9).
/// Devuelve `null` si la excepcion no es de identidad (rethrow por el caller).
Response? mapIdentityError(Object error, {String? correlationId}) {
  if (error is IdentityException) {
    return problemJson(
      status: _statusFor(error.code),
      title: _titleFor(error.code),
      code: error.code.wire,
      detail: error.message,
      correlationId: correlationId,
    );
  }
  if (error is FormatException) {
    return problemJson(
      status: HttpStatus.unprocessableEntity,
      title: 'Unprocessable Entity',
      code: ApiErrorCode.validationFailed.wire,
      detail: 'cuerpo JSON invalido',
      correlationId: correlationId,
    );
  }
  return null;
}

int _statusFor(ApiErrorCode code) => switch (code) {
  ApiErrorCode.validationFailed ||
  ApiErrorCode.phoneNotSupported => HttpStatus.unprocessableEntity,
  ApiErrorCode.otpInvalid => HttpStatus.unprocessableEntity,
  ApiErrorCode.otpExpired => HttpStatus.unprocessableEntity,
  ApiErrorCode.otpTooManyAttempts => HttpStatus.tooManyRequests,
  ApiErrorCode.otpRateLimited => HttpStatus.tooManyRequests,
  ApiErrorCode.credentialsInvalid => HttpStatus.unauthorized,
  ApiErrorCode.unauthenticated => HttpStatus.unauthorized,
  ApiErrorCode.tokenInvalid => HttpStatus.unauthorized,
  ApiErrorCode.tokenReuseDetected => HttpStatus.unauthorized,
  ApiErrorCode.forbidden => HttpStatus.forbidden,
  ApiErrorCode.notFound => HttpStatus.notFound,
  ApiErrorCode.conflict => HttpStatus.conflict,
  ApiErrorCode.rateLimited => HttpStatus.tooManyRequests,
  _ => HttpStatus.internalServerError,
};

String _titleFor(ApiErrorCode code) => switch (code) {
  ApiErrorCode.otpTooManyAttempts ||
  ApiErrorCode.otpRateLimited => 'Too Many Requests',
  ApiErrorCode.credentialsInvalid ||
  ApiErrorCode.unauthenticated ||
  ApiErrorCode.tokenInvalid ||
  ApiErrorCode.tokenReuseDetected => 'Unauthorized',
  ApiErrorCode.forbidden => 'Forbidden',
  ApiErrorCode.notFound => 'Not Found',
  ApiErrorCode.conflict => 'Conflict',
  _ => 'Unprocessable Entity',
};

/// Parsea el cuerpo JSON del request; `null` si invalido/vacio.
Future<Map<String, Object?>?> readJson(RequestContext context) async {
  try {
    final body = await context.request.body();
    if (body.isEmpty) return null;
    final decoded = jsonDecode(body);
    return decoded is Map<String, Object?> ? decoded : null;
  } on Object {
    return null;
  }
}
