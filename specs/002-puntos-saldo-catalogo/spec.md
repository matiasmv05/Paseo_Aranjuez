# Feature Specification: Motor de puntos, saldo e historial del cliente

**Feature**: `002-puntos-saldo-catalogo`
**Branch**: `feat/002-puntos-saldo-catalogo`
**Created**: 2026-10-03
**Status**: Approved (2026-10-03 — aprobación humana registrada al invocar `/speckit-plan`; aclaraciones de `/speckit-clarify` ya incorporadas)
**Input**: User description: "Persona 2 — Motor de Puntos y Saldo del Cliente: HU-04 consultar saldo, HU-05 historial de movimientos, HU-06 catálogo de beneficios, HU-09 establecimientos participantes y HUT-04 transacciones atómicas (nunca saldo negativo, nunca duplicados). Módulo utilizable de forma independiente e integrable con identidad (001), compras (003), administración de catálogo (004) y canjes (005)."
**Authority**: `AGENTS.md` remains the governing repository policy. Reglas aplicadas: §2 (1, 2, 3, 4, 5, 10), §3, §4, §5, §6, §7, §9, §11, §14, §16.

## Clarifications

### Sesión 2026-10-03 (/speckit-clarify)

- **Q → Visibilidad del catálogo (decisión humana)**: `GET /rewards` lista las `ACTIVE` vigentes **incluidas** las de `stock = 0` (marcadas `available: false`); las vencidas y las no aprobadas (`DRAFT/PENDING/PAUSED/RETIRED`) quedan fuera.
- **C1 → Autenticación del catálogo y establecimientos**: ambos exigen `bearerAuth` con `role=customer`; no son endpoints públicos anónimos (doc de stack: `GET /rewards` rol cliente).
- **C2 → Origen de `occurred_at`**: siempre el servidor (`now()` dentro de la transacción del motor). El invocador (003/005) no impone fecha.
- **C3 → `balanceAfter` sin romper append-only**: el trigger escribe `balance_after` en la propia fila del ledger durante el `INSERT`; ledger y saldo quedan atómicos por construcción.
- **C4 → Estado "procesándose" (HU-04)**: no existe en 002. Las escrituras son síncronas; toda lectura refleja el último `COMMIT`. No hay caché ni cola de puntos.
- **C5 → Semántica de idempotencia**: tabla del motor con `(scope, key)` único, hash del request y respuesta serializada. Mismo key + mismo payload → respuesta original (200/201); mismo key + payload distinto → 409 `CONFLICT`.
- **C6 → Tipos en historial**: el enum completo (`CREDIT, REDEEM, ADJUST, BONUS, REVERSAL`) se renderiza aunque 002 solo genere `CREDIT` y `REDEEM`.
- **C7 → Paginación**: `limit` por defecto 20, máximo 50; cursor opaco claveado por `(occurred_at, ledger_id)`.

### Sesión 2026-10-03 (análisis de gaps del spec)

- **C8 → Validación de pv en el motor**: el motor recibe phoneVerified del invocador (003/005) desde el JWT. AGENTS.md §6 recomienda consultar users.phone_verified en la base para acciones sensibles. **Decisión**: el invocador pasa pv desde el JWT como bool phoneVerified; el motor NO consulta la base en 002. Es deuda de hardening añadir una verificación en la transacción (tarea futura post-002) para casos donde el JWT esté desactualizado.
- **C9 → aud aceptado**: los 4 endpoints de customer aceptan **solo** aud=paseo-mobile. Las webs de comercio/admin no acceden a estos endpoints. El middleware authz valida role=customer **y** aud=paseo-mobile.
- **C10 → Mapeo MovementType → origin**: CREDIT→purchase, REDEEM→redemption, ADJUST→adjustment, BONUS→adjustment (no existe origen bonus en el contrato; BONUS comparte adjustment), REVERSAL→reversal. Implementado en domain/points/movement_type.dart.
- **C11 → Derivación de reference_id**: el ledger no tiene columna reference_id; se deriva en la consulta SQL del repositorio: CREDIT→purchase_id, REDEEM→ledger_id (auto-referencia; el canje futuro tendrá redemption_id), ADJUST→ledger_id, BONUS→ledger_id, REVERSAL→reverses_ledger_id.
- **C12 → updated_at en Balance**: siempre presente. Cuando el cliente no tiene movimientos (sin fila en customer_balances), el caso de uso devuelve balance=0 y la ruta fija updated_at=now() (tiempo de consulta). El DTO Balance tiene updatedAt requerido. Alínea FR-001, openapi y código.
- **C13 → Semántica de reward_type**: PERCENT = descuento porcentual (value_bp en basis points; p. ej. 1000 = 10%); FIXED = monto fijo en centavos (value_cents; p. ej. 2000 = Bs 20); GIFT = artículo físico (sin valor monetario directo). El cliente solo ve reward_type, cost_points, stock, available; value_bp/value_cents no se exponen en RewardSummary.
- **C14 → establishment_id en rewards**: NOT NULL (V006). No hay recompensas globales en el MVP. GET /rewards lista todas las recompensas de todos los establecimientos sin filtrar.
- **C15 → Estados de establishments y branches**: establishments.compliance_status en {ACTIVE, REVIEW, SUSPENDED} (V004); deleted_at marca baja lógica (no aparece en GET /establishments). branches.status en {ACTIVE, INACTIVE} (V004); las INACTIVE no se listan.
- **C16 → correlation_id en audit_log**: generado por el middleware (UUID v4) al inicio de cada petición HTTP; se propaga al caso de uso y al audit_log. El motor recibe el correlationId y lo pasa a AuditLogWriter.write(). Para invocaciones internas (003/005), el invocador genera el UUID. _middleware.dart ya genera correlation_id y lo incluye en problem+json.
- **C17 → Paginación de rewards/establishments**: **sin paginación en el MVP**. Devuelven lista completa (array JSON). Se reintroducirá CursorPage si el catálogo supera ~100 items (no bloqueante).
- **C18 → Rate limiting**: los 4 endpoints nuevos están sujetos al rate_limit_middleware existente. Un 429 RATE_LIMITED es posible en todos.
- **C19 → Idempotencia: 3 capas, 1 valor**: el Idempotency-Key del header viaja a points_idempotency.key (tabla del motor, (scope, key) PK) para replay. El mismo valor se persiste en purchases.idempotency_key (UNIQUE, defensa contra compra duplicada) y points_ledger.idempotency_key (UNIQUE, defensa en profundidad). Orden de protección: points_idempotency (replay limpio) → purchases.idempotency_key (409) → points_ledger.idempotency_key (409). request_hash solo vive en points_idempotency.

## Scope

- **Goal**: Que un cliente autenticado con teléfono verificado consulte su saldo real de puntos y su historial, explore el catálogo de beneficios y los establecimientos participantes; y que **toda** escritura de puntos (presente o futura) pase por un único motor transaccional del módulo: ledger de solo inserción, saldo derivado por trigger, idempotencia y sin saldo negativo.
- **Non-goals**:
  - Endpoint de registro de compras (feature 003, Persona 3). Esta spec crea el **motor de acreditación** (`PointsEngine.credit`) que 003 invocará; la tabla `purchases` se crea aquí como soporte del ledger.
  - Flujo de canje del cliente y validación en caja (feature 005, Persona 5). Esta spec crea el **motor de débito** (`PointsEngine.debit`) como contrato interno, **sin** endpoint REST ni tabla `redemptions`.
  - CRUD administrativo de recompensas/establecimientos y aprobación de propuestas (feature 004, Persona 4). Esta spec crea las tablas como **modelo de lectura** del cliente.
  - Reglas de conversión (`points_rules`, `PointsCalculator`, `RuleResolver`): `AGENTS.md` §7 las reserva al admin (feature 004). El motor acepta `points` ya calculados como entrada; el cálculo no es responsabilidad de 002.
  - Antifraude, reembolsos, notificaciones FCM, gamificación, QR.
  - Cambio de negocio en frontend de comercio/admin: las pantallas de 002 son solo del cliente (`apps/mobile`, app móvil).
- **Actor(s)**: `customer` (lecturas `/me/*`, catálogo, establecimientos); `system` (motor de puntos invocado por futuros casos de uso de 003/004/005).
- **Applications affected**: `api` (migraciones, motor, endpoints de lectura), `mobile` (4 pantallas del cliente), `worker` (no afectado).
- **OPEN_DECISIONS** (AGENTS.md §15; esta spec NO las resuelve): ninguna decisión abierta de §15 es bloqueante para esta feature. El regex endurecido de teléfono, el proveedor de SMS y el recorte hexagonal de Flutter siguen abiertos y **no** condicionan 002 (el frontend usa la estructura `features/<f>/{presentation,application,data}` ya acordada).

## Arquitectura del módulo (contrato de integración)

La fuente de verdad del estado de puntos es **`points_ledger`** (solo inserción; `customer_balances` es derivado por trigger). Ningún otro módulo escribe en estas tablas:

1. **Escritura única**: solo los casos de uso del módulo de puntos (`PointsEngine.credit` / `PointsEngine.debit`) insertan en `points_ledger`. Reforzado en base con `REVOKE UPDATE, DELETE, TRUNCATE` y `GRANT` mínimos (AGENTS.md §5.3).
2. **Contrato para Persona 3 (acreditación)**: el caso de uso de 003 llama al puerto de aplicación `PointsEngine.credit(CreditCommand{ idempotencyKey, customerId, establishmentId, branchId, purchaseInput, points, occurredAt })`. Una transacción atómica inserta `purchases` + `points_ledger(CREDIT)` + reserva de idempotencia. Misma `idempotencyKey` → misma respuesta, sin segundo `CREDIT`.
3. **Contrato para Persona 5 (débito)**: el canje del cliente llamará a `PointsEngine.debit(DebitCommand{ idempotencyKey, customerId, rewardId, points, occurredAt })` → `points_ledger(REDEEM)` con `delta < 0` en una transacción que incluye reserva de stock (función SQL futura de 004/005) y `audit_log`. Saldo insuficiente → `INSUFFICIENT_POINTS`. **En 002 no hay endpoint REST de débito** (decisión aprobada 03/10/2026).
4. **Nadie más importa** `PostgresLedgerRepository` ni tablas del módulo; la regla se verifica por convención de paquetes (`lib/domain/points`, `lib/application/points`, `lib/adapters/out/postgres/postgres_*ledger*`) y revisión de código.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consultar saldo (HU-04) (Priority: P1)

Un cliente autenticado abre su app y ve su saldo actual de puntos, que refleja el estado real del ledger en ese momento.

**Why this priority**: Es la consulta más frecuente y la demostración mínima de que el motor funciona.

**Independent Test**: Con seeds, login de cliente y `GET /me/balance` devuelve el saldo que coincide con la suma del ledger de ese cliente (verificable con SQL directo). Demostrable sin compras reales.

**Acceptance Scenarios**:

1. **Given** un cliente sin movimientos, **When** `GET /me/balance`, **Then** 200 con `balance_points=0` y el sistema no crea fila vacía en `customer_balances`.
2. **Given** un cliente con movimientos, **When** `GET /me/balance`, **Then** 200 con el saldo derivado por el trigger tras el último movimiento.
3. **Given** una sesión válida con `pv=false`, **When** `GET /me/balance`, **Then** 403 `PHONE_NOT_VERIFIED` (AGENTS.md §6).
4. **Given** un token de otro cliente, **When** `GET /me/balance`, **Then** devuelve **únicamente** el saldo del cliente del JWT (`cid`); no existe forma de pasar otro identificador.
5. **Given** un fallo interno de base, **When** `GET /me/balance`, **Then** 500 con `problem+json` genérico (sin detalles internos).

### User Story 2 - Consultar historial de movimientos (HU-05) (Priority: P1)

El cliente revisa sus movimientos en orden cronológico inverso, paginados por cursor (convención `CursorPage`, AGENTS.md §9). Cada movimiento muestra tipo, puntos, fecha/hora UTC, origen y referencia de la operación, además del **saldo resultante** calculado en el servidor.

**Why this priority**: Es la segunda consulta del cliente y la que evidencia la integridad del ledger.

**Independent Test**: Sembrar ≥ 3 tipos de movimientos para un cliente (con seeds y con el motor vía SQL del trigger) y verificar orden, cursor, tipos y `balanceAfter` coherente con el saldo actual.

**Acceptance Scenarios**:

1. **Given** un cliente sin movimientos, **When** `GET /me/movements`, **Then** 200 con lista vacía (empty state; no es error).
2. **Given** un cliente con más movimientos que el tamaño de página, **When** dos peticiones consecutivas con el `cursor` devuelto, **Then** no hay movimientos repetidos ni omitidos.
3. **Given** movimientos `CREDIT` y `REDEEM`, **When** `GET /me/movements`, **Then** cada ítem distingue `type`, `deltaPoints` (signo), `occurredAt` (ISO 8601 UTC), `origin` (compra/canje/ajuste) y `referenceId`, con `balanceAfter` correcto.
4. **Given** un token de otro cliente, **When** `GET /me/movements`, **Then** solo sus propios movimientos; imposible cruzar clientes.
5. **Given** `pv=false`, **When** `GET /me/movements`, **Then** 403 `PHONE_NOT_VERIFIED`.

### User Story 3 - Motor de puntos transaccional (HUT-04) (Priority: P1)

Toda escritura de puntos pasa por el motor: una transacción inserta la reserva de idempotencia, el movimiento del ledger y (si aplica) la compra; el trigger actualiza el saldo; si cualquier paso falla, **toda** la transacción revierte. El saldo nunca es negativo ni duplicado aunque haya reintentos ni carreras.

**Why this priority**: Es el requisito de integridad (Must) que habilita la integración con 003/005 sin riesgo.

**Independent Test**: Pruebas de integración contra PostgreSQL real con `paseo_app`: doble débito simultáneo ganando saldo una sola vez; misma `Idempotency-Key` repetida devolviendo la respuesta original; fallo inyectado a mitad de transacción sin rastro parcial.

**Acceptance Scenarios**:

1. **Given** saldo 100, **When** dos débitos concurrentes de 70, **Then** exactamente uno inserta el `REDEEM`; el otro obtiene error de dominio `INSUFFICIENT_POINTS` (SQLSTATE `23514` mapeado); saldo final 30; **sin** `SELECT … FOR UPDATE` ni escritura directa de saldo por la API.
2. **Given** una acreditación con `Idempotency-Key` K, **When** se repite la llamada con K, **Then** 200/201 con la respuesta original y **un solo** movimiento `CREDIT` en el ledger.
3. **Given** dos acreditaciones con la misma referencia externa, **When** se procesan, **Then** la segunda no crea un segundo movimiento (índice único sobre la referencia/idempotencia → conflicto determinista, p. ej. 409 `CONFLICT` o respuesta idempotente según el caso).
4. **Given** un fallo tras insertar el movimiento y antes de commitear (inyección de fallo), **When** la transacción revierte, **Then** ni el ledger ni el saldo contienen el movimiento.
5. **Given** `pv=false`, **When** el motor intenta acreditar a ese cliente, **Then** rechazo con `PHONE_NOT_VERIFIED` y nada insertado (AGENTS.md §6).
6. **Given** cualquier intento de `UPDATE/DELETE/TRUNCATE` sobre `points_ledger` con `paseo_app`, **When** se ejecuta, **Then** error de permisos (verificado por prueba de integración).
7. **Given** clientes A y B, **When** en paralelo A acredita y B retira, **Then** ambos terminan sin interferencia (bloqueo de fila por cliente, no global).

### User Story 4 - Catálogo de beneficios (HU-06) (Priority: P2)

El cliente ve las recompensas disponibles: nombre, descripción, costo en puntos, stock o disponibilidad, vigencia y estado. Solo aparecen las `ACTIVE` vigentes.

**Why this priority**: Es lectura pública para el cliente; no bloquea el motor pero sí la demo del valor de la plataforma.

**Independent Test**: Seeds con una recompensa de cada tipo (`PERCENT`, `FIXED`, `GIFT`), una `ACTIVE` sin stock y una vencida; `GET /rewards` devuelve las disponibles y la sin stock (marcada), y excluye la vencida, con los campos del contrato.

**Acceptance Scenarios**:

1. **Given** catálogo vacío, **When** `GET /rewards`, **Then** 200 con lista vacía (empty state).
2. **Given** recompensas `ACTIVE` con stock > 0 y vigentes, **When** `GET /rewards`, **Then** 200 con todos los campos del contrato y `available=true`.
3. **Given** una recompensa `ACTIVE` vigente con `stock=0`, **When** `GET /rewards`, **Then** aparece con `available=false` (decisión de la sesión de aclaración 2026-10-03).
4. **Given** recompensas `DRAFT/PENDING/PAUSED/RETIRED` o vencidas, **When** `GET /rewards`, **Then** no aparecen.
5. **Given** el contrato, **When** se consulta una recompensa, **Then** nunca se exponen campos administrativos (`approved_by`, `compliance`, etc.).

### User Story 5 - Establecimientos participantes (HU-09) (Priority: P2)

El cliente consulta los establecimientos adheridos con sucursales, para saber dónde acumular y canjear.

**Why this priority**: Should-have; lectura pura sobre las tablas que 003/004 necesitan.

**Independent Test**: Seeds con ≥ 2 establecimientos y sucursales; `GET /establishments` devuelve la lista con datos de identificación y ubicación.

**Acceptance Scenarios**:

1. **Given** no hay establecimientos activos, **When** `GET /establishments`, **Then** 200 con lista vacía.
2. **Given** establecimientos activos, **When** `GET /establishments`, **Then** 200 con nombre, categoría y sucursales (dirección); sin exponer `max_purchase_cents` ni `compliance_status`.
3. **Given** un establecimiento dado de baja lógica, **When** `GET /establishments`, **Then** no aparece.

## Correctness Properties (PBT)

Propiedades ejecutables que el motor de puntos debe satisfacer (AGENTS.md §2 reglas 2-4; HUT-04). Las pruebas de integración las verifican contra PostgreSQL real con paseo_app.

1. **Saldo == suma de deltas**: Para toda secuencia de movimientos en el ledger de un cliente, customer_balances.balance == SUM(points_ledger.delta) WHERE customer_id = X. El trigger garantiza esto por construcción.
2. **Saldo nunca negativo**: Para toda inserción en points_ledger, si balance + delta < 0, la transacción aborta con SQLSTATE 23514 (mapeado a INSUFFICIENT_POINTS). Ningún test produce balance < 0.
3. **Idempotencia de replay**: Para toda Idempotency-Key K repetida con el mismo payload, el ledger contiene exactamente un movimiento con esa key, y la segunda llamada devuelve la respuesta original (replayed=true).
4. **Conflicto de idempotencia**: Para toda Idempotency-Key K repetida con payload distinto, la segunda llamada devuelve 409 CONFLICT y no inserta movimiento.
5. **Ledger append-only**: Para todo intento de UPDATE, DELETE o TRUNCATE sobre points_ledger con paseo_app, la base rechaza con error de permisos. Verificado por prueba de integración.
6. **No interferencia entre clientes**: Para toda transacción concurrente entre clientes distintos A y B, el saldo final de A no depende de los movimientos de B. El trigger toma bloqueo de fila por customer_id.
7. **Serialización de carrera**: Para dos débitos concurrentes sobre el mismo cliente cuya suma excede el saldo, exactamente uno aborta con INSUFFICIENT_POINTS. El trigger serializa por el bloqueo de fila del UPDATE/INSERT en customer_balances.
8. **Atomicidad**: Para todo fallo a mitad de la transacción del motor, ni el ledger, ni el saldo, ni la compra, ni la idempotencia contienen rastro del movimiento.


### Edge Cases

- Movimiento `BONUS/ADJUST/REVERSAL` (futuros 004/009) → la API de historial debe renderizar cualquier tipo existente en el enum, aunque 002 no los genere.
- Historial muy grande → paginación por cursor estable `(occurred_at, ledger_id)` para inmutabilidad del orden sin saltos ni duplicados.
- Lectura de saldo justo tras una escritura → read-your-writes: saldo y `balanceAfter` se leen en la misma conexión/derivados del ledger, no de caché.
- Error interno en cualquier endpoint → `problem+json` con `INTERNAL` y `correlation_id`; nunca stacktrace ni PII.
- Cliente intentando acceder a recurso ajeno → los endpoints `/me/*` no aceptan identificador; para catálogo/establecimientos (públicos para `customer`) la autorización es por `aud`/`role` del JWT.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `GET /me/balance` devuelve `{ balance_points, updated_at? }` leyendo el saldo derivado; el cliente solo puede leer el suyo (identidad desde el JWT).
- **FR-002**: `GET /me/movements` devuelve una `CursorPage` de movimientos con `type`, `deltaPoints`, `occurredAt`, `origin`, `referenceId`, `balanceAfter`; cursor opaco claveado por `(occurred_at, ledger_id)` y `limit` con máximo (p. ej. 50).
- **FR-003**: `GET /rewards` lista recompensas `ACTIVE` y vigentes: con stock → `available=true`; sin stock → incluidas con `available=false`; vencidas o en otro `status` → excluidas. Campos: nombre, descripción, costo en puntos, stock/disponibilidad, vigencia y estado (Clarifications, decisión humana).
- **FR-004**: `GET /establishments` lista establecimientos activos con nombre, categoría y sucursales (nombre + dirección), sin campos administrativos.
- **FR-005**: El motor (`PointsEngine`) expone `credit` y `debit` como contratos internos (puertos de aplicación) con entradas idempotentes (`idempotencyKey`, referencia externa) y salida con el `ledgerId` y la respuesta confirmada; nunca se expone escritura de puntos por REST en esta feature. El servidor fija `occurred_at`; el invocador no la impone (Clarification C2).
- **FR-006**: Toda operación del motor es transaccional: reserva de idempotencia + inserción en ledger (+ compra en el caso de crédito) en **una** transacción; el trigger actualiza `customer_balances` y graba `balance_after` en la fila del ledger (Clarification C3); `CHECK (balance >= 0)` aborta con `23514 → INSUFFICIENT_POINTS`. La idempotencia compara el payload: mismo key + payload distinto → 409 `CONFLICT` (Clarification C5).
- **FR-007**: `points_ledger` es append-only (`REVOKE UPDATE, DELETE, TRUNCATE` para `paseo_app`); la reversión es un tipo de movimiento, no un borrado.
- **FR-008**: Toda escritura del motor escribe `audit_log` (actor, acción, entidad, `correlation_id`, sin PII).
- **FR-009**: `docs/openapi.yaml` se actualiza ANTES de implementar cualquier ruta de esta feature (los 4 GET y los problemas/nschemas nuevos).
- **FR-010**: El frontend del cliente implementa 4 pantallas (saldo, historial, catálogo, establecimientos) con estados loading/success/empty/error, consumiendo el contrato real; mientras no exista UI de login móvil, la sesión se inyecta desde una fuente de configuración manteniendo el contrato (sin acoplar vistas a tablas).

### Security, Privacy, and Integrity Requirements

- **SEC-001**: El `clientId` nunca viene del cliente: todos los `/me/*` derivan `cid` del JWT verificado.
- **SEC-002**: `pv=false` → 403 `PHONE_NOT_VERIFIED` en `/me/balance` y `/me/movements`, y el motor rechaza acreditar a clientes sin verificar (AGENTS.md §6).
- **SEC-007**: `GET /rewards` y `GET /establishments` exigen `bearerAuth` con `role=customer` (no son públicos anónimos; Clarification C1).
- **SEC-003**: `GRANT` mínimos en cada migración (`SELECT` sobre vistas/tablas de lectura; `INSERT` solo en ledger y tablas del motor; `UPDATE` solo donde el motor lo exige). Sin RLS en el MVP (decisión 03/10/2026); el aislamiento se verifica con pruebas de integración de autorización.
- **SEC-004**: El saldo nunca se escribe desde la API: `paseo_app` no tiene `UPDATE` en `customer_balances` (solo el trigger escribe). Prohibido `SELECT … FOR UPDATE` sobre el saldo (AGENTS.md §9).
- **SEC-005**: Logs sin PII import; el historial expone solo datos de la operación, nunca teléfonos/correos].
- **SEC-006**: Dinero y puntos en enteros; nunca `double` (regla 2.9).

### Key Entities *(include if data is involved)*

- **establishments**: comercio participante. `status`/`deleted_at` para baja lógica; `max_purchase_cents` y `compliance_status` existen pero **no** se exponen al cliente.
- **branches**: sucursales (`establishment_id`, nombre, dirección, `status`). Suficiente con lectura en 002; la sucursal "Principal" automática es decisión de 003/004, no de esta spec.
- **purchases**: compra registrada por el comercio (003). En 002 existe **solo como soporte del ledger** (`id`, `establishment_id`, `branch_id`, `customer_id`, montos enteros, `invoice_ref`, `idempotency_key` único, `rule_id/rule_snapshot` **nulos** hasta 004); el motor de crédito la inserta junto al `CREDIT`.
- **points_ledger**: único punto de escritura de puntos. `id`, `customer_id`, `delta` (int, signo), `type` (`CREDIT`, `REDEEM`, `ADJUST`, `BONUS`, `REVERSAL`), `purchase_id?`, `reverses_ledger_id?` (único parcial), `idempotency_key` (único), `occurred_at`, `created_at`. Nunca `UPDATE/DELETE`.
- **customer_balances**: `customer_id` PK, `balance` con `CHECK (balance >= 0)`, `updated_at`; mantenido exclusivamente por trigger sobre el ledger.
- **rewards**: catálogo. `reward_type` (`PERCENT`/`FIXED`/`GIFT`), valor, `cost_points`, `stock`, `valid_from/valid_to`, `establishment_id`, `status` (`DRAFT/PENDING/ACTIVE/PAUSED/RETIRED`). En 002: lectura del cliente + seeds.
- **audit_log** (ya creada en V002): el motor registra cada escritura de puntos.

## API and Contract Impact

- [ ] No API impact
- [x] `docs/openapi.yaml` update required before implementation: `GET /me/balance`, `GET /me/movements`, `GET /rewards`, `GET /establishments`
- [x] New/changed RFC 9457 error code required: `INSUFFICIENT_POINTS` (existente en el vocabulario de AGENTS.md §9; formalizar el `type`/`title` en openapi), `PHONE_NOT_VERIFIED`, `INTERNAL_ERROR`, `VALIDATION_FAILED`
- [x] Cursor pagination, UTC timestamps, or integer-cent amounts affected: `CursorPage` en movimientos; puntos enteros; `MoneyCents` no se expone al cliente en 002

## Database Impact

- [ ] No database impact
- [x] New Flyway migrations required: `infra/migrations/V004__comercios.sql` (`establishments`, `branches`), `infra/migrations/V005__puntos_ledger.sql` (`purchases` soporte, `points_ledger`, `customer_balances`, trigger, índices, tabla de idempotencia del motor, `REVOKE`/`GRANT`), `infra/migrations/V006__recompensas.sql` (`rewards`)
- [x] `GRANT` mínimos en cada migración (RLS diferido por decisión del equipo 03/10/2026; deuda bloqueante pre-producción documentada en §BLOCKERS)
- [x] ~~RLS isolation test required~~ Diferido con RLS; en su lugar, prueba de integración de **autorización por JWT** (cliente A no lee a B) y de **permisos** (`REVOKE` del ledger verificado)
- [ ] Migration immutability check affected (solo añade `V00x` nuevas; no muta existentes)

## Success Criteria *(mandatory)*

- **SC-001**: HU-04/HU-05 demostrables con el cliente de la app móvil: login (ya existe) → saldo → historial con cursor, consistentes con SQL directo al ledger; HU-06/HU-09 con seeds de catálogo y establecimientos.
- **SC-002**: Pruebas verdes en CI: unitarias del motor por tabla de casos; integración con PostgreSQL real cubriendo los 16 escenarios mínimos de la asignación (incluidos doble acreditación, carrera de débitos, fallo a mitad de transacción y acceso cruzado entre clientes).
- **SC-003**: Cero escrituras de saldo fuera del trigger y cero `UPDATE/DELETE` al ledger verificadas por permisos; misma `Idempotency-Key` nunca produce dos movimientos; saldo nunca negativo en ningún test.
- **SC-004**: Contratos documentados en `docs/openapi.yaml` (lint 0 errores) y contratos internos del motor descritos en `specs/002-puntos-saldo-catalogo/contracts/` para consumo de 003/004/005.

## Assumptions

- 001 (identidad) aporta `cid` y `pv` del JWT ya operativos; 002 no reimplementa autenticación.
- 003 (compras) y 005 (canje) integrarán por los puertos del motor, no por escritura directa en tablas de 002. El campo `points` de la acreditación lo calcula 003 con las reglas de 004; el motor no inventa valores cuando no hay regla (regla `NO_APPLICABLE_RULE` queda en 003/004).
- `rewards` y `establishments` se siembran con `infra/seed/R__seed_dev.sql` (solo dev) para la demo; el CRUD real llega con 004.
- La excepción en concurrencia se mapea en dominio como `INSUFFICIENT_POINTS` desde `pg_errors` existente (`23514`).
- **OPEN**: ninguna adicional a las de AGENTS.md §15 que bloquee esta spec.

## Definition of Done

- [ ] Spec reviewed and approved by a human
- [ ] Plan written and approved
- [ ] Tasks written and traceable
- [ ] Contract updated before implementation, if API changes
- [ ] Tests written before behavior changes
- [ ] Security, RLS, audit, and idempotency rules checked when applicable
