# Feature Specification: Panel del Establecimiento (Acreditación y Canje)

**Feature**: `003-panel-establecimiento`
**Branch**: `feat/003-panel-establecimiento`
**Created**: 2026-10-03
**Status**: Approved
**Input**: User description: "Implementar todas las historias de Persona 3 (Panel del Establecimiento — Acreditación y Canje) en backend y frontend: HU-10 identificar cliente por QR/celular, HU-11 registrar compra con cálculo automático de puntos, HU-13 consultar movimientos del local y HUT-02 registro en menos de 3 segundos. Usar las especificaciones del repositorio y Spec Kit; preguntar ante decisiones abiertas."
**Authority**: `AGENTS.md` remains the governing repository policy.

> **Rama:** `AGENTS.md` §12 pide `feat/<id-historia>-descripcion`. La rama arrancó como `feature/Persona3` por orden explícita del humano; el 2026-10-03 se renombró a `feat/003-panel-establecimiento` para alinearla con §12. El resto de §12 (Conventional Commits con HU, PR con revisión) se mantiene.

## Scope

- **Goal**: Que el dueño y el cajero de un comercio, desde el panel web del comercio, identifiquen a un cliente por QR o por teléfono, registren la compra con los puntos acreditados automáticamente por el servidor, y consulten los movimientos del local — todo en menos de 3 segundos por operación.
- **Non-goals**:
  - Emitir el QR del cliente (`GET /customers/me/qr`, HU-03 de Persona 1). Este módulo **valida** un token QR conforme al formato firmado; no lo emite.
  - Recompensas, canjes y validación de canjes (`HU-07`, `HU-12`, Persona 5).
  - Reembolsos: ni solicitud (`Persona 3` los declara fuera de alcance en el reparto actual) ni resolución (solo `admin`).
  - Crear o editar reglas de conversión y campañas: **solo `admin`** (`AGENTS.md` §7, §14).
  - Dashboard, gestión de personal, sucursales y recompensas propuestas (solo `merchant_owner`, pero son otra feature).
  - App del cliente y panel del administrador.
  - Cualquier cambio de `V001`, `V002` o `V003` (migraciones inmutables).
- **Actor(s)**: `merchant_owner`, `merchant_cashier`
- **Applications affected**: `api`, `web-merchant`
- **OPEN_DECISIONS** (gate 4 de `specs/README.md`): **ninguna abierta.** El humano resolvió el 2026-10-03 las tres decisiones de `AGENTS.md` §15 que afectaban a esta feature: (1) **`invoice_ref` obligatorio para todos los comercios** → FR-016; (2) **sucursal "Principal" creada automáticamente por trigger** → FR-026; (3) **numeración `+591` + 8 dígitos, sin exigir que inicie en 6 o 7**, coherente con el `CHECK` ya aplicado en `V002` → FR-005.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Identificar al cliente (Priority: P1)

La cajera abre el panel del comercio, pide al cliente su celular o le pide que muestre su QR, y el sistema confirma la identidad del cliente **sin exponerle sus datos personales**.

**Why this priority**: HU-10 es Must y es el prerrequisito literal de HU-11: sin cliente identificado no hay compra que registrar. Además es el paso donde el comercio gana o pierde la confianza del cliente, así que enmascarar el nombre es requisito de privacidad, no un extra.

**Independent Test**: Con un cliente registrado y verificado en la base, llamar `POST /api/v1/merchant/customers/identify` con `{"method":"PHONE","phone":"+5917XXXXXXX"}` y con `{"method":"QR","qr_token":"<token del seed>"}`; ambos devuelven 200 con un ticket firmado y el nombre enmascarado. Se puede demostrar sin frontend.

**Acceptance Scenarios**:

1. **Given** un cliente con teléfono verificado (`pv=true`) y una regla de conversión activa, **When** el cajero identifica por `PHONE` con un número `+591` de 8 dígitos exacto, **Then** responde 200 con `ticket` firmado, `expires_at` a ~5 min y `customer_name` enmascarado (p. ej. `"Carlos M."`), ligado a `establishment_id` y `branch_id` del cajero.
2. **Given** un cliente con `pv=false`, **When** se intenta identificar por `PHONE` o por `QR`, **Then** responde 403 con `code` `PHONE_NOT_VERIFIED`.
3. **Given** un número que no existe en `customers`, **When** se identifica por `PHONE`, **Then** responde 404 con `code` `CUSTOMER_NOT_FOUND` — sin distinguir "no existe" de "existe pero no verificado" más de lo que el código ya permite.
4. **Given** un prefijo distinto de `+591`, **When** se identifica por `PHONE`, **Then** responde 422 con `code` `PHONE_NOT_SUPPORTED`.
5. **Given** un token `QR` vencido (más de ~60 s), malformado o con firma inválida, **When** se identifica, **Then** responde 422 con `code` `INVALID_QR_TOKEN`.
6. **Given** un cajero autenticado, **When** pide `identify`, **Then** el `ticket` emitido lo ata a su `establishment_id` y `branch_id`; el mismo ticket no sirve en otro comercio.

### User Story 2 - Registrar la compra con puntos automáticos (Priority: P1)

El cajero registra la venta y ve de inmediato cuántos puntos se acreditaron y el cliente los ve en su saldo sin hacer nada.

**Why this priority**: HU-11 es el Must que genera el valor del producto: sin compra registrada no hay fidelización. Depende de HU-10 y del motor de conversión.

**Independent Test**: Con un `ticket` válido y una regla `GLOBAL` activa del seed, llamar `POST /api/v1/merchant/purchases` con `Idempotency-Key` y un `net_cents` conocido; responde 201 con los `points_credited` esperados y el saldo del cliente aumenta exactamente esa cantidad. Verificable sin frontend.

**Acceptance Scenarios**:

1. **Given** un `ticket` válido de menos de 5 min, `net_cents = 10000`, `gross_cents = 12000`, `discount_cents = 2000` y una regla activa, **When** el cajero registra la compra con `Idempotency-Key` único, **Then** responde 201 con la compra, los `points_credited` calculados **sobre `net_cents`**, y una fila `CREDIT` en `points_ledger`.
2. **Given** una compra ya registrada con la misma `Idempotency-Key`, **When** se reintenta con el mismo body, **Then** responde **200 con la respuesta original**, sin segunda fila en `points_ledger` y sin doble saldo.
3. **Given** un `invoice_ref` ya usado **en el mismo comercio**, **When** se registra otra compra con ese `invoice_ref`, **Then** responde 409 con `code` `DUPLICATE_INVOICE`. El mismo `invoice_ref` en **otro** comercio sí se acepta.
4. **Given** `ticket` vencido, de otro comercio, o manipulado, **When** se registra la compra, **Then** responde 422 con `code` `INVALID_IDENTIFICATION_TICKET`.
5. **Given** que ninguna regla `BASE` ni `CAMPAIGN` es aplicable, **When** se registra la compra, **Then** responde 409 con `code` `NO_APPLICABLE_RULE` — nunca acredita un valor por defecto.
6. **Given** `net_cents` por debajo de `compra_minima`, **When** se registra la compra, **Then** la compra se guarda con `points_credited = 0` y **no** se inserta fila en `points_ledger`.
7. **Given** un `net_cents` cuyo `points_calculados` superan `tope_puntos_por_compra`, **When** se registra la compra, **Then** se acredita exactamente el tope y `rule_snapshot` registra el valor previo al tope.
8. **Given** un cuerpo inválido (montos negativos, `net_cents != gross_cents - discount_cents`, `invoice_ref` ausente o en blanco, `branch_id` de otra sucursal del cajero), **When** se registra, **Then** responde 422 con `detail` de campo y sin escribir nada.

### User Story 3 - Previsualizar la compra antes de confirmarla (Priority: P2)

El cajero ve cuántos puntos se acreditarán **antes** de confirmar, para no sorprender al cliente ni acreditar puntos de más.

**Why this priority**: `AGENTS.md` §7 exige que `preview` y el registro usen **el mismo** código; es lo que garantiza que la cifra prometida sea la acreditada. Es Should respecto de la HU, pero es la red de seguridad del P1.

**Independent Test**: Llamar `POST /api/v1/merchant/purchases/preview` con los mismos parámetros que luego se registrarán y comparar `points` con los `points_credited` del registro. No escribe nada.

**Acceptance Scenarios**:

1. **Given** los mismos parámetros que un registro exitoso, **When** se llama `preview`, **Then** devuelve `points`, `rule_id`, `campaign_rule_id` y el desglose del cálculo, **sin** escribir en `purchases`, `points_ledger` ni `customer_balances`.
2. **Given** `preview` y luego el registro con los mismos valores, **When** se comparan ambos resultados, **Then** `points` de `preview` es idéntico a `points_credited` del registro.
3. **Given** que ninguna regla es aplicable, **When** se llama `preview`, **Then** devuelve el mismo `code` `NO_APPLICABLE_RULE` que devolvería el registro.

### User Story 4 - Consultar los movimientos del local (Priority: P2)

El dueño revisa las compras del comercio para cuadrar caja y ver la actividad; el cajero solo ve lo que él mismo registró.

**Why this priority**: HU-13 es Should. No bloquea a P1, pero sin él el módulo no es utilizable en la práctica diaria.

**Independent Test**: Registrar dos compras desde dos terminales y llamar `GET /api/v1/merchant/movements`; el `merchant_owner` ve ambas y el `merchant_cashier` solo las suyas.

**Acceptance Scenarios**:

1. **Given** un `merchant_owner` con 30 compras en su comercio, **When** pide `GET /api/v1/merchant/movements?limit=20`, **Then** responde 200 con una `CursorPage` de 20 movimientos y `next_cursor` para el resto.
2. **Given** un `merchant_cashier` que registró 3 de esas 30 compras, **When** pide la misma lista, **Then** devuelve **solo esas 3** (filtro por `seller_user_id`), nunca las de otros cajeros del mismo comercio.
3. **Given** un comercio ajeno, **When** se pide la lista, **Then** responde 200 con la lista **vacía** — el aislamiento se aplica en la capa de aplicación (regla 2.7) y nunca se filtra la existencia de datos de otro comercio.
4. **Given** `limit` mayor que el máximo o negativo, **When** se pide la lista, **Then** responde 422 con el detalle del límite.
5. **Given** un movimiento de otro cliente, **When** se lista, **Then** el DTO expone **el** `customer_name` enmascarado y **nunca** el teléfono, el `customer_id` completo ni el saldo del cliente.

## Edge Cases

- **Aritmética y redondeo**: `puntos_base = redondear(net_cents × puntos_otorgados / monto_por_tramo_centavos)`; luego `puntos = redondear(puntos_base × multiplicador_bp / 10000)`; después tope y compra mínima. Todo en **enteros**; sin `double`/`float` (`AGENTS.md` §2 regla 9). Los tres bordes de redondeo (`FLOOR`, `ROUND`, `CEIL`) se prueban con tabla de casos, incluidos los empates exactos (`.5`).
- **`multiplicador_bp`**: base points en *basis points*; un ×2 es `20000`. Un valor `0` significa "sin multiplicador", no "puntos a cero".
- **Campañas que no aplican**: si hay `CAMPAIGN` vigente pero por importe, fecha o categoría no corresponde, se acredita con la `BASE` sola; las campañas **no se acumulan** entre sí (`AGENTS.md` §7).
- **Regla_base resolution**: `ESTABLISHMENT` > `CATEGORY` > `GLOBAL`, desempate por `priority` ascendente. Nunca se mezclan dos `BASE`.
- **`rule_snapshot` inmutable**: si el `admin` publica una versión nueva de la regla y retira la anterior, las compras viejas siguen siendo legibles y auditables porque el snapshot guarda los parámetros efectivamente usados. Una regla activa **nunca se edita**.
- **Idempotencia bajo carrera**: dos reintentos simultáneos con la misma `Idempotency-Key` no deben produzir dos `CREDIT`. Se resuelve con el índice único sobre `idempotency_key`, no con un `SELECT` previo.
- **`invoice_ref` duplicado bajo carrera**: dos compras simultáneas con el mismo `invoice_ref` en el mismo comercio → una gana y la otra recibe `409 DUPLICATE_INVOICE` (índice único parcial, no verificación previa).
- **`23514` en el saldo**: si una carrera de reversión deja el saldo negativo, el `CHECK (balance >= 0)` aborta. Se reintenta o se informa; **nunca** se relaja el `CHECK`.
- **`pv` desactualizado**: el claim puede tener hasta 15 min. En `identify` y en el registro se consulta `users.status` y `users.phone_verified` **en la base**, no solo el claim.
- **Cajero sin sucursal o con sucursal ajena**: `branch_id` sale del claim `br`; el cliente **no** puede elegirlo. Si el `branch_id` enviado no corresponde a la sucursal fija del cajero, es 422.
- **`POST` de compra con ticket de otro comercio**: 422 `INVALID_IDENTIFICATION_TICKET`, no 403 — el ticket es opaco para el cliente y no debe revelar si el comercio existe.
- **Limite del comercio**: el comercio del seed con `max_purchase_cents` superado y `compliance_status` no `ACTIVE` — el comportamiento exacto depende de Persona 4 (antifraude); esta feature **no** decide ni implementa ese bloqueo. Declarado como no-goal.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST expose exactly four endpoints for this feature, all under the `/api/v1/merchant` prefix: `POST /merchant/customers/identify`, `POST /merchant/purchases/preview`, `POST /merchant/purchases` and `GET /merchant/movements`. The four path keys are written **relative to `servers: [{url: /api/v1}]`**, the same way the eight auth endpoints already are; the effective URLs are `/api/v1/merchant/...` and Dart Frog serves them from `routes/merchant/`, with no `api/v1` directory in the route tree.
- **FR-002**: `docs/openapi.yaml` MUST be updated with those four endpoints **before** any route is implemented (`AGENTS.md` §2 regla 5; gate 3 de `specs/README.md`).
- **FR-003**: `POST /merchant/customers/identify` MUST accept `method` ∈ {`QR`, `PHONE`} and return an **opaque, signed** identification ticket bound to the caller's `establishment_id` (and `branch_id` for a cashier), valid ~5 minutes, plus the customer's **masked** name. It MUST NOT return the phone number, the full name, the `customer_id`, or the balance.
- **FR-004**: `identify` MUST reject customers whose `phone_verified` is false (`pv=false`) with 403 `PHONE_NOT_VERIFIED`, both for `QR` and for `PHONE`.
- **FR-005**: `identify` MUST normalize `PHONE` to E.164 and accept **only** Bolivian numbers (`+591` + 8 digits); any other prefix → 422 `PHONE_NOT_SUPPORTED`. Partial or fuzzy phone search MUST NOT be supported.
- **FR-006**: `identify` MUST validate the `QR` token's **signature and age** (~60 s). This feature validates the token but MUST NOT implement its issuance (that is HU-03, Persona 1).
- **FR-007**: `POST /merchant/purchases` MUST accept **only** the identification ticket — never a phone number nor a customer id — and MUST verify that the ticket belongs to the caller's establishment and is unexpired.
- **FR-008**: `POST /merchant/purchases` MUST require an `Idempotency-Key` header. A retry with the same key and the same body MUST return **200 with the original response**; it MUST NOT create a second `purchases` row, a second `points_ledger` row, or a second balance change.
- **FR-009**: `POST /merchant/purchases` MUST require `gross_cents`, `discount_cents` and `net_cents` as **integers ≥ 0**, and MUST reject the request with 422 unless `net_cents == gross_cents - discount_cents`. Money is never a `double`/`float`.
- **FR-010**: Points MUST be computed by the server from `net_cents`. The Flutter client MUST NOT compute points authoritatively (`AGENTS.md` §2 regla 1); it only renders what `preview`/the purchase response returns.
- **FR-011**: `/merchant/purchases/preview` and `POST /merchant/purchases` MUST call **the same** `domain/PointsCalculator` + `domain/RuleResolver` code path (`AGENTS.md` §7). Preview MUST NOT write to `purchases`, `points_ledger` or `customer_balances`.
- **FR-012**: The calculation MUST be integer-only and follow, in this order: `puntos_base = redondear(net_cents × puntos_otorgados / monto_por_tramo_centavos)`; `puntos = redondear(puntos_base × multiplicador_bp / 10000)`; `puntos = min(puntos, tope_puntos_por_compra)` when a cap exists; `puntos = 0` when `net_cents < compra_minima`. Rounding is `FLOOR | ROUND | CEIL` as defined by the rule.
- **FR-013**: Rule resolution MUST pick **one** active `BASE` rule (`ESTABLISHMENT` > `CATEGORY` > `GLOBAL`, tie-broken by `priority`) and **at most one** active `CAMPAIGN` rule (highest `priority`). Campaigns MUST NOT accumulate with each other.
- **FR-014**: When no rule is applicable, the system MUST fail with `NO_APPLICABLE_RULE` and MUST NOT invent a default conversion.
- **FR-015**: Every purchase MUST persist `establishment_id`, `branch_id`, `customer_id`, `seller_user_id`, `gross_cents`, `discount_cents`, `net_cents`, `invoice_ref` (mandatory), `rule_id`, nullable `campaign_rule_id`, and `rule_snapshot` (the JSON of the parameters actually used).
- **FR-016**: `invoice_ref` MUST be **mandatory** on every purchase (resuelto 2026-10-03) and MUST be unique per `(establishment_id, invoice_ref)`; a repeat MUST return 409 `DUPLICATE_INVOICE`. It MUST NOT identify the customer. Because it is never null, the uniqueness is enforced by a **full** unique index on `(establishment_id, invoice_ref)`, not a partial one, and a missing/blank `invoice_ref` MUST be rejected with 422.
- **FR-017**: `POST /merchant/purchases` MUST derive `branch_id` from the authenticated `merchant_cashier`'s `br` claim (single fixed branch) or from the establishment's branch for a `merchant_owner`. The client MUST NOT choose the branch.
- **FR-018**: When `points_credited > 0`, the purchase and its `points_ledger` `CREDIT` row MUST be written in **one transaction**, together with the `audit_log` row. When `points_credited = 0` (below minimum), the purchase is stored and **no** ledger row is inserted.
- **FR-019**: `GET /merchant/movements` MUST return a `CursorPage` of the establishment's purchases ordered by `created_at DESC, id DESC` (deterministic, stable for the cursor), with a validated `limit` and an opaque `next_cursor`.
- **FR-020**: `GET /merchant/movements` MUST scope rows by the caller's `establishment_id`; a `merchant_cashier` MUST additionally be restricted to purchases where `seller_user_id` equals their own `user_id`. Isolation MUST be enforced in the application/repository layer (see SEC-002).
- **FR-021**: The commerce MUST NOT receive endpoints to create, edit or list conversion rules or campaigns. Only `admin` may (`AGENTS.md` §7, §14).
- **FR-022**: All four endpoints MUST return `application/problem+json` (RFC 9457) with a stable `code` on error, using the project's status mapping: 422 validation, 401 no session, 403 no permission, 404 not found, 409 conflict, 429 rate limit.
- **FR-023**: Routes MUST stay thin: validate, call **one** use case, map the result to RFC 9457. Zero business rules in routes (`AGENTS.md` §3).
- **FR-024**: The four endpoints MUST accept only `aud = paseo-web-merchant` with `role ∈ {merchant_owner, merchant_cashier}`. A `customer` or `admin` token MUST be rejected with 403.
- **FR-025**: `POST /merchant/purchases` and `/preview` MUST be rate-limited per `establishment_id` to protect the write path (429 with `code` `RATE_LIMITED`).
- **FR-026**: Creating an `establishments` row MUST automatically create its "Principal" branch via a database trigger (resuelto 2026-10-03), so no establishment can exist without a branch — the invariant that `establishment_staff.branch_id` and the `br` claim depend on (`AGENTS.md` §10.1). `branch_id` stays mandatory for `merchant_cashier` and null for `merchant_owner`.

### Security, Privacy, and Integrity Requirements

- **SEC-001**: JWT claims MUST NOT contain personal data. `identify` and `purchases` MUST NOT add any. `pv`, `ev` and `tv` are booleans/integers, not personal data (`AGENTS.md` §2 regla 8).
- **SEC-002**: New tables MUST be created with the **minimum `GRANT`s** that `paseo_app` needs — and **nothing more**. RLS, policies and isolation tests are **NOT included in this feature**: rule 2.7 (`AGENTS.md`) was superseded on 2026-10-03 with "MVP sin RLS", and `V002` was already merged under that rule. This is a **deliberate, documented divergence from `specs/README.md` gate 6**, recorded in `research.md`; RLS + isolation tests remain **blocking debt** before any deployment with real data. Multi-establishment isolation is enforced in the application layer per `AGENTS.md` §6.
- **SEC-003**: The commerce MUST see only the customer's **masked name**. It MUST NOT receive the phone number, the full name, the `customer_id`, the customer's balance, the customer's status or the antifraud flags/thresholds (`AGENTS.md` §8, §10).
- **SEC-004**: Logs MUST NOT contain identification tickets, QR tokens, full phone numbers, full email addresses, passwords or OTPs.
- **SEC-005**: The identification ticket MUST be **signed** and verified before use; its payload MUST NOT be readable or forgeable by the client, and MUST be bound to `establishment_id` (and `branch_id`) so it cannot be replayed across establishments.
- **SEC-006**: `paseo_app` MUST have **no** `UPDATE`/`DELETE`/`TRUNCATE` on `points_ledger`, and **no** `UPDATE` on `customer_balances` (the balance is maintained by a trigger; `AGENTS.md` §2 reglas 2 y 3, §9).
- **SEC-007**: `purchases` and `points_ledger` MUST have **no** `UPDATE`/`DELETE` path for the commerce. A cancellation is a `REVERSAL` row, never a mutation (that logic belongs to Persona 4's refunds).
- **SEC-008**: The `establishment_id` used in every query MUST come from the **verified JWT claims**, never from the request body or query string.
- **SEC-009**: Both critical writes (`purchases`) MUST write an `audit_log` row in the same transaction, with `actor_user_id`, `action`, `entity`, `entity_id`, `correlation_id` and non-personal `metadata`.

### Key Entities *(include if data is involved)*

- **Establishment**: `id`, `name`, `category_id`, `location`, `status` (soft delete), `max_purchase_cents`, `compliance_status`. One establishment has ≥ 1 branch.
- **Branch**: `id`, `establishment_id`, `name`, `address`, `status`. Every purchase stores its `branch_id`. A "Principal" branch is created **automatically by trigger** on `establishments` insert, so the 1..n relation can never be empty (FR-026).
- **Establishment staff**: `user_id` + `establishment_id` + `staff_role` ∈ {`OWNER`, `CASHIER`} + `branch_id`. A **cashier has exactly one fixed branch** (mandatory, enforced by a `CHECK`); an **owner has none** and operates in all branches. Source of the `est`/`br` claims.
- **Points rule**: `id`, `scope` ∈ {`ESTABLISHMENT`, `CATEGORY`, `GLOBAL`}, `type` ∈ {`BASE`, `CAMPAIGN`}, `priority`, `points_awarded`, `amount_per_tier_cents`, `multiplier_bp`, `max_points_per_purchase`, `min_purchase_cents`, `rounding` ∈ {`FLOOR`, `ROUND`, `CEIL`}, `valid_from`, `valid_to`. **An active rule is never edited** — a new version is created and the previous one retired. Created only by `admin`.
- **Purchase**: `id`, `establishment_id`, `branch_id`, `customer_id`, `seller_user_id`, `gross_cents`, `discount_cents`, `net_cents`, **`invoice_ref` (NOT NULL)**, `rule_id`, nullable `campaign_rule_id`, `rule_snapshot` (jsonb), `idempotency_key` (unique), `created_at`. Invariants: `net_cents = gross_cents - discount_cents`; `invoice_ref NOT NULL` and `idempotency_key` unique; **full** unique index on `(establishment_id, invoice_ref)`.
- **Ledger movement**: `points_ledger` row with `delta`, `type` ∈ {`CREDIT`, `REDEEM`, `ADJUST`, `BONUS`, `REVERSAL`}, `customer_id`, `establishment_id`, `purchase_id`, and nullable `reverses_ledger_id` (unique when non-null). **Insert-only**: never `UPDATE`, never `DELETE`. This feature writes only `CREDIT` rows; `REVERSAL` is written by the refunds feature (Persona 4).
- **Customer balance**: `customer_id` + `balance`, `CHECK (balance >= 0)`. Maintained by a **trigger**; the API role never writes it.
- **Identification ticket**: ephemeral, signed, **not persisted**; bound to establishment + branch, ~5 min TTL.

## API and Contract Impact

- [ ] No API impact
- [x] `docs/openapi.yaml` update required before implementation
- [x] New/changed RFC 9457 error code required — **new**: `INVALID_QR_TOKEN`, `INVALID_IDENTIFICATION_TICKET`. **Reused**: `CUSTOMER_NOT_FOUND`, `PHONE_NOT_VERIFIED`, `PHONE_NOT_SUPPORTED`, `NO_APPLICABLE_RULE`, `DUPLICATE_INVOICE`, `RATE_LIMITED`.
- [x] Cursor pagination, UTC timestamps, or integer-cent amounts affected — `GET /merchant/movements` returns a `CursorPage`; all amounts are integer cents; all timestamps ISO 8601 UTC.

## Database Impact

- [ ] No database impact
- [x] New Flyway migration required:
  - `infra/migrations/V004__comercios.sql` — `establishments`, `branches`, `establishment_staff` + the `AFTER INSERT` trigger that creates the "Principal" branch (+ `GRANT`s).
  - `infra/migrations/V005__conversion.sql` — `points_rules` (+ `GRANT`s).
  - `infra/migrations/V006__compras_y_ledger.sql` — `purchases`, `points_ledger`, `customer_balances` + the balance trigger + a **full** unique index on `(establishment_id, invoice_ref)` (mandatory `invoice_ref`) and a unique index on `idempotency_key` (+ `GRANT`s).
  - **Numbering:** `V003` is already taken by `V003__cleanup_grants.sql` and applied migrations are immutable (`AGENTS.md` §2 regla 6), so the numbering planned in `9-stack-tecnologico-paseo-points.md` §9.9 (V003/V004/V005) shifts by one. `V007`+ stays free for Personas 4 and 5.
- [ ] RLS/policies/`GRANT` required in the same change — **partially**: `GRANT`s mínimos **yes**; RLS **no** (SEC-002, regla 2.7 supersedida; deuda bloqueante documentada).
- [ ] RLS isolation test required — **deferred** with RLS (SEC-002). Isolation of `GET /merchant/movements` and `POST /merchant/purchases` **is** covered by application-level integration tests against the real `paseo_app` role.
- [x] Migration immutability check affected — new files only; `V001`–`V003` untouched.
- [x] Idempotent dev seed in `infra/seed/R__seed_dev.sql` (only with the `dev` override): one `GLOBAL` `BASE` rule, one demo establishment with a "Principal" branch, one owner, one cashier, and one verified customer. Needed because only `admin` may create rules (Persona 4 is not implemented), so without the seed HU-11 would always return `NO_APPLICABLE_RULE`.

## Success Criteria *(mandatory)*

- **SC-001**: HU-10, HU-11, HU-13 and HUT-02 have at least one test each, written or reviewed by someone other than the implementer (`AGENTS.md` §11).
- **SC-002**: `POST /merchant/purchases` end-to-end (identify → purchase) completes in **under 3 seconds** measured from the API, and identify + purchase together stay **under 500 ms at p95** server-side (`HUT-02`; stack doc §9.4). Verified by an automated test, not by assertion.
- **SC-003**: `PointsCalculator` and `RuleResolver` have table-driven unit tests with **no database**, covering all three rounding modes, the cap, the minimum purchase, campaign multipliers, campaign non-accumulation, the `ESTABLISHMENT > CATEGORY > GLOBAL` precedence, tie-breaking, and the "no rule → `NO_APPLICABLE_RULE`" case.
- **SC-004**: An integration test proves idempotency: two calls with the same `Idempotency-Key` produce exactly one `purchases` row, one `points_ledger` row and one balance change; the second call returns 200 with the original body.
- **SC-005**: An integration test proves isolation: a `merchant_cashier` sees only their own purchases, and a `merchant_owner` sees all of the establishment's, with a different establishment's data never visible — all executed with the real `paseo_app` role.
- **SC-006**: `docs/openapi.yaml` contains all four endpoints and their new error codes **before** the first route file is written, and `npx @redocly/cli@2 lint docs/openapi.yaml` passes.
- **SC-007**: No response body, log line, `audit_log.metadata` or JWT claim contains a full phone number, a full name, an identification ticket or a QR token.
- **SC-008**: All migrations apply from scratch with Flyway in CI, and `paseo_app` is verified to have no `UPDATE`/`DELETE` on `points_ledger` and no `UPDATE` on `customer_balances`.
- **SC-009**: The `web-merchant` panel completes the identify → purchase journey, shows the masked name, and displays the same point figure that `preview` returned.
- **SC-010**: `fvm dart format --set-exit-if-changed .`, `fvm dart analyze --fatal-warnings`, `fvm flutter analyze`, and every test are green; `pubspec.lock` is committed with `http` and `flutter_riverpod` pinned.

## Assumptions

- `001-identidad` (HU-01–HU-05) is merged on `main` and provides `users`, `customers`, Argon2id, JWT issuance with `role`/`est`/`br`/`pv`/`ev`/`tv`, and the RFC 9457 middleware this feature reuses. Persona 3 depends on those **basic contracts only**.
- The `customers.phone` `CHECK (^\+591[0-9]{8}$)` already applied in `V002` is the validation source of truth for `identify` by `PHONE`.
- Since RLS is suspended (SEC-002), every query in this feature filters by `establishment_id` from verified claims **explicitly in the repository**. This is the compensating control and it is reviewed as such.
- Points conversion is **variable and admin-defined**. This feature only reads rules and snapshots them; it never writes them.
- For development, `infra/seed/R__seed_dev.sql` provides a `GLOBAL` `BASE` rule and a demo establishment. In production there is no seed; the admin provisions rules through Persona 4.
- `merchant_cashier` has exactly one fixed branch; `merchant_owner` has none and operates across the establishment's branches.
- Only `total refund` exists and is resolved by `admin`; the commerce never reverses points from this feature.
- **Resuelto 2026-10-03** — `invoice_ref` es obligatorio para todos los comercios (FR-016); la unicidad pasa de índice único parcial a único completo sobre `(establishment_id, invoice_ref)`.
- **Resuelto 2026-10-03** — la sucursal "Principal" la crea un trigger `AFTER INSERT` sobre `app.establishments`, de modo que ningún comercio existe sin sucursal (FR-026). El seed no la inserta a mano.
- **Resuelto 2026-10-03** — `identify` por `PHONE` acepta cualquier `+591` seguido de 8 dígitos, exactamente lo que valida el `CHECK` de `V002`; no se exige que el número empiece en 6 o 7 (FR-005).

## Definition of Done

- [ ] Spec reviewed and approved by a human
- [ ] Plan written and approved
- [ ] Tasks written and traceable
- [ ] Contract updated before implementation, if API changes
- [ ] Tests written before behavior changes
- [ ] Security, RLS, audit, and idempotency rules checked when applicable — `GRANT`s mínimos, `audit_log`, `Idempotency-Key`, isolation by `establishment_id`; RLS deferred per SEC-002 with the divergence recorded in `research.md`
- [x] The three `OPEN_DECISIONS` resolved by the human and removed from this spec (resuelto 2026-10-03)
