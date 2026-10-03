# Paseo Points Constitution

> `AGENTS.md` es la política gobernante del repositorio. Esta constitución es una memoria operativa para Spec Kit y no reemplaza, reinterpreta ni amplía `AGENTS.md`. Si existe conflicto, gana `AGENTS.md`.

## Principios innegociables

### I. Servidor como fuente de verdad
El cliente Flutter nunca calcula puntos de forma autoritativa. Toda previsualización y registro usa el mismo código del servidor.

### II. Ledger de solo inserción
Los puntos se mueven únicamente mediante `points_ledger`. Nunca se hace `UPDATE` ni `DELETE`; una anulación es un movimiento `REVERSAL`. El saldo nunca es negativo y lo mantiene el trigger configurado por la base.

### III. Escrituras críticas idempotentes y auditables
Toda escritura crítica exige `Idempotency-Key` cuando el contrato lo declara y debe registrar `audit_log`. La misma clave devuelve la respuesta original sin duplicar efectos.

### IV. Contrato antes que endpoint
Todo endpoint existe primero en `docs/openapi.yaml`, luego en la ruta y finalmente en pruebas. Los errores usan `application/problem+json` (RFC 9457) con `code` estable.

### V. Base de datos con defensa en profundidad
Toda tabla nace con RLS, políticas, `GRANT` mínimos y prueba de aislamiento. La API usa un rol sin privilegios de dueño ni `BYPASSRLS`. Las migraciones aplicadas son inmutables; las semillas viven fuera de `infra/migrations/`.

### VI. Identidad sin datos personales en el JWT
Los claims no contienen datos personales. Teléfono boliviano (`+591`) verificado por SMS es mínimo obligatorio; el correo habilita recuperación de cuenta. Contraseñas con Argon2id en formato PHC.

### VII. Arquitectura y trazabilidad
Backend `adapters → application → domain`; rutas finas; ninguna regla de negocio en rutas. Ningún cambio de comportamiento sin spec y prueba. Cada cambio debe ser trazable: requisito → spec → plan → tareas → implementación → pruebas.

### VIII. Reembolsos controlados
El personal solicita; solo `admin` resuelve. La reversión se realiza como `REVERSAL` del ledger, sin editar la compra ni el crédito original. Sucursal y hora vienen del servidor, nunca del cliente HTTP.

### IX. Decisiones abiertas
Open decisions remain OPEN. Ninguna plantilla, agente ni implementación puede resolver una decisión marcada como abierta sin aprobación humana explícita.

## Restricciones adicionales

- Dinero y puntos en enteros; nunca `double`/`float`.
- Web comercio y web administración son builds separados, con audiencias y cookies propias.
- `uploads` no se expone por Caddy ni por URL pública.
- No se registran contraseñas, OTP, tokens, teléfonos completos ni correos completos.
- No se usa `flyway clean`; la aplicación nunca ejecuta migraciones ni DDL.

## Flujo de desarrollo

1. Constitución/política: `AGENTS.md` y esta memoria.
2. Feature spec: `specs/<feature>/spec.md`.
3. Plan: `specs/<feature>/plan.md`.
4. Tareas: `specs/<feature>/tasks.md`.
5. Contrato API cuando aplique: `docs/openapi.yaml`.
6. Implementación, pruebas, revisión y gates del repositorio.

El humano aprueba spec y plan antes de implementar.

## Gobernanza

- Las enmiendas se documentan primero en `AGENTS.md` o en la fuente normativa correspondiente; esta memoria se actualiza después.
- Toda plantilla bajo `.specify/templates/` debe remitir a `AGENTS.md` y mantener las decisiones abiertas como `OPEN_DECISIONS` cuando apliquen.
- `INFRASTRUCTURE.md` define dónde corre cada servicio; `9-stack-tecnologico-paseo-points.md` documenta decisiones técnicas y pendientes.

**Version**: 0.1.0 | **Ratified**: 2026-10-02 | **Last Amended**: 2026-10-02
