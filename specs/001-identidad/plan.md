# Identidad (001) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use `superpowers:subagent-driven-development` (recomendado) o `superpowers:executing-plans` para implementar este plan tarea a tarea. Los pasos usan checkbox (`- [ ]`).

**Goal:** Registro/verificación de cliente, login por audiencia, refresh rotativo, logout y recuperación de contraseña sobre PostgreSQL con RLS, según `specs/001-identidad/spec.md` (**aprobada**).

**Architecture:** API Dart Frog con hexagonal (`adapters → application → domain`), PostgreSQL con RLS y contexto por transacción (`set_config(..., true)`), identidad tras puertos (`OtpSender`, `EmailSender`, `PasswordHasher`, `TokenSigner`). El router es fino: valida DTO → llama **un** caso de uso → mapea a RFC 9457.

**Tech Stack:** Dart 3.13 / FVM 3.47.6 · `dart_frog` 1.2.6 · `postgres` 3.5.18 · `dart_jsonwebtoken` 3.4.1 · `mailer` 7.2.0 (`SmtpEmailSender`, Gmail) · `crypto` 3.0.7 · `uuid` 4.6.0 · `mocktail` 1.0.5 · `test` 1.32.0 · **Argon2id: librería pendiente de benchmark (Task R0; decisión humana)**.

**Spec:** `specs/001-identidad/spec.md`

## Global Constraints

- Reglas 1–10 de `AGENTS.md` §2; claims exactos `iss, aud, sub, iat, exp, jti, role, cid, est, br, pv, ev, tv`; access ≤ 900 s; sin datos personales en JWT ni logs.
- Teléfonos `+591` E.164, regex laxa `^\+591[0-9]{8}$` (endurecer solo tras decisión).
- Contraseña: **Argon2id**, formato PHC, parámetros mínimos OWASP, fuera del hilo principal.
- OTP: 6 dígitos, solo hash, 5 min, 5 intentos, reenvío ≥ 60 s, tope diario por teléfono e IP.
- `forgot` **siempre 202**; token ≥ 32 bytes, hasheado, 30 min, un solo uso; `reset` → `token_version++` y revoca refreshes.
- Cookies web: `HttpOnly; Secure; SameSite=Strict; Path=/api/v1/auth`, nombres `__Secure-rt_merchant` / `__Secure-rt_admin`; refresh web exige `X-Paseo-Client` y valida `Origin`.
- `docs/openapi.yaml` se actualiza **antes** que cualquier ruta (Task A0).
- Toda tabla nueva: `ENABLE ROW LEVEL SECURITY` + políticas + `GRANT` mínimos + prueba de aislamiento en `infra/tests/rls/`.
- Migraciones inmutables; la app nunca ejecuta DDL; el CI de migraciones ya corre (job `migrations`).
- `OPEN_DECISIONS` de la spec permanecen abiertas salvo la marcada como decidida (correo: Gmail + `SmtpEmailSender`).

## Review Focus

1. **Reutilización de refresh en carrera** (dos `refresh` paralelos): exactamente uno 200, otro 401; fijado en test de concurrencia del caso de uso (Task C6/T4).
2. **`pv` desactualizado en el token** (usuario verificado hace <15 min): la verificación otorga sesión fresca; se prueba login tras verify.
3. **Reloj/hora UTC en OTP y tokens** (5 min exactos, borde incluido): tests de dominio con `Clock` inyectado.
4. **Respuesta uniforme de `forgot`** (nada distingue existencia de correo): test de contrato comparando cuerpos.
5. **`audit_log` sin datos personales** (payload mínimo): test de integración inspecciona columnas.

## Constitution Check

- [x] `docs/openapi.yaml` antes que las rutas (Task A0 precede a R*).
- [x] `adapters → application → domain` (sin imports hacia atrás; CI lo verificará cuando exista el job de arquitectura — pendiente).
- [x] Rutas sin reglas de negocio (solo DTO→caso de uso→RFC 9457).
- [x] V002 con RLS+GRANT+pruebas; `audit_log` mínima adelantada (decisión aprobada en spec).
- [ ] Job de CI "arquitectura hexagonal" aún no existe → se añade en Task CI1.
- [x] Sin datos personales en JWT/listados.

## Project Structure

```text
apps/api/
├── bin/{server.dart,worker.dart}
├── routes/
│   ├── health.dart · ready.dart
│   └── auth/{register,phone/verify,phone/send-otp,verify-email,login,refresh,logout,password/forgot,password/reset}.dart
├── lib/
│   ├── domain/{identity/…}
│   ├── application/{identity/{ports,use_cases},…}
│   └── adapters/{in/{http/{dto,middleware}},out/{postgres,jwt,smtp,console,argon2}}
packages/paseo_shared/lib/src/auth/…  # DTOs y códigos de error
infra/migrations/V002__identidad.sql
infra/tests/rls/002_identity.sql
```

## Data / Contract / Infrastructure Impact

- **API contract**: renombrar `otp/verify`→`phone/verify`, `otp/resend`→`phone/send-otp`, añadir `POST /auth/verify-email` (Task A0).
- **Database**: `V002__identidad.sql` — `users`, `customers`, `verification_codes`, `password_resets`, `refresh_tokens`, `audit_log` (mínima) en esquema `app`, con RLS, grants y pruebas (Task D1).
- **Infrastructure**: `api.Dockerfile` pasa a usarse de verdad (Task A2 verifica build); sin nuevas variables (Gmail ya en `.env.example`).
- **Security**: JWT con `darty_jsonwebtoken`→ **`dart_jsonwebtoken`** 3.4.1; cookies por audiencia; rate limit en login/OTP/recuperación (middleware).
- **Notifications/jobs**: worker con job de limpieza de OTP/resets vencidos (Task W1).

## Test Strategy

- **Domain tests**: tablas de casos (teléfono `+591`, OTP expira/intentos, rotación/reuso de refresh, claims sin PII).
- **Integration tests**: PostgreSQL real (contenedor, rol `paseo_app`): repos + transacción con `set_config`, aislamiento RLS (`infra/tests/rls/002_identity.sql` lo corre CI), concurrencia de refresh.
- **API tests**: contrato RFC 9457, códigos estables (`PHONE_NOT_SUPPORTED`, `OTP_*`, `CREDENTIALS_INVALID`, `TOKEN_REUSE_DETECTED`, `RATE_LIMITED`), cookies web, respuesta uniforme de `forgot`.
- **Verification commands**: `fvm dart format --set-exit-if-changed . && fvm dart analyze --fatal-warnings && fvm dart test` en `apps/api` y `packages/paseo_shared`; `docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d --wait db && … run --rm migrate && migrate validate`; `redocly lint docs/openapi.yaml` (CI).

## Rollback / Forward Fix

- Nada se deshace: errores de esquema se corrigen con `V003+`. Compatibilidad del contrato garantizada porque las rutas nacen del `openapi.yaml` aprobado.

## Implementation Sequence

Orden (cada tarea termina en verde con sus pruebas y commit propio):

- [ ] **T-A0** Contrato: actualizar `docs/openapi.yaml` (renombres + `verify-email`) → `redocly lint` verde.
- [ ] **T-R0** Research: benchmark Argon2id (`cryptography` 2.9.0 si incluye Argon2id, `argon2_ffi` 1.0.0+2, `argon2` 1.0.1 queda descartada por `sdk <3.0.0` salvo fork) → `specs/001-identidad/research.md` + **aprobación humana** de la librería (OPEN_DECISION).
- [ ] **T-A1** Esqueleto Dart Frog: `routes/health.dart`, `routes/ready.dart` (ready falla sin BD), pipeline con `problem+json`.
- [ ] **T-A2** Dockerfile: `dart_frog build` (pin de `dart_frog_cli` registrado en el Dockerfile tras verificar versión) y `docker build` verde localmente.
- [ ] **T-D1** `V002__identidad.sql` (tablas + RLS + GRANT) + `infra/tests/rls/002_identity.sql`; `migrate` desde cero en verde.
- [ ] **T-S1** `paseo_shared`: DTOs de auth + enum `ApiErrorCode` (solo contrato).
- [ ] **T-DO1** Dominio: `Email`, `PhoneBO`, `OtpChallenge` (TTL/intentos/ventana), `RefreshChain` (rotación/reuso), `AuthClaims` — tests de tabla.
- [ ] **T-AP1** Puertos + casos de uso: `RegisterCustomer`, `VerifyPhoneOtp`, `ResendPhoneOtp`, `VerifyEmail`, `Login`, `RefreshSession`, `Logout`, `ForgotPassword`, `ResetPassword`, `CleanupExpiredCredentials` — tests con mocks.
- [ ] **T-AD1** Adapters out Postgres (repos + `TransactionRunner` con `set_config(..., true)`) — tests contra contenedor con `paseo_app`.
- [ ] **T-AD2** Adapters out de terceros: `JwtTokenSigner` (HS256 desde `JWT_SECRET`+`JWT_KID`), `Argon2idPasswordHasher` (aislado; librería aprobada en T-R0), `SmtpEmailSender` (mailer 7.2.0, credenciales Gmail), `ConsoleOtpSender`/`ConsoleEmailSender`.
- [ ] **T-R1…T-R9** Rutas auth (una por endpoint) + middles (auth/contexto RLS/rate limit) — tests de API.
- [ ] **T-W1** Worker: job de limpieza (OTP, resets, QR n/a) cada hora.
- [ ] **T-G1** Gates finales: CI verde, auditoría §16, PR con trazabilidad.

El detalle ejecutable (archivos, firmas, tests y comandos por paso) está en `tasks.md`.
