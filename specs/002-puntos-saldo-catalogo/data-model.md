# Data Model: Motor de puntos, saldo e historial (002)

> Esquema de V004-V006. Fuente: migraciones en infra/migrations/. Inmutables (regla 2.6).

## establishments (V004)

| Columna | Tipo | Restricciones | Notas |
|---------|------|---------------|-------|
| id | uuid PK | DEFAULT gen_random_uuid() | |
| name | text | NOT NULL | |
| category | text | NOT NULL | |
| max_purchase_cents | bigint | CHECK (NULL OR >= 0) | Administrativo; no se expone al cliente |
| compliance_status | text | NOT NULL DEFAULT ACTIVE, CHECK IN (ACTIVE, REVIEW, SUSPENDED) | Administrativo; no se expone |
| deleted_at | timestamptz | nullable | Baja logica; NULL = activo |
| created_at | timestamptz | NOT NULL DEFAULT now() | |

Indices: establishments_active_idx ON (id) WHERE deleted_at IS NULL.
GRANT: SELECT a paseo_app.

## branches (V004)

| Columna | Tipo | Restricciones | Notas |
|---------|------|---------------|-------|
| id | uuid PK | DEFAULT gen_random_uuid() | |
| establishment_id | uuid FK establishments | NOT NULL | |
| name | text | NOT NULL | |
| address | text | NOT NULL | |
| status | text | NOT NULL DEFAULT ACTIVE, CHECK IN (ACTIVE, INACTIVE) | |
| created_at | timestamptz | NOT NULL DEFAULT now() | |

Indices: branches_establishment_idx ON (establishment_id).
GRANT: SELECT a paseo_app.
## purchases (V005)

Soporte del CREDIT en el ledger. El endpoint POST /merchant/purchases es de 003.

| Columna | Tipo | Restricciones | Notas |
|---------|------|---------------|-------|
| id | uuid PK | DEFAULT gen_random_uuid() | |
| establishment_id | uuid FK establishments | NOT NULL | |
| branch_id | uuid FK branches | nullable | 003 lo completa |
| customer_id | uuid FK customers.user_id | NOT NULL | |
| seller_user_id | uuid FK users | nullable | 003 lo completa |
| gross_cents | bigint | NOT NULL CHECK >= 0 | Centavos enteros (regla 2.9) |
| discount_cents | bigint | NOT NULL DEFAULT 0 CHECK >= 0 | |
| net_cents | bigint | NOT NULL CHECK >= 0 | Base para puntos (regla 7) |
| invoice_ref | text | nullable | Unico por (establishment_id, invoice_ref); no identifica cliente |
| idempotency_key | text | NOT NULL UNIQUE | Defensa contra compra duplicada |
| rule_id | uuid | nullable | 004 lo completa |
| rule_snapshot | jsonb | nullable | 004 lo completa |
| occurred_at | timestamptz | NOT NULL DEFAULT now() | Lo fija el servidor (C2) |
| created_at | timestamptz | NOT NULL DEFAULT now() | |

Indices: purchases_invoice_ref_uq ON (establishment_id, invoice_ref) WHERE invoice_ref IS NOT NULL. purchases_customer_idx ON (customer_id).
GRANT: SELECT, INSERT a paseo_app.

## points_ledger (V005)

Unico punto de escritura de puntos. Append-only: REVOKE UPDATE, DELETE, TRUNCATE.

| Columna | Tipo | Restricciones | Notas |
|---------|------|---------------|-------|
| id | uuid PK | DEFAULT gen_random_uuid() | |
| customer_id | uuid FK customers.user_id | NOT NULL | |
| delta | bigint | NOT NULL CHECK <> 0 | Con signo: positivo acredita, negativo debita |
| type | text | NOT NULL CHECK IN (CREDIT, REDEEM, ADJUST, BONUS, REVERSAL) | |
| purchase_id | uuid FK purchases | nullable | Para CREDIT |
| reverses_ledger_id | uuid FK points_ledger | nullable | Para REVERSAL; unico parcial |
| idempotency_key | text | NOT NULL UNIQUE | Defensa en profundidad |
| occurred_at | timestamptz | NOT NULL DEFAULT now() | Lo fija el servidor (C2) |
| balance_after | bigint | NOT NULL | Lo rellena el trigger (C3) |
| created_at | timestamptz | NOT NULL DEFAULT now() | |

Indices: points_ledger_reverses_uq ON (reverses_ledger_id) WHERE NOT NULL. points_ledger_customer_cursor_idx ON (customer_id, occurred_at DESC, id DESC).
GRANT: SELECT, INSERT a paseo_app. REVOKE UPDATE, DELETE, TRUNCATE.
## customer_balances (V005)

Saldo derivado por trigger. paseo_app SOLO lee; el trigger escribe.

| Columna | Tipo | Restricciones | Notas |
|---------|------|---------------|-------|
| customer_id | uuid PK FK customers.user_id | | |
| balance | bigint | NOT NULL CHECK >= 0 | Nunca negativo (regla 2.3) |
| updated_at | timestamptz | NOT NULL DEFAULT now() | |

GRANT: SELECT a paseo_app. Sin UPDATE para paseo_app.

## fn_apply_ledger_movement (V005, trigger)

Funcion SECURITY DEFINER, esquema app, search_path fijado (app, pg_temp). BEFORE INSERT FOR EACH ROW sobre points_ledger.

Logica: UPDATE customer_balances SET balance = balance + NEW.delta RETURNING balance INTO NEW.balance_after. Si FOUND: RETURN NEW. Si no: INSERT INTO customer_balances. Si unique_violation: reintentar UPDATE (LOOP). Si balance + delta < 0: CHECK aborta con 23514 -> transaccion revierte.

## points_idempotency (V005)

| Columna | Tipo | Restricciones | Notas |
|---------|------|---------------|-------|
| scope | text | NOT NULL, PK (scope, key) | p. ej. points.credit |
| key | text | NOT NULL | Idempotency-Key del header |
| request_hash | text | NOT NULL | Mismo key + hash distinto -> 409 CONFLICT |
| response | jsonb | NOT NULL | Respuesta original para replay |
| ledger_id | uuid FK points_ledger | nullable | |
| created_at | timestamptz | NOT NULL DEFAULT now() | |

GRANT: SELECT, INSERT a paseo_app.

## rewards (V006)

| Columna | Tipo | Restricciones | Notas |
|---------|------|---------------|-------|
| id | uuid PK | DEFAULT gen_random_uuid() | |
| establishment_id | uuid FK establishments | NOT NULL | No hay globales en MVP (C14) |
| name | text | NOT NULL | |
| description | text | NOT NULL DEFAULT  | |
| reward_type | text | NOT NULL CHECK IN (PERCENT, FIXED, GIFT) | C13 |
| value_bp | int | CHECK (NULL OR > 0) | PERCENT: basis points |
| value_cents | bigint | CHECK (NULL OR > 0) | FIXED: centavos |
| discount_cap_cents | bigint | nullable | Tope del descuento |
| cost_points | bigint | NOT NULL CHECK >= 0 | |
| stock | int | CHECK (NULL OR >= 0) | NULL = sin limite |
| valid_from | timestamptz | nullable | |
| valid_to | timestamptz | nullable | |
| status | text | NOT NULL DEFAULT DRAFT, CHECK IN (DRAFT, PENDING, ACTIVE, PAUSED, RETIRED) | |
| approved_by | uuid FK users | nullable | Administrativo |
| created_at | timestamptz | NOT NULL DEFAULT now() | |
| updated_at | timestamptz | NOT NULL DEFAULT now() | |

CHECK: PERCENT requiere value_bp NOT NULL. FIXED requiere value_cents NOT NULL.
Indices: rewards_catalog_idx ON (status, valid_to).
GRANT: SELECT a paseo_app.

## Invariantes

1. Solo points_ledger mueve puntos (regla 2.2). REVERSAL, no DELETE.
2. customer_balances.balance == SUM(points_ledger.delta) por cliente.
3. balance >= 0 siempre (CHECK; aborta con 23514 si no).
4. paseo_app no puede UPDATE/DELETE/TRUNCATE points_ledger.
5. paseo_app no puede UPDATE customer_balances (solo el trigger).
6. Una Idempotency-Key produce un solo movimiento.
7. Un solo REVERSAL por credito (indice unico parcial).
