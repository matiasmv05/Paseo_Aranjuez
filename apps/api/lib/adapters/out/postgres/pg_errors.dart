import 'package:paseo_api/domain/identity/errors.dart';
import 'package:paseo_api/domain/points/errors.dart';
import 'package:postgres/postgres.dart';

Never throwMappedPgError(ServerException e) {
  throw switch (e.code) {
    '23505' => IdentityException.conflict('Registro duplicado'),
    '23503' => IdentityException.conflict('Referencia inexistente'),
    _ => e,
  };
}

Never throwMappedPointsPgError(ServerException e) {
  throw switch (e.code) {
    '23514' => PointsException.insufficientPoints(),
    '23505' => PointsException.conflict(
      'Entrada duplicada (idempotencia o referencia)',
    ),
    '23503' => PointsException.conflict('Referencia inexistente'),
    _ => e,
  };
}
