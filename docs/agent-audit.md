# Agent Audit — Paseo Points

Fecha de auditoría: 04/10/2026
Estado: UPDATED (auditoría post-implementación de feature 002-puntos-saldo-catalogo). Código e infraestructura implementados y verificados.

## CURRENT_STATE

DOCUMENTED:
- `AGENTS.md` (actualizado 03/10/2026): reglas innegociables, arquitectura, endpoints, decisiones abiertas/cerradas. Constitución SDD.
- `INFRASTRUCTURE.md`: servicios, roles BD, Flyway, variables, CI/CD, backups, Caddy.
- `9-stack-tecnologico-paseo-points.md`: stack, arquitectura, ADR/roadmap, endpoints MVP, matriz pruebas, decisiones.
- `docs/openapi.yaml`: OpenAPI 3.1 — servidor `/api/v1`, `Problem` RFC 9457, `bearerAuth` con audiencias, `Idempotency-Key`, `MoneyCents`, `CursorPage`; `GET /health`, `GET /ready`, 8 endpoints auth, los 4 GET del cliente de 002 (`GET /me/balance`, `GET /me/movements`, `GET /rewards`, `GET /establishments`) con schemas `Balance`/`Movement`/`RewardSummary`/`EstablishmentSummary` y códigos `PHONE_NOT_VERIFIED`, `INSUFFICIENT_POINTS`, `CONFLICT`.
- `.specify/`: Spec Kit local — constitución, templates (spec/plan/tasks/checklist), `specs/README.md`.
- `specs/001-identidad/`: spec.md, plan.md, tasks.md (casillas no fiables como estado, ver nota en §CONTRADICTIONS), research.md.
- `specs/002-puntos-saldo-catalogo/`: spec.md, plan.md, tasks.md, data-model.md (aprobados 03–04/10/2026; rama `feat/002-puntos-saldo-catalogo`).
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
  - `V003`: `GRANT DELETE` sobre credenciales expirables para el job de limpieza (`CleanupExpiredCredentials`).
  - `V004__comercios.sql`: `establishments` (con `max_purchase_cents`/`compliance_status`, **no expuestos al cliente**) y `branches`; `GRANT SELECT` a `paseo_app`.
  - `V005__puntos_ledger.sql`: `purchases` (soporte del `CREDIT`, `idempotency_key` UNIQUE, `(establishment_id, invoice_ref)` único parcial), `points_ledger` append-only (`reverses_ledger_id` único parcial, `balance_after`, `idempotency_key` UNIQUE, índice de cursor `(customer_id, occurred_at DESC, id DESC)`), `customer_balances` (`CHECK (balance >= 0)`, sin `UPDATE` para `paseo_app`), trigger `SECURITY DEFINER` (`search_path` fijado, upsert serializado por bloqueo de fila) y `points_idempotency` (`(scope,key)` PK, `request_hash`, `response` jsonb). `REVOKE UPDATE/DELETE/TRUNCATE` del ledger para `paseo_app`.
  - `V006__recompensas.sql`: `rewards` (status `DRAFT/PENDING/ACTIVE/PAUSED/RETIRED`, `reward_type` `PERCENT/FIXED/GIFT`, `cost_points` entero, stock, vigencia); `GRANT SELECT` a `paseo_app`.
  - Seeds dev idempotentes en `R__seed_dev.sql` (2 establecimientos con sucursales, recompensas PERCENT/FIXED/GIFT + sin stock + vencida, movimientos demo del cliente seed).
- Semilla dev: `infra/seed/R__seed_dev.sql` (solo con override dev).
- CI: `.github/workflows/ci.yml` — jobs `dart` (format/analyze/unit tests excluyendo integration), `openapi` (redocly), `migrations` (DB desde cero + Flyway + chequeos roles/extensiones/DDL denegado + RLS tests hook), `integration` (DB 5433 + `dart test test/integration`), `migration-immutability` (rechaza M/D en `infra/migrations/` vs `main`).
- Backend `apps/api`:
  - Hexagonal: `lib/domain/identity/*`, `lib/application/identity/{ports,use_cases/*}`, `lib/adapters/out/postgres/*` (repositorios, transaction runner, audit log writer).
  - **Identidad completa** (HU-01–HU-05): `routes/auth/*` (register, phone/verify, phone/send-otp, verify-email, login, refresh, logout, password/forgot, password/reset), `adapters/in` (DI, mapeo RFC 9457, rate-limit), `Argon2idPasswordHasher` (PHC, Isolate), `SmtpEmailSender` + `ConsoleOtpSender`/`ConsoleEmailSender`.
  - **Motor de puntos (002)**: `lib/domain/points/` (`CreditCommand`/`DebitCommand`, `MovementType` ×5, cursor opaco `(occurred_at, ledger_id)`, errores de dominio); `lib/application/points/` (`CreditPoints`/`DebitPoints` con idempotencia `(scope,key)` + replay + `CONFLICT` por payload distinto, `GetBalance`/`GetMovements`/`ListRewards`/`ListEstablishments`, puertos); adaptadores Postgres (`postgres_points_ledger_repository`, `postgres_points_idempotency_repository`, `postgres_purchase_repository`, `postgres_balance_repository`, `postgres_movements_repository`, `postgres_rewards_repository`, `postgres_establishments_repository`); escritura siempre transaccional (idempotencia + ledger [+ compra] + `audit_log`; `pv=false` rechazado con `PHONE_NOT_VERIFIED`).
  - Middleware de autorización `adapters/in/middleware/authz.dart` (JWT válido vía `JwtTokenVerifier`, `role=customer`, `pv=true`, `aud=paseo-mobile`) aplicado a `routes/me/*`, `/rewards` y `/establishments`.
  - Rutas: `routes/health.dart`, `routes/ready.dart`, `routes/_middleware.dart` (RFC 9457, correlation_id, logging sin PII), `routes/me/balance.dart`, `routes/me/movements.dart` (cursor + limit), `routes/rewards.dart`, `routes/establishments.dart`.
  - Binarios: `bin/server.dart`, `bin/worker.dart` (job horario `CleanupExpiredCredentials`), `bin/healthcheck.dart`.
  - Tests: `test/domain/{identity,points}/*`, `test/application/{identity,points}/*`, `test/routes/*`, `test/integration/*` (incluye `ledger_trigger_test.dart` — invariantes del trigger, carreras y permisos — y `points_repositories_test.dart` — crédito/débito, replay, CONFLICT, 23514, doble débito concurrente, rollback, `pv=false`, lecturas).
- `packages/paseo_shared`: `lib/src/auth/*` (DTOs 8 endpoints), `lib/src/points/*` y `lib/src/catalog/*` (DTOs de los 4 GET de 002), `lib/src/errors/*` (`ApiErrorCode` con los códigos nuevos); tests de serialización.
- Flutter `apps/mobile`: puntos de entrada `lib/main.dart`, `main_merchant_web.dart`, `main_admin_web.dart`, `app.dart` (placeholders); `lib/core/api_client.dart` (cliente `http` con Bearer vía `--dart-define=PASEO_TOKEN` y base por `--dart-define=PASEO_API_BASE`, parseo `problem+json` a excepción tipada con `code`); `lib/features/wallet/` (saldo + historial con scroll infinito por cursor) y `lib/features/catalog/` (recompensas + establecimientos) con estados loading/success/empty/error y widget tests con cliente HTTP falso del contrato.

TESTED:
- Unitarias: domain + application + routes (excluye integration) — pasan en CI, ahora con `test/domain/points/*` y `test/application/points/*`.
- Integración: `test/integration/*` contra BD dev en loopback:5433 (requiere `DB_DEV_PORT=5433` en `infra/.env` o shell), incluyendo el motor de puntos (crédito/débito, replay de idempotencia, `CONFLICT` por payload distinto, `23514 → INSUFFICIENT_POINTS`, carreras concurrentes de débitos y créditos, rollback sin rastro, `pv=false`) y las invariantes del trigger (`balance_after` coherente, permisos del ledger, saldo solo-lectura para `paseo_app`).
- Serialización de DTOs nuevos de 002 en `packages/paseo_shared` (points/catalog).
- Widget tests de las pantallas de 002 en `apps/mobile` con cliente HTTP falso del contrato.
- OpenAPI: `redocly lint docs/openapi.yaml` — 0 errores (con los 4 GET de 002).
- Migraciones: `flyway migrate` + `validate` desde BD vacía hasta V006 — éxito (verified 04/10/2026).
- Roles/permisos: verificados en CI job `migrations` (3 roles, `paseo_app` sin BYPASSRLS, 2 extensiones, DDL denegado) + tests de integración de permisos del ledger y de `customer_balances`.

VERIFIED:
- Rama de trabajo: `feat/002-puntos-saldo-catalogo` (trabajo de 002 sin commit en el árbol al 04/10/2026).
- `docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d --wait db` → DB healthy.
- `flyway info` → V001–V006 Success; `migrate validate` → verde (04/10/2026).
- `caddy validate` → OK.
- `fvm dart format --set-exit-if-changed .` → sin cambios.
- `fvm dart analyze --fatal-warnings` → sin errores.
- `fvm dart test` (packages) + `fvm dart test test/domain test/application test/routes` (api unit) → verde.
- OpenAPI endpoints coinciden con `AGENTS.md` §6/§8 y con `specs/002-puntos-saldo-catalogo/spec.md` (FR-001..FR-004).

## MISSING

- **Specs features 003+**: existen 001-identidad y 002-puntos-saldo-catalogo; faltan compras (003), catálogo admin (004) y canjes (005).
- **RLS + isolation tests**: deuda bloqueante pre-producción (MVP sin RLS, decisión 03/10/2026).
- **Proveedor SMS**: decisión abierta (solo OTP por consola en dev).
- **Valores iniciales config**: `refund_window_days`, retención fotos, tamaños, vencimientos — por decidir.

## CONTRADICTIONS

- **Tasks.md vs código real**: varias tareas de 001 y 002 avanzaron sin marcar sus casillas (y viceversa no ocurre: nada marcado sin código). **Regla**: no usar checkboxes como estado; verificar archivos.
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
- Contraseñas: Argon2id implementado (`Argon2idPasswordHasher`, PHC, Isolate).
- Cookies web: nombres propios (`__Secure-rt_merchant`, `__Secure-rt_admin`), `HttpOnly; Secure; SameSite=Strict`, `X-Paseo-Client` + `Origin` validation en `/auth/refresh`.
- Logs: prohibido PII (middleware `_middleware.dart`).
- Uploads: solo vía API, validación contenido, sin EXIF, nombres aleatorios, `X-Content-Type-Options: nosniff`.
- Rate limit: implementado en `routes/auth/*` (429 `RATE_LIMITED`).
- Puntos (002): identidad siempre desde el JWT (`/me/*` no aceptan identificadores), ledger append-only por permisos, saldo solo-escrito por el trigger, motor auditado (`audit_log` sin PII) e idempotente.
- BD: `paseo_app` sin superusuario, sin BYPASSRLS, DDL denegado, GRANT mínimos.

## INFRASTRUCTURE_STATUS

| Componente | Estado | Notas |
|------------|--------|-------|
| Docker Compose base | ✅ | `paseo-aranjuez`, imágenes fijadas |
| Docker Compose dev | ✅ | Override DB loopback, semillas, vars dev |
| PostgreSQL 18 | ✅ | 18.6, PGDATA verificado, healthcheck |
| Flyway 13.9.0 | ✅ | `FLYWAY_CLEAN_DISABLED`, validación nombres |
| Roles BD | ✅ | 4 roles, `paseo_app` NOBYPASSRLS verificado |
| Migraciones V001–V006 | ✅ | Aplicadas, validadas, inmutables en CI |
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
9. Identity completa (rutas, Argon2id, SMTP, rate-limit, worker) — **DONE**.
10. Flutter web entry points — **DONE** (placeholders presentes; contenido de producto pendiente por features).
11. Feature 002 (motor de puntos, saldo, catálogo) implementada en rama — **DONE** (sin commit al 04/10/2026).
12. GATE 12: CI green — **PENDING** (al abrir el PR de `feat/002-puntos-saldo-catalogo`).
13. GATE 13: Human review — **REQUIRED** antes de features de negocio.

## NEXT_GATES

- GATE 8 — domain tests pass: ✅ (existentes en `test/domain/identity/`).
- GATE 9 — backend tests pass: ✅ (routes + adapters implementados; unitarias en verde).
- GATE 10 — Flutter tests pass: ✅ (widget tests de las pantallas de 002).
- GATE 11 — API integration pass: ✅ (DB 5433; identidad + motor de puntos + invariantes del trigger).
- GATE 12 — security review pass: ⏳ (post-Identity completion).
- GATE 13 — CI green: ⏳ (post-Tasks 2-9).
- GATE 14 — human approval: ⏳ (post-Foundation complete).

---

**Próximos pasos inmediatos (actualizado 04/10/2026):**
1. Commit y PR de la rama `feat/002-puntos-saldo-catalogo` (trabajo en el árbol sin commit).
2. Specs de las features 003+ (compras, catálogo admin, canjes) con Spec Kit.
3. Deuda bloqueante pre-producción: RLS + pruebas de aislamiento (§BLOCKERS).