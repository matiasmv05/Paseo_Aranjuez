# Agent Audit — Paseo Points

Fecha de auditoría: 03/10/2026
Estado: UPDATED (auditoría post-implementación de fundaciones). Código e infraestructura implementados y verificados.

## CURRENT_STATE

DOCUMENTED:
- `AGENTS.md` (actualizado 03/10/2026): reglas innegociables, arquitectura, endpoints, decisiones abiertas/cerradas. Constitución SDD.
- `INFRASTRUCTURE.md`: servicios, roles BD, Flyway, variables, CI/CD, backups, Caddy.
- `9-stack-tecnologico-paseo-points.md`: stack, arquitectura, ADR/roadmap, endpoints MVP, matriz pruebas, decisiones.
- `docs/openapi.yaml`: OpenAPI 3.1 — servidor `/api/v1`, `Problem` RFC 9457, `bearerAuth` con audiencias, `Idempotency-Key`, `MoneyCents`, `CursorPage`; `GET /health`, `GET /ready`, 8 endpoints auth.
- `.specify/`: Spec Kit local — constitución, templates (spec/plan/tasks/checklist), `specs/README.md`.
- `specs/001-identidad/`: spec.md, plan.md, tasks.md (29 tareas, casillas sin marcar pese a avance real), research.md.
- `CLAUDE.md`: `@AGENTS.md`.

IMPLEMENTED:
- Monorepo pub workspaces: `apps/api` (Dart Frog), `apps/mobile` (Flutter), `packages/paseo_shared` (DTOs auth, `ApiErrorCode`).
- FVM: `.fvmrc` → Flutter 3.47.6 / Dart 3.13; `fvm flutter pub get`, `analyze`, `format` en verde.
- `analysis_options.yaml`: `very_good_analysis` 11, exclusiones estándar.
- Infraestructura Docker Compose (`paseo-aranjuez`):
  - `db`: `postgres:18-alpine` (18.6, PGDATA=/var/lib/postgresql/18/docker), healthcheck, volúmenes.
  - `migrate`: `flyway/flyway:13.9.0`, `FLYWAY_CLEAN_DISABLED=true`, validación nombres.
  - `api`: multi-stage `infra/api.Dockerfile` (dart:3.13.5), `expose: 8080`, healthcheck `/app/healthcheck`, usuario no-root, read-only fs.
  - `worker`: misma imagen, comando `worker`.
  - `caddy`: `caddy:2.11.6-alpine`, puertos 80/443/8443, sirve `build/web-merchant` (443) y `build/web-admin` (8443), proxy `/api/*` → `api:8080`.
  - `backup`: `postgres:18-alpine` + `backup.sh`, `paseo_backup` (BYPASSRLS + pg_read_all_data), respalda `uploads`.
  - Dev override: `docker-compose.dev.yml` publica DB en `127.0.0.1:${DB_DEV_PORT:-5432}`, semillas, `OTP_SENDER=console`, `EMAIL_SENDER=smtp`.
- Roles BD (init script): `postgres_admin` (solo init), `paseo_owner` (Flyway), `paseo_app` (API/worker, NOBYPASSRLS), `paseo_backup` (backup, BYPASSRLS).
- Migraciones Flyway:
  - `V001__baseline_extensions_y_esquema.sql`: extensiones `citext`, `pgcrypto`, esquema `app`, roles/grants base.
  - `V002__identidad.sql`: tablas `users`, `customers`, `verification_codes`, `password_resets`, `refresh_tokens`, `audit_log` en esquema `app`; **sin RLS** (MVP); `GRANT` mínimos a `paseo_app`; `REVOKE UPDATE,DELETE,TRUNCATE` en `audit_log`.
- Semilla dev: `infra/seed/R__seed_dev.sql` (solo con override dev).
- CI: `.github/workflows/ci.yml` — jobs `dart` (format/analyze/unit tests excluyendo integration), `openapi` (redocly), `migrations` (DB desde cero + Flyway + chequeos roles/extensiones/DDL denegado + RLS tests hook), `integration` (DB 5433 + `dart test test/integration`), `migration-immutability` (rechaza M/D en `infra/migrations/` vs `main`).
- Backend `apps/api`:
  - Hexagonal: `lib/domain/identity/*`, `lib/application/identity/{ports,use_cases/*}`, `lib/adapters/out/postgres/*` (repositorios, transaction runner, audit log writer).
  - Rutas: `routes/health.dart`, `routes/ready.dart`, `routes/_middleware.dart` (RFC 9457, correlation_id, logging sin PII).
  - Binarios: `bin/server.dart` (stub), `bin/worker.dart` (stub), `bin/healthcheck.dart`.
  - Tests: `test/domain/identity/*`, `test/application/identity/*`, `test/routes/health_test.dart`, `ready_test.dart`, `middleware_test.dart`, `test/integration/support.dart` (helpers `uniqueEmail`, `uniquePhone`, `newId`, config BD 5433), `test/integration/*_test.dart`.
- `packages/paseo_shared`: `lib/src/auth/*` (DTOs 8 endpoints), `lib/src/errors/*` (`ApiErrorCode`).
- Flutter `apps/mobile`: solo `lib/main.dart` (stub); sin `main_merchant_web.dart` ni `main_admin_web.dart`.

TESTED:
- Unitarias: domain + application + routes (excluye integration) — pasan en CI.
- Integración: `test/integration/*` contra BD dev en loopback:5433 (requiere `DB_DEV_PORT=5433` en `infra/.env` o shell).
- OpenAPI: `redocly lint docs/openapi.yaml` — 0 errores.
- Migraciones: `flyway migrate` + `validate` desde BD vacía — éxito.
- Roles/permisos: verificados en CI job `migrations` (3 roles, `paseo_app` sin BYPASSRLS, 2 extensiones, DDL denegado).

VERIFIED:
- `git status`: árbol limpio en rama `feat/001-identidad`.
- `docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d --wait db` → DB healthy.
- `flyway info` → V001 Success, V002 Success.
- `caddy validate` → OK.
- `fvm dart format --set-exit-if-changed .` → sin cambios.
- `fvm dart analyze --fatal-warnings` → sin errores.
- `fvm dart test` (packages) + `fvm dart test test/domain test/application test/routes` (api unit) → verde.
- OpenAPI endpoints coinciden con `AGENTS.md` §6/§8.

## MISSING

- **Identity routes** (`routes/auth/*`) y `adapters/in` (T013–T021): no implementados.
- **Argon2idPasswordHasher** (T031): falta; `cryptography` 2.9.0 decidida, PHC + Isolate requerido.
- **SmtpEmailSender** (T031): falta; `mailer` 7.2.0, Gmail/Google Workspace SMTP.
- **Console OTP/Email senders** (T031): faltan para dev (`OTP_SENDER=console`, `EMAIL_SENDER=console`).
- **Rate-limit middleware** (T032): falta; login/OTP/forgot → 429 `RATE_LIMITED`.
- **Worker job real** (T033): `bin/worker.dart` stub; falta `CleanupExpiredCredentials` horario.
- **Flutter web entry points**: `main_merchant_web.dart`, `main_admin_web.dart` no existen.
- **Specs features 002+**: solo 001-identidad existe.
- **RLS + isolation tests**: deuda bloqueante pre-producción (MVP sin RLS, decisión 03/10/2026).
- **Proveedor SMS**: decisión abierta (solo OTP por consola en dev).
- **Valores iniciales config**: `refund_window_days`, retención fotos, tamaños, vencimientos — por decidir.

## CONTRADICTIONS

- **Tasks.md vs código real**: `specs/001-identidad/tasks.md` tiene 29 casillas sin marcar, pero domain/application/adapters-out/tests existen y pasan. **Regla**: no usar checkboxes como estado; verificar archivos.
- **RLS**: `AGENTS.md` §2 regla 7 y §5.3 dicen "RLS en toda tabla"; decisión de equipo 03/10/2026 = MVP sin RLS (ver §BLOCKERS). Documentado en `AGENTS.md` como SUPERSEDIDO.
- **Mailpit**: `INFRASTRUCTURE.md` §15.4 decía "confirmar proveedor OTP/correo"; decisión 03/10 = sin Mailpit, SMTP real (`SmtpEmailSender` propio).
- **DB_DEV_PORT**: Dev compose publica en 5432 por defecto; tests de integración y CI usan 5433. Requiere `DB_DEV_PORT=5433` en `infra/.env` o prefijado en shell.

## DECISIONES DE EQUIPO (03/10/2026)

- **MVP sin RLS** (supersede AGENTS.md §2 regla 7 y §5.3): tablas con `GRANT` mínimos; aislamiento en middleware. Deuda bloqueante pre-prod.
- **Argon2id**: `cryptography` 2.9.0, PHC, OWASP m=19MiB/t=2/p=1, Isolate.
- **Correo**: Gmail/Google Workspace SMTP, `SmtpEmailSender` propio (sin Mailpit).
- **SMS mínimo**: solo registro + cambio teléfono; OTP por consola en dev.
- **Teléfonos**: solo `+591` (Bolivia), E.164, 8 dígitos iniciando 6/7 (regex por confirmar).
- **Dos builds web**: merchant (443) y admin (8443), cookies/audiencias separadas.
- **Conversión puntos**: solo admin; puntos sobre `net_cents`; versión reglas + snapshot.
- **Reembolsos**: cajero/duenño solicitan; solo admin resuelve; `REVERSAL` en ledger; foto+factura+razón social; ventana configurable; saldo insuficiente = parcial.
- **Sucursales**: cajero 1 sucursal fija (`br` claim); dueño todas; compra guarda `branch_id`.

## OPEN_DECISIONS (no resolver sin humano)

1. Proveedor SMS (costo real, API).
2. Valores iniciales: `refund_window_days`, vencimiento solicitudes, `UPLOAD_MAX_BYTES`, retención fotos.
3. Razón social: comprador o emisor.
4. `invoice_ref`: obligatorio u opcional por comercio.
5. Destino despliegue/demo (VPS, dominio, DNS).
6. Recorte hexagonal en Flutter (¿feature-based completo o simplificado?).
7. Interpretaciones encuesta: refresh web cookie `HttpOnly`; SMS mínimo + correo opcional.
8. Regex teléfono boliviano exacto (`+591` + 8 dígitos 6/7).
9. Motivo opcional en reembolso (código vs texto libre).
10. Sucursal "Principal" automática al crear comercio.
11. HTTPS Caddy puerto 8443 (validar en servidor real) vs subdominios.

## BLOCKERS

- **RLS + pruebas aislamiento**: deuda bloqueante pre-producción. Requiere: `ENABLE RLS` + políticas + tests en `infra/tests/rls/` por migración + CI job.
- **Proveedor SMS**: bloquea OTP real en producción (dev usa consola).
- **Valores config reembolso/fotos**: bloquean spec de reembolsos y `system_settings`.
- **Tasks.md desactualizado**: no refleja estado real; requiere sincronización o aclaración en `AGENTS.md`.

## SECURITY_RISKS (mitigados en código, pendientes en features)

- JWT: sin PII, claims fijos, `aud` por app, `pv` gate, `token_version` refresh.
- Contraseñas: Argon2id (pendiente implementación T031).
- Cookies web: nombres propios (`__Secure-rt_merchant`, `__Secure-rt_admin`), `HttpOnly; Secure; SameSite=Strict`, `X-Paseo-Client` + `Origin` validation en `/auth/refresh`.
- Logs: prohibido PII (middleware `_middleware.dart`).
- Uploads: solo vía API, validación contenido, sin EXIF, nombres aleatorios, `X-Content-Type-Options: nosniff`.
- Rate limit: pendiente T032.
- BD: `paseo_app` sin superusuario, sin BYPASSRLS, DDL denegado, GRANT mínimos.

## INFRASTRUCTURE_STATUS

| Componente | Estado | Notas |
|------------|--------|-------|
| Docker Compose base | ✅ | `paseo-aranjuez`, imágenes fijadas |
| Docker Compose dev | ✅ | Override DB loopback, semillas, vars dev |
| PostgreSQL 18 | ✅ | 18.6, PGDATA verificado, healthcheck |
| Flyway 13.9.0 | ✅ | `FLYWAY_CLEAN_DISABLED`, validación nombres |
| Roles BD | ✅ | 4 roles, `paseo_app` NOBYPASSRLS verificado |
| Migraciones V001/V002 | ✅ | Aplicadas, validadas, inmutables en CI |
| Semilla dev | ✅ | `R__seed_dev.sql` con override dev |
| API Dockerfile | ✅ | Multi-stage, healthcheck, non-root, read-only |
| Caddy | ✅ | 2.11.6, 443/8443, proxy, builds web separados |
| Backup | ✅ | `paseo_backup` BYPASSRLS, `uploads` incluido |
| CI GitHub Actions | ✅ | 5 jobs, migraciones desde cero, inmutabilidad |
| `.env.example` | ✅ | Plantilla completa, `.env` en `.gitignore` |

## AGENT_SYSTEM_STATUS

- `.specify/` + templates: ✅ Constitución → AGENTS.md, templates referencian AGENTS.md.
- `CLAUDE.md`: ✅ `@AGENTS.md`.
- CI gates: ✅ Formato, análisis, tests, OpenAPI, migraciones, RLS hook, inmutabilidad.
- MCP DB: ⚠️ Pendiente configurar read-only local para agentes.
- Architecture checker: ⚠️ Pendiente herramienta automatizada (TDD + CI cubre parcial).

## EXECUTION_ORDER (actualizado)

1. GATE 0: Audit actualizado (ESTE DOCUMENTO) — **DONE**.
2. GATE 1: Contradicciones resueltas — **DONE** (RLS supersedido, Mailpit eliminado, versiones fijadas).
3. GATE 2: Spec 001 aprobada — **DONE** (spec.md + plan.md + tasks.md existen).
4. GATE 3: Plan 001 aprobado — **DONE** (plan.md existe).
5. GATE 4: OpenAPI baseline válido — **DONE** (health + 8 auth, redocly 0 errores).
6. GATE 5: Arquitectura válida — **DOCUMENTED + VERIFIED** (hexagonal respetada en código).
7. GATE 6: Migraciones limpias — **VERIFIED** (V001/V002 desde cero, validate, roles/grants).
8. GATE 7: RLS tests — **BLOCKED** (deuda MVP sin RLS).
9. **PENDIENTE**: Completar Identity (rutas, Argon2id, SMTP, rate-limit, worker) — Tasks 2-7 del plan.
10. **PENDIENTE**: Flutter web entry points — Task 8 del plan.
11. **PENDIENTE**: Validación completa pipeline — Task 9 del plan.
12. GATE 12: CI green — **PENDING** (requiere Tasks 2-9 completados).
13. GATE 13: Human review — **REQUIRED** antes de features de negocio.

## NEXT_GATES

- GATE 8 — domain tests pass: ✅ (existentes en `test/domain/identity/`).
- GATE 9 — backend tests pass: ⏳ (requiere routes + adapters/in implementados).
- GATE 10 — Flutter tests pass: ⏳ (requiere entry points + features).
- GATE 11 — API integration pass: ⏳ (requiere DB 5433 + routes).
- GATE 12 — security review pass: ⏳ (post-Identity completion).
- GATE 13 — CI green: ⏳ (post-Tasks 2-9).
- GATE 14 — human approval: ⏳ (post-Foundation complete).

---

**Próximos pasos inmediatos (Plan 2026-10-03):**
1. Argon2idPasswordHasher + tests
2. SmtpEmailSender + Console senders + tests
3. Rate-limit middleware + tests
4. 8 Auth routes + tests (T013–T021)
5. Worker CleanupExpiredCredentials + tests
6. Flutter main_merchant_web.dart + main_admin_web.dart
7. Full verification pipeline (format, analyze, unit, openapi, migrations from zero, integration, flutter builds)

---

## FEATURE 003 — PANEL DEL ESTABLECIMIENTO (04/10/2026)

Estado: **IMPLEMENTED + VERIFIED** en rama `feat/003-panel-establecimiento`
(PR #3 → `main`; sin merge). HU-10 / HU-11 / HU-13 / HUT-02.

IMPLEMENTED:
- **BD**: `V004` (comercios/sucursales/personal), `V005` (reglas de conversion
  versionadas), `V006` (`purchases`, `points_ledger`, `customer_balances` +
  trigger de saldo); `GRANT` minimos y `REVOKE UPDATE,DELETE,TRUNCATE` en
  `points_ledger`, `customer_balances`, `purchases`, `audit_log`. Seed `R__seed_dev`
  extendido con comercio/sucursal/staff/cliente/regla GLOBAL fijos.
- **API**: dominio loyalty (`PointsCalculator`, `RuleResolver`, ticket HMAC
  SHA-256); casos de uso merchant (`IdentifyCustomer`, `PreviewPurchase`,
  `RegisterPurchase`, `ListMovements`); adapters Postgres; 4 rutas `/merchant/*`
  (identify, preview, purchases, movements) con RFC 9457.
- **Contrato**: 4 endpoints en `docs/openapi.yaml` **antes** de las rutas.
- **`packages/paseo_shared`**: DTOs `src/merchant/dto.dart`.
- **Flutter**: `lib/features/merchant/{data,application,presentation}` +
  `main_merchant_web.dart` (web comercio) + scaffolding `apps/mobile/web/`
  (index.html, manifest, iconos) para los builds merchant/admin. Resuelve el
  item de MISSING "Flutter web entry points" para comercio (linea 68); el
  admin sigue stub.

VERIFIED (04/10/2026):
- `fvm dart format --set-exit-if-changed .` → 0 cambios.
- `fvm dart analyze --fatal-warnings` → EXIT 0 (606 infos no fatales).
- `fvm flutter analyze` → 0 issues; `fvm flutter test` → 6 verdes.
- API unit (`test/domain test/application test/routes`) → 223 verdes.
- API integration con rol real `paseo_app` (127.0.0.1:55432) → 22 verdes
  (incluye HUT-02 p95<500ms, idempotencia, aislamiento, grants).
- Migraciones desde cero: `V001`–`V006` + `R__seed_dev`; `migrate info` en 006.
- OpenAPI: `redocly lint` valido (4 warnings preexistentes).
- Web build: `flutter build web -t lib/main_merchant_web.dart` → OK.
- **SC-001 – SC-010** cubiertos (una prueba por HU, p95/HUT-02, calculo
  compartido, idempotencia, aislamiento app-layer, contrato antes, sin PII,
  grants, web-merchant muestra el mismo valor, gates verdes).
- Pendiente (no bloquea 003): RLS (deuda, regla 2.7), proveedor SMS, merge del PR.