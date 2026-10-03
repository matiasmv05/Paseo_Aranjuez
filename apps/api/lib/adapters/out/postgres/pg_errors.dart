import 'package:paseo_api/domain/identity/errors.dart';
import 'package:postgres/postgres.dart';

/// Mapea errores de PostgreSQL a errores tipados de dominio (brief T030 §5).
///
/// Los mensajes NUNCA copian `e.message` del servidor: pueden contener
/// valores de la fila (datos personales). El `code` del contrato lo decide
/// el caso de uso; aqui solo se traduce la causa fisica.
///
/// Errores no mapeados se relanzan tal cual (infraestructura → 500).
Never throwMappedPgError(ServerException e) {
  throw switch (e.code) {
    // Violacion de unicidad → 409 CONFLICT.
    '23505' => IdentityException.conflict('registro duplicado'),
    // Violacion de CHECK (p. ej. saldo) → error tipado de dominio.
    '23514' => IdentityException.conflict('restriccion violada'),
    // FK inexistente.
    '23503' => IdentityException.validation('referencia inexistente'),
    _ => e,
  };
}
