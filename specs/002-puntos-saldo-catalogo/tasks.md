---
description: "Task list: feature 002 puntos saldo y catálogo"
---

# Tasks: Motor de puntos, saldo e historial del cliente (002-puntos-saldo-catalogo)

**Input**: `specs/002-puntos-saldo-catalogo/spec.md` (aprobada), `specs/002-puntos-saldo-catalogo/plan.md` (aprobado)
**Prerequisites**: spec + plan aprobados; feature 001 (identidad) implementada en la rama base.
**Authority**: `AGENTS.md`; las `OPEN_DECISIONS` no se resuelven sin aprobación humana explícita.

Verificación global tras cada tarea: `fvm dart format --set-exit-if-changed . && fvm dart analyze --fatal-warnings` y los tests del alcance. Migraciones: `docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d --wait db && docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml run --rm migrate && … run --rm migrate validate`.

## Phase 1: Contrato (F1) — bloquea todo lo demás

- [x] T001 [A0] `docs/openapi.yaml`: añadir tags `points`/`catalog`, `GET /me/balance`, `GET /me/movements` (CursorPage, limit 20/máx 50, `balanceAfter` por ítem), `GET /rewards` (`available=false` cuando stock=0), `GET /establishments` (sin campos administrativos), schemas `Balance`/`Movement`/`RewardSummary`/`EstablishmentSummary`, código `PHONE_NOT_VERIFIED` en la lista del `Problem`. Seguridad: `bearerAuth` (rol `customer`) en los 4. **Sin rutas aún.** Verificar: `npx --yes @redocly/cli@2 lint docs/openapi.yaml` → 0 errores.

## Phase 2: Datos (F2) — bloquea motor y backend

- [x] T002 [D1] `infra/migrations/V004__comercios.sql`: `establishments`, `branches` (esquema `app`), `GRANT SELECT` a `paseo_app`.
- [x] T003 [D2] `infra/migrations/V005__puntos_ledger.sql`: `purchases` (mínima, `idempotency_key` único), `points_ledger` (append-only, `reverses_ledger_id` único parcial, `balance_after`), `customer_balances` (`CHECK (balance>=0)`), trigger `SECURITY DEFINER` (upsert + `balance_after`, `search_path` fijado), `points_idempotency ((scope,key) PK, request_hash, response jsonb)`, índices de cursor, `REVOKE UPDATE, DELETE, TRUNCATE ON points_ledger FROM paseo_app`, `customer_balances` sin `UPDATE` para `paseo_app`.
- [x] T004 [D3] `infra/migrations/V006__recompensas.sql`: `rewards` (status, tipo, costo entero, stock, vigencia). `GRANT SELECT` a `paseo_app`.
- [x] T005 [D4] `infra/seed/R__seed_dev.sql`: 2 establecimientos con sucursales, 3 recompensas (PERCENT/FIXED/GIFT) + 1 sin stock + 1 vencida, y movimientos de demo para el cliente seed (idempotente con `ON CONFLICT`). Corregir el comentario obsoleto ("V002 queda BLOCKED").
- [x] T006 [D5] Migraciones desde cero + `validate` en verde; tabla de verificación manual con `paseo_app`: `UPDATE/DELETE` sobre ledger → permiso denegado.

## Phase 3: Dominio y contrato interno (F3)

- [x] T007 [P] [DO1] Tests de dominio `test/domain/points/`: comandos `CreditCommand`/`DebitCommand` (puntos enteros > 0, reference presente), `MovementType` (5 tipos), mapeo `23514 → INSUFFICIENT_POINTS`, conflicto de idempotencia → `CONFLICT`, cursor encode/decode `(occurred_at, ledger_id)`.
- [x] T008 [P] [DO2] Implementar `lib/domain/points/` hasta verde. Dart puro, sin imports.
- [x] T009 [P] [S1] `packages/paseo_shared/lib/src/points/` y `catalog/`: DTOs de los 4 GET + `ApiErrorCode` nuevos (`PHONE_NOT_VERIFIED`, uso futuro de `INSUFFICIENT_POINTS`). Sin lógica de dominio. Tests de serialización.

## Phase 4: Motor transaccional (F4) — HUT-04

- [x] T010 [AP1] Puertos `lib/application/points/ports.dart` + casos de uso `CreditPoints`/`DebitPoints` (transacción: reserva idempotencia → insert ledger (+ compra en crédito) → trigger; `audit_log`; `pv=false` → rechazo). Tests con mocks (unitarias).
- [x] T011 [AP2] Casos de uso de lectura: `GetBalance`, `GetMovements` (cursor), `ListRewards`, `ListEstablishments`. Tests con mocks.
- [x] T012 [AD1] Adapters Postgres: `PostgresPointsLedgerRepository` (con `TransactionRunner` existente y mapping de `pg_errors`), `PostgresPointsIdempotencyRepository`, `PostgresBalanceRepository`, `PostgresMovementsRepository`, `PostgresRewardsRepository`, `PostgresEstablishmentsRepository`. Tests de integración (BD 5433): escenarios 1–10 y 16 de la asignación (crédito, doble crédito, débito, débito > saldo, carrera de dos débitos, dos acreditaciones con misma referencia, fallo a mitad de transacción, permisos del ledger, `pv=false`).

## Phase 5: Rutas del cliente (F5, F6)

- [x] T013 [R1] Middleware `adapters/in/middleware/authz.dart`: JWT válido + `role=customer` (y `pv=true` para `/me/*`) → 401/403 con códigos estables. Tests del middleware.
- [x] T014 [R2] `routes/me/balance.dart` y `routes/me/movements.dart` (DTO → caso de uso → RFC 9457; cursor y limit parseados). Tests de rutas: 200, empty, 401, 403 `PHONE_NOT_VERIFIED`, aislamiento A≠B (integración).
- [x] T015 [R3] `routes/rewards.dart` y `routes/establishments.dart` (solo `ACTIVE`+vigentes; `available`; sin campos admin). Tests de rutas + integración con seeds.

## Phase 6: Frontend móvil (F7) — paralelizable desde T001 [P]

- [x] T016 [P] [U1] `lib/core/api_client.dart`: cliente `http` con `Authorization: Bearer` (token vía `--dart-define=PASEO_TOKEN`), base URL por `--dart-define=PASEO_API_BASE` (default `http://localhost:8080/api/v1`), parseo de `problem+json` a excepción tipada con `code`. Versión exacta de `http` fijada con `dart pub add http` (nunca de memoria, §14).
- [x] T017 [P] [U2] `features/wallet/`: pantalla Saldo + pantalla Historial (scroll infinito con cursor) — data/application/presentation; estados loading/success/empty/error.
- [x] T018 [P] [U3] `features/catalog/`: pantalla Catálogo (con `available=false` visible) + pantalla Establecimientos — estados completos.
- [~] T019 [P] [U4] Widget tests de las 4 pantallas con cliente HTTP falso del mismo contrato (sin acoplar a tablas); `fvm flutter test` verde.

## Phase 7: Integración y hardening (F8)

[x] T020 [C1] `specs/002-puntos-saldo-catalogo/contracts/points-engine.md`: contrato interno `credit`/`debit` (request/response/errores/validación/idempotencia/autorización/estados) para Persona 3 y 5. `contracts/api-extract.md`: extracto de los 4 GET.
- [~] T021 [Q1] Pruebas de concurrencia y regresión finales de integración (los 16 escenarios completos); revisión `persona2-domain-reviewer` (atomicidad, idempotencia, carreras) e `persona2-integration-reviewer` (sin acoplamiento a tablas internas desde fuera del módulo).

## Phase N: Cross-Cutting Verification (F9)

- [~] T090 `fvm dart format --set-exit-if-changed . && fvm dart analyze --fatal-warnings` + tests apps/api (unit + integration) + `packages/paseo_shared` + `apps/mobile` en verde.
- [~] T091 Migraciones desde cero + `migrate validate` + pruebas de permisos del ledger en CI-equivalente local.
- [~] T092 Revisión de seguridad: logs sin PII, `/me/*` solo desde JWT, campos admin ausentes, permisos mínimos; `github_run_secret_scanning` sobre el diff.
- [~] T093 Actualizar `docs/agent-audit.md` y `AGENTS.md` §1.1; gate §16 completo; `/speckit-analyze` sin inconsistencias críticas; `/speckit-converge`.

## Dependencies & Execution Order

- T001 bloquea todo (contrato primero, regla 2.5). T002–T006 preceden a T010–T015.
- T016–T019 (móvil) son `[P]` desde T001: no comparten archivos con el backend (único contacto: `docs/openapi.yaml`, que solo toca T001).
- Tests primero (TDD) en T007/009/010/011/013/014/015.

## Notes

- Rutas finas: validación → un caso de uso → RFC 9457 (AGENTS.md §3). Cero reglas de negocio en rutas.
- El motor no calcula puntos: los recibe (`NO_APPLICABLE_RULE` vive en 003/004).
- Nadie fuera de `lib/*/points` importa los repositorios del módulo (contrato interno).
