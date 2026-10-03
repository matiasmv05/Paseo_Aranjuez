# Implementation Plan: 001-identidad

**Branch**: `feat/001-identidad` | **Date**: 2026-10-03 | **Spec**: `specs/001-identidad/spec.md`

**Input**: Feature specification from `specs/001-identidad/spec.md` (Approved)

**Authority**: `AGENTS.md` and `.specify/memory/constitution.md` govern this plan.

## Summary

Implementar identidad de cliente y sesiones: V002 (usuarios/clientes/OTP/recuperación/refresh/auditoría mínima con RLS + prueba de aislamiento), contrato OpenAPI actualizado **antes** de rutas, esqueleto Dart Frog, dominio y casos de uso con puertos, adaptadores Postgres/JWT/Argon2id/SMTP/consola y el job de limpieza del worker. No resuelve `OPEN_DECISIONS`: la librería Argon2id se decide con un benchmark en la Tarea 7 (salida en `research.md`, elección humana); SMS/correo van tras puertos.

## Technical Context

**Language/Version**: Dart 3.13.5 / Flutter 3.47.6 vía FVM (`.fvmrc`)
**Primary Dependencies**: `dart_frog` (API), driver PostgreSQL y librerías JWT/Argon2id/SMTP **a verificar en pub.dev en el momento de cada tarea** (AGENTS.md §14: nunca de memoria).
**Storage**: PostgreSQL vía Flyway (`V002__identidad.sql`); RLS con contexto por transacción (`set_config`).
**Testing**: `dart test` (dominio), integración contra PostgreSQL efímero (rol `paseo_app`), `infra/tests/rls/002_*.sql` en CI, `redocly lint`, `dart analyze`/`dart format`.
**Target Platform**: `api`, `worker` (job de limpieza). Clientes Flutter: solo consumo posterior del contrato (fuera de esta feature).
**Constraints**: server authoritative, RLS, auditabilidad, idempotencia, sin datos personales en JWT/logs, Argon2id, cookies por audiencia.
**Scale/Scope**: 9 endpoints de auth, 6 tablas, 1 job del worker.

## Constitution Check

*GATE: Must pass before implementation and again before review.*

- [x] `docs/openapi.yaml` updated before any endpoint implementation → **Tarea 1 precede a todas las rutas**
- [x] Backend preserves `adapters → application → domain` → estructura fijada; `CI` de arquitectura en esta feature
- [x] No business rules in routes or Flutter presentation/data layers → rutas solo validan/llaman un caso de uso
- [x] New tables include RLS, policies, minimum `GRANT`, and isolation tests → **Tarea 2**
- [x] Critical writes include `Idempotency-Key` and `audit_log` → auditoría en Tarea 8; idempotencia de escrituras de auth no aplica por naturaleza (login/verify no son efectos financieros); se revisa en la tarea de rutas
- [x] JWT claims contain no personal data → claims fijados por spec
- [x] Uploads N/A
- [x] `OPEN_DECISIONS` remain open → librería Argon2id se decide por benchmark (Tarea 7) con elección humana; proveedores SMS/SMTP tras puertos

## Project Structure

### Documentation (this feature)

```text
specs/001-identidad/
├── spec.md
├── plan.md      # este archivo
├── research.md  # benchmark Argon2id + verificación de versiones pub.dev (salida de Tareas 0/7)
└── tasks.md     # se genera tras aprobar este plan
```

### Source Code (repository root)

```text
apps/api/
├── bin/server.dart                 # entrypoint Dart Frog
├── bin/worker.dart                 # job de limpieza (OTP/password_resets/QR vencidos)
├── routes/                         # Dart Frog: index /health,/ready + /api/v1/auth/*
├── middleware + _middleware.dart
└── lib/
    ├── domain/                     # PhoneBO, PasswordPolicy, OtpCode, errors
    ├── application/                # use cases + ports
    └── adapters/{in,out}/          # DTOs/rutas + Postgres/Jwt/Argon2/Smtp/Console
packages/paseo_shared/              # DTOs y códigos de error del contrato auth
.github/workflows/ci.yml            # hook RLS ya existe; el test vive en infra/tests/rls/
infra/migrations/V002__identidad.sql
infra/tests/rls/002_identidad.sql
```

**Prueba de regla hexagonal**: `tool/check_architecture.dart` (o script equivalente) que falla si `application`/`domain` importan `adapters` o paquetes externos no permitidos; se añade al job `dart` de CI.

## Data / Contract / Infrastructure Impact

- **API contract**: ajustar `POST /auth/otp/verify` → `POST /auth/phone/verify`, `POST /auth/otp/resend` → `POST /auth/phone/send-otp`; añadir `POST /auth/verify-email`. Respuestas y códigos según spec §User Stories (ver spec, acceptance scenarios).
- **Database**: `V002__identidad.sql` con `users`, `customers`, `verification_codes`, `password_resets`, `refresh_tokens`, `audit_log` (mínima): RLS + políticas + `GRANT` mínimos a `paseo_app` + prueba de aislamiento en `infra/tests/rls/002_identidad.sql`.
- **Infrastructure**: ninguna nueva variable; `EMAIL_SENDER=smtp` ya en `.env.example` (03/10).
- **Security**: Argon2id (PHC, parámetros OWASP, fuera del hilo principal); JWT con claims §6 y `kid`; cookies web propias; `X-Paseo-Client` + validación de `Origin` en refresh; rate limiting lógico sobre OTP (intentos/reenvío) y hook de rate limit HTTP.
- **Notifications/jobs**: worker: limpieza horaria de `verification_codes` y `password_resets` vencidos (y QR cuando exista tabla).

## Test Strategy

- **Domain tests**: tabla de casos para teléfono (`+591` ok, otros prefijos → `PHONE_NOT_SUPPORTED`), política de contraseña, vigencia/intentos del OTP, rotación/detección de reutilización de refresh (máquina de estados pura).
- **Integration tests**: repositorios contra PostgreSQL (servicio `db` del compose local / efímero en CI) con rol `paseo_app`; transacción con `set_config`; concurrencia: dos refresh paralelos → uno 200, otro 401; `reset` → `token_version++` y revocación.
- **API tests**: matriz de autorización/audiencias (mobile body refresh vs web cookie), RFC 9457 con `code` en cada error, siempre-202 en `forgot` y en `phone/send-otp`.
- **RLS tests**: `infra/tests/rls/002_identidad.sql` ejecutado por CI con `paseo_app`.
- **Verification commands**: `fvm dart format --set-exit-if-changed .`, `fvm dart analyze --fatal-warnings`, `fvm dart test` (apps/api, packages/paseo_shared), `npx @redocly/cli lint docs/openapi.yaml`, `docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d --wait db && docker compose ... run --rm migrate`, `docker build -f infra/api.Dockerfile .` (solo tras la Tarea 3).

## Review Focus

1. OTP propio es criptografía-adyacente: vigencia, comparación y hash deben ser exactos (Tarea 6, tests de vencimiento/intentos/consumo).
2. Detección de reutilización de refresh bajo carrera (Tarea 10; test de concurrencia).
3. Cookie/audiencia cruzadas entre webs (Tarea 11; test de matriz de audiencias).
4. `token_version++` y revocación en `reset` (Tarea 12; test).
5. Logs libres de secretos (Tarea 13; test de forma de log/respuesta, ningún OTP/token/teléfono completo).

## Implementation Sequence

> Detail ejecutable hasta paso/nombre; código completo solo donde signature+test no lo determinan.

- **T0. Research (verificación de versiones)**: consultar pub.dev y fijar en `pubspec`/`research.md`: `dart_frog`, driver Postgres, JWT, SMTP, librerías Argon2id candidatas. Nada se fija "de memoria".
- **T1. Contrato OpenAPI** (renombrar/añadir los 3 endpoints; ajustar respuestas de register/verify) + `redocly lint` verde. *Sin este, ninguna ruta.*
- **T2. V002 migración + RLS + grants + prueba de aislamiento** en `infra/tests/rls/002_identidad.sql`; CI la ejecuta. Verificación: `migrate validate` + prueba RLS verde.
- **T3. Esqueleto API/worker**: `bin/server.dart`, `bin/worker.dart`, middleware JSON + `Problem`, `/health` `/ready`; chequeo de regla hexagonal integrado al job `dart` de CI (falla si `application`/`domain` importan de `adapters`); `docker build` verde.
- **T4. paseo_shared**: DTOs/códigos de auth del contrato.
- **T5. domain**: `PhoneBO` (E.164 `+591`), `PasswordPolicy`, `OtpCode` (6 dígitos, 5 min, 5 intentos), errores de identidad. Tests por tabla.
- **T6. application: puertos + casos de uso de emisión** (registro, envío/verificación OTP, verify-email) con puertos `OtpSender`, `EmailSender`, `PasswordHasher`, `TokenService`, repos y `AuditLog`, `Clock`, `IdGenerator`. Tests con dobles.
- **T7. Research Argon2id** → `research.md` con benchmark de candidatas; **elección humana registrada** (decisión abierta). *Bloquea solo la T8-hasher, no el resto.*
- **T8. application: casos de uso de sesión** (Login, Refresh, Logout, Forgot, Reset) + máquina de rotación/revocación. Tests con dobles (incluye reutilización → `TOKEN_REUSE_DETECTED`).
- **T9. adapters/out Postgres**: repos de T6/T8 + transacción con `set_config` de contexto RLS; integración real.
- **T10. adapters/out JWT + Argon2id + senders**: `JwtTokenService` (claims §6, `kid`, `aud` por cliente), hasher elegido en T7 (PHC, fuera del hilo), `SmtpEmailSender`, `ConsoleOtpSender`, `ConsoleEmailSender`.
- **T11. adapters/in**: middleware de autenticación/audiencias + contexto RLS desde claims; rutas de los 9 endpoints; mapeo de errores a `problem+json` con `code`.
- **T12. worker**: job horario de limpieza de OTP/tokens vencidos.
- **T13. Verificación E2E del criterio SC-001/002/003**: flujo completo en local + matriz de pruebas del cap. 9 para identidad + checklist de logs sin PII.

Pruebas primero en cada tarea (TDD); commits frecuentes con Conventional Commits referenciando HU-01/HU-02.

## Rollback / Forward Fix

- V002 es inmutable tras aplicarse; cualquier corrección es una migración nueva.
- La API se puede reconstruir/revertir a voluntad: la base marca el estado real del contrato de datos.
