---
description: "Task list: feature 001 identidad"
---

# Tasks: Identidad de cliente y sesiones (001-identidad)

**Input**: `specs/001-identidad/spec.md` (aprobada), `specs/001-identidad/plan.md`
**Prerequisites**: spec y plan aprobados; `research.md` (Argon2id) aprobado antes de T-AD2.
**Authority**: `AGENTS.md`; las `OPEN_DECISIONS` no se resuelven sin aprobación humana explícita.

Verificación global tras cada tarea: `fvm dart format --set-exit-if-changed . && fvm dart analyze --fatal-warnings` y los tests del alcance de la tarea. Migraciones: `docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d --wait db && docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml run --rm migrate`.

## Phase 1: Setup Gates

- [ ] T001 Confirmar spec/plan aprobados y OPEN_DECISIONS intactas (correo = Gmail decidido; SMS, Argon2id-lib, regex y encuesta siguen).
- [ ] T002 [A0] Actualizar `docs/openapi.yaml`: renombrar `otp/verify`→`phone/verify` y `otp/resend`→`phone/send-otp`; añadir `POST /auth/verify-email` (token → 204 / 422 `TOKEN_INVALID`). Verificar: `npx @redocly/cli@2 lint docs/openapi.yaml` → 0 errores.
- [ ] T003 Crear esta rama: `feat/001-identidad` (nada se implementa en `main`; AGENTS.md §12).

## Phase 2: Foundational Blocking Tasks

- [ ] T004 [R0] Benchmark Argon2id → `specs/001-identidad/research.md`: candidatos `cryptography` 2.9.0 (verificar que expone Argon2id con formato PHC), `argon2_ffi` 1.0.0+2 (`sdk <4`, requiere librería nativa en imagen Dart); `argon2` 1.0.1 queda descartado (`sdk <3.0.0`). Criterios: formato PHC válido, parámetros OWASP configurables (m=19 MiB, t=2, p=1), latencia ~≥100 ms en isolate, verif. PHC interoperable. **GATE: humano elige la librería.**
- [ ] T005 [D1] `infra/migrations/V002__identidad.sql`: tablas en esquema `app` — `users` (email citext único, password_hash phc, role, status, token_version, email_verified_at), `customers` (user_id, phone E.164 único, full_name, phone_verified_at), `verification_codes` (phone, code_hash, purpose, expires_at, attempts, consumed_at), `password_resets` (user_id, token_hash, expires_at, used_at), `refresh_tokens` (user_id, aud, jti, token_hash, family_id, expires_at, revoked_at), `audit_log` (id, at UTC, actor_role, actor_user_id?, action, entity, entity_id?, correlation_id, metadata jsonb). Cada tabla: `ENABLE ROW LEVEL SECURITY` + políticas (`app.role='system'` para identidad; owner lee solo su fila en `/me` futuro; sin UPDATE/DELETE en tokens consumidos) + `GRANT` mínimos a `paseo_app`.
- [ ] T006 [D1] `infra/tests/rls/002_identity.sql`: aislamiento con rol `paseo_app` (sin contexto no ve filas; con `app.role='system'` inserta/lee; cliente solo ve su fila). Verificar: la receta del job CI `migrations` la ejecuta.
- [ ] T007 [A1] Esqueleto Dart Frog en `apps/api`: `routes/health.dart` (200 `{"status":"ok"}`), `routes/ready.dart` (200/`SERVICE_UNAVAILABLE` con chequeo BD), middleware de errores RFC 9457 + `correlation_id` y de logging sin PII. Test: contrato de ambas rutas.
- [ ] T008 [A2] `infra/api.Dockerfile` compila con `dart_frog build` (pin exacto de `dart_frog_cli` verificado con `dart pub global` y anotado en el Dockerfile). Verificar: `docker build -f infra/api.Dockerfile .` en verde y `docker run` responde `/health`.
- [ ] T009 [S1] `packages/paseo_shared/lib/src/auth/`: DTOs de los 8 endpoints + `ApiErrorCode` (códigos del `Problem` del contrato). Sin lógica de dominio.

**Checkpoint**: CI en verde en la rama con A0/D1/A1/A2; `migrate info` muestra V002 Success.

## Phase 3: Dominio y casos de uso

### User Story 1 - Registro y verificación del teléfono (P1)

- [ ] T010 [P] [US1] Tests de dominio `apps/api/test/domain/identity/`: tabla de casos de `PhoneBO.parse` (+591 válido/inválido/otro prefijo → `PHONE_NOT_SUPPORTED`), `OtpChallenge` (expira a los 5 min exactos, 5.º intento agota y bloquea, reenvío <60 s), política de contraseña.
- [ ] T011 [P] [US1] Tests de caso de uso (mocktail): `RegisterCustomer` (duplicado → 409 `CONFLICT`, dispara `OtpSender` y `EmailSender`, escribe `audit_log`), `VerifyPhoneOtp` (éxito → `pv=true`; inválido/consumido/expirado/agotado), `ResendPhoneOtp` (tope 60 s y diario).
- [ ] T012 [US1] Implementar dominio (`apps/api/lib/domain/identity/`) y casos de uso (`apps/api/lib/application/identity/`) hasta verde.
- [ ] T013 [US1] Rutas `routes/auth/register.dart`, `routes/auth/phone/verify.dart`, `routes/auth/phone/send-otp.dart`: DTO → caso de uso → RFC 9457. Tests de API.

### User Story 2 - Verificación del correo (P2)

- [ ] T014 [P] [US2] Tests: `VerifyEmail` (éxito 204; usado/vencido → `TOKEN_INVALID`).
- [ ] T015 [US2] Caso de uso + ruta `routes/auth/verify-email.dart` hasta verde.

### User Story 3 - Login y sesión por aplicación (P1)

- [ ] T016 [P] [US3] Tests: claims sin PII y con `aud` correcto; `paseo-web-admin` sin `role=admin` → 403; duales cuerpo/cookie por cliente; `CREDENTIALS_INVALID` uniforme.
- [ ] T017 [US3] `Login` + `JwtTokenSigner` (HS256, `JWT_SECRET`/`JWT_KID`, exp ≤ 900) + rutas `login.dart` con `X-Paseo-Client` y `Set-Cookie` web. Verde.

### User Story 4 - Refresh rotativo y logout (P1)

- [ ] T018 [P] [US4] Tests: rotación, reutilización → `TOKEN_REUSE_DETECTED` + revocación de familia, concurrencia (solo uno gana), web sin `X-Paseo-Client`/`Origin` válido → 401/403.
- [ ] T019 [US4] `RefreshSession`, `Logout` + rutas `refresh.dart`, `logout.dart`. Verde.

### User Story 5 - Recuperación de contraseña (P2)

- [ ] T020 [P] [US5] Tests: `forgot` siempre 202 (cuerpos idénticos), token un solo uso/30 min, `reset` → `token_version++` + revoca familia.
- [ ] T021 [US5] `ForgotPassword`, `ResetPassword` + rutas `password/forgot.dart`, `password/reset.dart`. Verde.

## Phase 4: Adapters e integración

- [ ] T030 [AD1] `adapters/out/postgres/`: repositorios + `TransactionRunner` (setea `app.user_id/app.role/app.customer_id/...` con `set_config(..., true)` en cada transacción; identidad usa `app.role='system'`). Tests de integración contra contenedor con `paseo_app`.
- [ ] T031 [AD2] `Argon2idPasswordHasher` (librería aprobada en T004, en `Isolate`), `SmtpEmailSender` (mailer 7.2.0, Gmail), `ConsoleOtpSender`, `ConsoleEmailSender` (dev). Tests con vector PHC conocido (formato) y SMTP contra servidor de prueba local efímero o mock de socket.
- [ ] T032 Middleware de rate limit (login/OTP/recuperación → 429 `RATE_LIMITED`; ventana y tope por configuración de `system_settings` cuando exista, mientras constantes documentadas).
- [ ] T033 [W1] `bin/worker.dart`: job horario `CleanupExpiredCredentials` (borra OTP y resets vencidos). Test de integración.

## Phase N: Cross-Cutting Verification

- [ ] T090 `fvm dart format --set-exit-if-changed . && fvm dart analyze --fatal-warnings && fvm dart test` (apps/api, packages/paseo_shared) en verde.
- [ ] T091 Migraciones desde cero + `migrate validate` + `infra/tests/rls/` en verde (local y CI).
- [ ] T092 Revisión de seguridad (skill `security`): cookies, claims, logs sin PII, 202 uniforme, rate limits; escaneo de secretos del diff (`github_run_secret_scanning`).
- [ ] T093 Actualizar `docs/agent-audit.md`, `AGENTS.md` §1.1 y `INFRASTRUCTURE.md` si el estado cambió; gate §16 completo.

## Dependencies & Execution Order

- T001–T009 bloquean todo; T005/T006 preceden a T030/T033.
- T004 (research) bloquea únicamente T031.
- Tests (T010/T011, T014, T016, T018, T020) preceden a su implementación (TDD).
- Ramas de historias son paralelizables después de Phase 2, salvo T017/T019 (comparten `JwtTokenSigner` y middleware de auth: secuenciar tras T030–T031).
- Un agente por historia/rama; no dos agentes sobre los mismos archivos.

## Notes

- Rutas finas: validación → un caso de uso → mapeo RFC 9457 (AGENTS.md §3).
- Dominio sin imports de framework ni postgres.
- Códigos de error solo del contrato (`ApiErrorCode`).
