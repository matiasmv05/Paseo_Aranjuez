# Motor de puntos, saldo e historial del cliente (002) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: `superpowers:subagent-driven-development` (recomendado) o `superpowers:executing-plans`. Un agente por fase; nunca dos agentes sobre los mismos archivos (AGENTS.md §12). Los pasos usan checkbox (`- [ ]`).

**Branch**: `feat/002-puntos-saldo-catalogo` | **Date**: 2026-10-03 | **Spec**: `specs/002-puntos-saldo-catalogo/spec.md` (**aprobada**; decisiones de `/speckit-clarify` 2026-10-03 ya incorporadas)

**Input**: Feature specification `specs/002-puntos-saldo-catalogo/spec.md` (HU-04, HU-05, HU-06, HU-09, HUT-04)

**Authority**: `AGENTS.md` y `.specify/memory/constitution.md` gobiernan este plan. No resuelve `OPEN_DECISIONS` de §15.

## Summary

Crear el módulo de puntos como única fuente de verdad del estado del cliente: `points_ledger` append-only + `customer_balances` derivado por trigger `SECURITY DEFINER` (saldo nunca negativo, `balance_after` por fila, bloqueo por cliente sin `FOR UPDATE`), motor transaccional `PointsEngine.credit/debit` como contrato interno para 003/005 (con tabla de idempotencia propia), cuatro endpoints de lectura del cliente (`/me/balance`, `/me/movements`, `/rewards`, `/establishments`) y cuatro pantallas móviles con estados loading/empty/error. El contrato REST se actualiza en `docs/openapi.yaml` **antes** de cualquier ruta.

## Technical Context

**Language/Version**: Dart 3.13 / Flutter 3.47.6 vía FVM (única fuente: `.fvmrc`).
**Primary Dependencies**:
- `apps/api` (todas ya presentes): `dart_frog` 1.2.6, `postgres` 3.5.x, `uuid`, `crypto`, `paseo_shared`. **Sin dependencias nuevas en la API.**
- `apps/mobile`: `http` (oficial dart.dev; versión exacta se fija con `dart pub add` al implementar — AGENTS.md §14 prohíbe fijar versiones de memoria). Estado: `ChangeNotifier`/widgetes reactivos nativos; **no** se introduce bloc/riverpod (no hay convención previa y el scope es 4 pantallas).
**Storage**: PostgreSQL 18 + Flyway; nuevas migraciones V004/V005/V006 (inmutables; la numeración prevista del doc de stack se desplazó porque V003 quedó ocupada por `cleanup_grants`).
**Testing**: `dart test` unitario sin BD (`test/domain|application|routes|adapters`); integración contra PostgreSQL real en `127.0.0.1:5433` con rol `paseo_app` (`test/integration`, helpers `uniqueEmail/uniquePhone/newId` de 001); Flutter `flutter test` (widgets/estado). Concurrencia: conexiones reales en paralelo, nunca mocks.
**Target Platform**: `api` + `mobile` (app cliente). `worker`, `web-merchant`, `web-admin`: no afectados.
**Constraints**: servidor autoritativo; puntos enteros; sin RLS en MVP (aislamiento por autorización de casos de uso + pruebas); escrituras críticas con idempotencia + `audit_log`; rutas finas RFC 9457; `cid` siempre desde el JWT.
**Scale/Scope**: 4 endpoints de lectura, 1 motor transaccional interno, 4 pantallas, 3 tablas + 1 tabla de idempotencia + 1 trigger, seeds de demo.

## Constitution Check

*GATE: debe pasar antes de implementar y otra vez antes de revisión.*

- [x] `docs/openapi.yaml` actualizado antes que cualquier ruta (T-A0 precede a T-R*).
- [x] Backend preserva `adapters → application → domain`; el motor vive en `domain/points` + `application/points`; nadie fuera del módulo importa sus repositorios.
- [x] Sin reglas de negocio en rutas ni en Flutter (`data` solo habla HTTP contra el contrato).
- [x] Tablas nuevas con `GRANT` mínimos; **RLS diferida por decisión del equipo 03/10/2026 (SUPERSEDIDA, regla 2.7)**; en su lugar: pruebas de integración de autorización (cliente A ≠ cliente B) y de permisos (`REVOKE` del ledger).
- [x] Escrituras críticas: tabla de idempotencia del motor `(scope, key)` única + `audit_log` en cada escritura de puntos.
- [x] JWT sin datos personales; los `/me/*` derivan `cid`/`pv` del JWT verificado.
- [x] Sin uploads en esta feature.
- [x] `OPEN_DECISIONS` intactas; ninguna decisión §15 se resuelve aquí.

## Decisiones de diseño (dentro del plan, no de la spec)

1. **Saldo por trigger `SECURITY DEFINER`**: `BEFORE INSERT` sobre `points_ledger` ejecuta `INSERT INTO customer_balances … ON CONFLICT (customer_id) DO UPDATE SET balance = balance + NEW.delta RETURNING balance INTO NEW.balance_after`. El `ON CONFLICT` toma el bloqueo de fila del cliente → serializa carreras sin `SELECT … FOR UPDATE` (prohibido por §9). Si el saldo resultante viola `CHECK (balance >= 0)` → `23514` → aborta toda la transacción. La función la posee `paseo_owner` con `search_path` fijado; `paseo_app` tiene solo `SELECT` en `customer_balances` y `INSERT/SELECT` en `points_ledger` (`REVOKE UPDATE, DELETE, TRUNCATE`).
2. **Idempotencia del motor**: `points_idempotency(scope, key, request_hash, response, ledger_id, created_at)` con PK `(scope, key)`. Transacción: insertar reserva `ON CONFLICT DO NOTHING RETURNING`; si ya existe → mismo `request_hash` = replay de la respuesta guardada; hash distinto = 409 `CONFLICT`.
3. **`purchases` mínima en 002** (soporte del ledger): sin `rule_id`/`rule_snapshot` obligatorios (nulos hasta 004), sin `seller_user_id` obligatorio (lo completa 003). El motor de crédito inserta compra + `CREDIT` en la misma transacción cuando el alcance lo pida; el endpoint `POST /merchant/purchases` es de 003.
4. **Middleware de autenticación de customer**: 001 solo tenía rutas públicas de auth; esta feature introduce el primer guardián de rol (`role=customer`, `pv`, `aud`) en `routes/_middleware.dart`/`adapters/in/middleware/`. Reutiliza el verificador JWT existente de `adapters/out/auth`.
5. **Frontend móvil**: cliente HTTP propio (`http`) con token inyectado por `--dart-define=PASEO_TOKEN=…` (hasta que exista login móvil, que pertenece a la UI de 001, fuera de alcance); las vistas nunca hablan SQL ni conocen tablas. 4 pantallas bajo `features/wallet/` (saldo+historial) y `features/catalog/` (recompensas+establecimientos) con estados loading/success/empty/error.

## Project Structure

### Documentation (this feature)

```text
specs/002-puntos-saldo-catalogo/
├── spec.md · plan.md · tasks.md
├── data-model.md          # entidades e invariantes (V004–V006)
└── contracts/
    ├── points-engine.md   # contrato interno credit/debit para 003/005
    └── api-extract.md     # extracto de los 4 GET del openapi
```

### Source Code (repository root)

```text
apps/api/
├── routes/
│   ├── me/{balance,movements}.dart          # HU-04, HU-05 (protegidas customer)
│   └── {rewards,establishments}.dart        # HU-06, HU-09 (protegidas customer)
├── lib/
│   ├── domain/points/                       # MovementType, LedgerMovement, Balance, errores
│   ├── application/points/{ports,use_cases} # PointsEngine(credit/debit), GetBalance, GetMovements, ListRewards, ListEstablishments
│   └── adapters/
│       ├── in/middleware/authz.dart         # guarda de rol/pv (1ª ruta protegida no-auth del repo)
│       └── out/postgres/                    # postgres_points_ledger_*, postgres_balance_*, postgres_rewards_*, postgres_establishments_*
apps/mobile/lib/
├── core/api_client.dart                     # http + token inyectable + Problem parsing
└── features/
    ├── wallet/{presentation,application,data}     # saldo + historial
    └── catalog/{presentation,application,data}    # recompensas + establecimientos
packages/paseo_shared/lib/src/
└── points/ · catalog/                       # DTOs + ApiErrorCode nuevos (solo contrato)
infra/
├── migrations/V004__comercios.sql · V005__puntos_ledger.sql · V006__recompensas.sql
└── seed/R__seed_dev.sql                     # seeds demo (establecimientos, sucursales, recompensas, movimientos)
```

**Structure Decision**: tal cual arriba; no se toca `worker` ni las webs.

## Data / Contract / Infrastructure Impact

- **API contract** (`docs/openapi.yaml`, antes de rutas): `GET /me/balance` (200 `{balancePoints}`), `GET /me/movements` (`CursorPage<Movement>`, cursor `(occurred_at, ledger_id)`, limit 20/máx 50, `balanceAfter` por ítem), `GET /rewards` (ACTIVE+vigentes; `stock=0` → `available=false`), `GET /establishments` (nombre, categoría, sucursales con dirección). Schemas: `Balance`, `Movement`, `RewardSummary`, `EstablishmentSummary`. Códigos nuevos normalizados: `PHONE_NOT_VERIFIED` (403), `INSUFFICIENT_POINTS` (409, usado a futuro por 005), `CONFLICT` (409 idempotencia). Todo con `bearerAuth` rol `customer`.
- **Database**:
  - `V004__comercios.sql`: `establishments` (nombre, categoría, baja lógica, `max_purchase_cents`, `compliance_status` — ambos sin exponer), `branches`. `GRANT SELECT` a `paseo_app`.
  - `V005__puntos_ledger.sql`: `purchases` (mínima, idempotency único), `points_ledger` (+ `reverses_ledger_id` único parcial, `balance_after`), `customer_balances` (`CHECK (balance>=0)`), trigger `SECURITY DEFINER`, `points_idempotency`, índices `(customer_id, occurred_at, id)` para cursor, `REVOKE/GRANT` finales.
  - `V006__recompensas.sql`: `rewards` (statuses, costo puntos entero, stock, vigencia). `GRANT SELECT` a `paseo_app`.
  - Seeds demo en `R__seed_dev.sql` (idempotentes con `ON CONFLICT`) + corrección de su comentario obsoleto ("V002 queda BLOCKED" es historia antigua).
- **Infrastructure**: sin cambios de Compose/Caddy/variables de entorno.
- **Security**: primer guardián de autorización por rol del repo (middleware `authz`); pruebas de aislamiento aplicativo (A no lee a B) sustituyen temporalmente a las pruebas RLS (deuda bloqueante documentada).
- **Notifications/jobs**: ninguna (`worker` sin cambios).

## Test Strategy

Mapeo de los 16 escenarios obligatorios de la asignación:

- **Domain (unitarias por tabla, sin BD)**: validación de comandos (puntos enteros > 0, referencia presente), mapeo de errores (`23514 → INSUFFICIENT_POINTS`, conflicto de idempotencia → `CONFLICT`), regla `pv=false` rechaza acreditación, cursor encode/decode.
- **Integration (PostgreSQL real, `paseo_app`)**: saldo 0/sin movimientos/muchos movimientos; acreditación OK; acreditación duplicada (misma key) sin segundo `CREDIT`; débito OK; débito > saldo → `INSUFFICIENT_POINTS`; **dos débitos concurrentes** (conexiones reales simultáneas) → solo uno gana; **dos acreditaciones concurrentes con la misma referencia** → una sola fila; fallo inyectado a mitad de transacción → cero rastro; `UPDATE/DELETE/TRUNCATE` sobre ledger → error de permisos; cliente A no lee saldo/movimientos de B (a nivel ruta con dos JWT).
- **API tests**: contrato RFC 9457 (422/401/403/409/500 con `code` estable), paginación por cursor sin repetidos ni omitidos, `pv=false` → 403 en `/me/*`, campos administrativos ausentes de `rewards`/`establishments`.
- **Flutter tests**: estados loading/success/empty/error de las 4 pantallas con cliente HTTP falso del mismo contrato; sin pruebas acopladas a esquema.
- **Verification commands**: `fvm dart format --set-exit-if-changed .`; `fvm dart analyze --fatal-warnings`; `fvm dart test test/domain test/application test/routes test/adapters` (apps/api); `cd apps/api && fvm dart test test/integration` (BD dev en 5433); `fvm flutter test` (apps/mobile); `npx --yes @redocly/cli@2 lint docs/openapi.yaml`; migraciones desde cero (`migrate` + `validate`).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| `purchases` en 002 aunque 003 la "posee" | El `CREDIT` del ledger necesita la entidad origen e idempotencia por compra desde ya | Crearla en 003 dejaría al motor sin integración real demostrable y obligaría a rehacer V005 |
| Tabla de idempotencia propia del motor | Primera infraestructura de `Idempotency-Key` del repo; 003/005 la reutilizan vía el motor | Esperar a 003 dejaría HUT-04 sin garantía real |
| Trigger `SECURITY DEFINER` | `paseo_app` no puede tener `UPDATE` en `customer_balances` (regla 2.3) | Dar `UPDATE` al rol rompe la regla de oro del saldo |
| `balance_after` denormalizado | La UI de historial exige saldo resultante sin recomputo por petición ni N+1 | Recalcular en cada lectura es O(n) por ítem y acopla lectura al trigger |

## Implementation Sequence

Detalle ejecutable en `tasks.md`. Orden de fases (una tarea no empieza si su predecesora no está verde):

- [ ] **F1** Contrato `docs/openapi.yaml` (4 GET + schemas + códigos) → `redocly lint` verde. *(desbloquea en paralelo: API y mobile)*
- [ ] **F2** Migraciones V004–V006 + seeds + `migrate`/`validate` desde cero.
- [ ] **F3** Dominio de puntos (tablas de casos) + `paseo_shared` DTOs/códigos.
- [ ] **F4** Motor `PointsEngine` (credit/debit, idempotencia, trigger) — integración PostgreSQL.
- [ ] **F5** Middleware authz (rol customer, `pv`) + rutas `/me/balance`, `/me/movements` — pruebas de contrato y aislamiento.
- [ ] **F6** Rutas `/rewards`, `/establishments` — pruebas de contrato.
- [ ] **F7** Frontend móvil: `api_client` + 4 pantallas + estados — contra contrato (mock local y luego API real con seed).
- [ ] **F8** Contratos documentados (`contracts/points-engine.md`, `contracts/api-extract.md`) + pruebas de concurrencia/hardening + agenda `speckit-analyze`/`converge`.
- [ ] **F9** Gates finales: CI verde, §16 completo, `docs/agent-audit.md` y `AGENTS.md §1.1` actualizados, PR con trazabilidad.

Paralelizable (`[P]` en tasks.md): F3 ∥ F4 solo tras F2 (F4 toca BD); F5 ∥ F6 comparten middleware (secuencial dentro de api); F7 arranca tras F1 (mobile no toca archivos del API); documentación de contratos al final.

## Rollback / Forward Fix

- Las migraciones solo avanzan: un error de esquema se corrige con `V007+`, nunca editando V004–V006 tras merge (regla 2.6, CI `migration-immutability`).
- Las rutas nacen del openapi aprobado: el rollback de API no rompe consumidores porque el contrato no existía antes de esta feature.
