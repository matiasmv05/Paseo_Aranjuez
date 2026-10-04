-- V005__puntos_ledger.sql
-- Motor de puntos: purchases (soporte), points_ledger (append-only),
-- customer_balances (derivado por trigger), points_idempotency.
-- Spec: specs/002-puntos-saldo-catalogo (HUT-04). Se ejecuta como paseo_owner.
--
-- INVARIANTES (AGENTS.md §2 reglas 2-4, §7, §9):
-- 1. Los puntos solo se mueven por points_ledger. Jamás UPDATE/DELETE: una
--    anulación es un movimiento REVERSAL (reverses_ledger_id único parcial).
-- 2. El saldo lo mantiene EXCLUSIVAMENTE el trigger fn_apply_ledger_movement
--    (SECURITY DEFINER, dueño paseo_owner): la API no puede escribir saldos.
-- 3. CHECK (balance >= 0): saldo insuficiente aborta con 23514 en la MISMA
--    transacción del INSERT → nada queda a medias. El upsert toma el bloqueo
--    de fila del cliente: no hay carrera y (regla §9) NO se usa
--    SELECT ... FOR UPDATE sobre el saldo.
-- 4. Idempotencia con respaldo doble: points_idempotency (scope, key) con
--    replay de respuesta, y UNIQUE en points_ledger.idempotency_key y
--    purchases.idempotency_key como última línea de defensa.

-- ============================================================================
-- purchases: soporte del CREDIT. rule_id/rule_snapshot/seller llegan con 003/004 (nulos aquí).
-- ============================================================================
CREATE TABLE app.purchases (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    establishment_id uuid NOT NULL REFERENCES app.establishments(id),
    branch_id        uuid REFERENCES app.branches(id),
    customer_id      uuid NOT NULL REFERENCES app.customers(user_id),
    seller_user_id   uuid REFERENCES app.users(id),
    gross_cents      bigint NOT NULL CHECK (gross_cents >= 0),
    discount_cents   bigint NOT NULL DEFAULT 0 CHECK (discount_cents >= 0),
    net_cents        bigint NOT NULL CHECK (net_cents >= 0),
    invoice_ref      text,
    idempotency_key  text NOT NULL UNIQUE,
    rule_id          uuid,
    rule_snapshot    jsonb,
    occurred_at      timestamptz NOT NULL DEFAULT now(),
    created_at       timestamptz NOT NULL DEFAULT now()
);
-- Único por comercio cuando existe (AGENTS.md §9); no identifica al cliente.
CREATE UNIQUE INDEX purchases_invoice_ref_uq ON app.purchases (establishment_id, invoice_ref)
    WHERE invoice_ref IS NOT NULL;
CREATE INDEX purchases_customer_idx ON app.purchases (customer_id);

-- ============================================================================
-- points_ledger: único punto de escritura de puntos.
-- ============================================================================
CREATE TABLE app.points_ledger (
    id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id        uuid NOT NULL REFERENCES app.customers(user_id),
    delta              bigint NOT NULL CHECK (delta <> 0),
    type               text NOT NULL CHECK (type IN ('CREDIT', 'REDEEM', 'ADJUST', 'BONUS', 'REVERSAL')),
    purchase_id        uuid REFERENCES app.purchases(id),
    reverses_ledger_id uuid REFERENCES app.points_ledger(id),
    idempotency_key    text NOT NULL UNIQUE,
    occurred_at        timestamptz NOT NULL DEFAULT now(),  -- la fija el servidor
    balance_after      bigint NOT NULL,  -- la rellena el trigger; CHECK abajo
    created_at         timestamptz NOT NULL DEFAULT now()
);
-- Un solo REVERSAL por crédito (§10.1).
CREATE UNIQUE INDEX points_ledger_reverses_uq ON app.points_ledger (reverses_ledger_id)
    WHERE reverses_ledger_id IS NOT NULL;
-- Cursor del historial (occurred_at, ledger_id) por cliente (spec FR-002).
CREATE INDEX points_ledger_customer_cursor_idx ON app.points_ledger (customer_id, occurred_at DESC, id DESC);

-- ============================================================================
-- customer_balances: saldo derivado. paseo_app SOLO lee; el trigger escribe.
-- ============================================================================
CREATE TABLE app.customer_balances (
    customer_id uuid PRIMARY KEY REFERENCES app.customers(user_id),
    balance     bigint NOT NULL CHECK (balance >= 0),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Trigger del saldo. UPDATE primero `balance = balance + delta`: toma el
-- bloqueo de fila del cliente y, al desbloquearse, re-lee el valor ya
-- confirmado (READ COMMITTED) → serializa carreras sin SELECT ... FOR
-- UPDATE (regla §9) y sin lost-update. Si no hay fila, INSERT; la
-- unique_violation por carrera en la insercion reintenta como UPDATE.
-- NO usar ON CONFLICT dentro del trigger: su arbitraje especulativo no
-- detecta de forma fiable la fila recien insertada/actualizada desde el
-- propio disparador (provoco saldo incorrecto en la seed; cubierto por
-- test/integration/ledger_trigger_test.dart). El CHECK (balance >= 0)
-- sigue abortando con 23514 la transaccion completa.
CREATE FUNCTION app.fn_apply_ledger_movement()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = app, pg_temp
AS $fn$
BEGIN
    LOOP
        UPDATE app.customer_balances
           SET balance = balance + NEW.delta, updated_at = now()
         WHERE customer_id = NEW.customer_id
        RETURNING balance INTO NEW.balance_after;
        IF FOUND THEN RETURN NEW; END IF;

        BEGIN
            INSERT INTO app.customer_balances (customer_id, balance, updated_at)
            VALUES (NEW.customer_id, NEW.delta, now())
            RETURNING balance INTO NEW.balance_after;
            RETURN NEW;
        EXCEPTION WHEN unique_violation THEN
            -- Otra transaccion creo la fila primero: reintentar como UPDATE.
        END;
    END LOOP;
END;
$fn$;

CREATE TRIGGER trg_points_ledger_balance
    BEFORE INSERT ON app.points_ledger
    FOR EACH ROW EXECUTE FUNCTION app.fn_apply_ledger_movement();

-- ============================================================================
-- points_idempotency: primera infraestructura de Idempotency-Key del repo;
-- la consumen el motor (002) y, tras sus puertos, las features 003/005.
-- ============================================================================
CREATE TABLE app.points_idempotency (
    scope        text NOT NULL,   -- p. ej. 'points.credit' | 'points.debit'
    key          text NOT NULL,
    request_hash text NOT NULL,   -- mismo key + payload distinto → 409 CONFLICT
    response     jsonb NOT NULL,  -- respuesta original para replay
    ledger_id    uuid REFERENCES app.points_ledger(id),
    created_at   timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (scope, key)
);

-- ============================================================================
-- GRANTs mínimos (AGENTS.md §5.3; MVP sin RLS por decisión 03/10/2026)
-- ============================================================================
GRANT SELECT, INSERT ON app.purchases           TO paseo_app;
GRANT SELECT, INSERT ON app.points_ledger       TO paseo_app;
REVOKE UPDATE, DELETE, TRUNCATE ON app.points_ledger FROM paseo_app;  -- explícito (regla 2.2)
GRANT SELECT ON app.customer_balances           TO paseo_app;         -- sin UPDATE: solo el trigger
GRANT SELECT, INSERT ON app.points_idempotency  TO paseo_app;
