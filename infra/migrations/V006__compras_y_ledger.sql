-- V006__compras_y_ledger.sql
-- Compras (purchases), ledger de puntos (points_ledger) y saldo (customer_balances).
-- Se ejecuta como paseo_owner vía Flyway.
-- Ledger de SOLO INSERCIÓN: nunca UPDATE ni DELETE. Una anulación es una fila
-- REVERSAL que apunta al crédito original (AGENTS.md §2 regla 2).
-- El saldo lo mantiene un trigger, no la API: paseo_app inserta el ledger y nada más.
-- INVARIANTE INNEGOCIABLE: balance >= 0 (AGENTS.md §2 regla 3).

-- ============================================================================
-- Tablas
-- ============================================================================

CREATE TABLE app.customer_balances (
    customer_id uuid PRIMARY KEY REFERENCES app.customers(user_id) ON DELETE CASCADE,
    balance     bigint NOT NULL DEFAULT 0 CHECK (balance >= 0),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE app.points_ledger (
    id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id        uuid NOT NULL REFERENCES app.customers(user_id),
    establishment_id   uuid REFERENCES app.establishments(id),
    type               text NOT NULL CHECK (type IN ('CREDIT', 'REDEEM', 'ADJUST', 'BONUS', 'REVERSAL')),
    delta              bigint NOT NULL CHECK (delta <> 0),
    purchase_id        uuid,
    redemption_id      uuid,  -- sin FK: redemptions es de Persona 5
    reverses_ledger_id uuid REFERENCES app.points_ledger(id),
    reason             text,
    created_at         timestamptz NOT NULL DEFAULT now(),
    -- Esta feature solo inserta CREDIT desde una compra.
    CONSTRAINT points_ledger_purchase_is_credit_ck CHECK (purchase_id IS NULL OR type = 'CREDIT'),
    -- REVERSAL exige original; el resto lo prohíbe.
    CONSTRAINT points_ledger_reversal_target_ck    CHECK ((reverses_ledger_id IS NULL) <> (type = 'REVERSAL'))
);

-- Un solo REVERSAL por crédito original.
CREATE UNIQUE INDEX points_ledger_reverses_uk
    ON app.points_ledger (reverses_ledger_id) WHERE reverses_ledger_id IS NOT NULL;
CREATE INDEX points_ledger_customer_idx      ON app.points_ledger (customer_id, created_at DESC);
CREATE INDEX points_ledger_establishment_idx ON app.points_ledger (establishment_id, created_at DESC);

CREATE TABLE app.purchases (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    establishment_id uuid NOT NULL REFERENCES app.establishments(id),
    branch_id        uuid NOT NULL,
    customer_id      uuid NOT NULL REFERENCES app.customers(user_id),
    seller_user_id   uuid NOT NULL REFERENCES app.users(id),
    gross_cents      bigint NOT NULL CHECK (gross_cents >= 0),
    discount_cents   bigint NOT NULL DEFAULT 0 CHECK (discount_cents >= 0),
    net_cents        bigint NOT NULL CHECK (net_cents >= 0),
    invoice_ref      text NOT NULL CHECK (length(btrim(invoice_ref)) BETWEEN 1 AND 64),
    rule_id          uuid NOT NULL REFERENCES app.points_rules(id),
    campaign_rule_id uuid REFERENCES app.points_rules(id),
    rule_snapshot    jsonb NOT NULL,
    idempotency_key  text NOT NULL CHECK (length(idempotency_key) BETWEEN 8 AND 128),
    points_credited  int NOT NULL DEFAULT 0 CHECK (points_credited >= 0),
    created_at       timestamptz NOT NULL DEFAULT now(),
    -- net_cents no puede mentir: si no es gross - discount, el INSERT revienta (23514).
    CONSTRAINT purchases_amounts_ck CHECK (net_cents = gross_cents - discount_cents),
    -- La sucursal guardada pertenece al comercio, en la BD y no solo en el use case.
    CONSTRAINT purchases_branch_fk
        FOREIGN KEY (branch_id, establishment_id)
        REFERENCES app.branches (id, establishment_id)
);

-- Idempotencia por comercio, no global: cada comercio es dueño de sus claves
-- (desviación registrada en research.md).
CREATE UNIQUE INDEX purchases_idempotency_uk
    ON app.purchases (establishment_id, idempotency_key);
-- invoice_ref NOT NULL → índice completo (acelera el INSERT ... ON CONFLICT).
CREATE UNIQUE INDEX purchases_establishment_invoice_uk
    ON app.purchases (establishment_id, invoice_ref);
-- id DESC como desempate del cursor de movimientos (created_at, id).
CREATE INDEX purchases_establishment_created_idx
    ON app.purchases (establishment_id, created_at DESC, id DESC);
CREATE INDEX purchases_customer_created_idx
    ON app.purchases (customer_id, created_at DESC);
CREATE INDEX purchases_branch_created_idx
    ON app.purchases (branch_id, created_at DESC);

-- ============================================================================
-- Trigger de saldo
-- ============================================================================
-- SECURITY DEFINER: paseo_app NO tiene UPDATE sobre customer_balances y aun así
-- el saldo se mueve al insertar el ledger. Hace cumplir AGENTS.md §2 regla 3 a
-- nivel de permiso, no solo de convención.

CREATE FUNCTION app.fn_apply_ledger_to_balance() RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = app, pg_temp
AS $$
BEGIN
    INSERT INTO app.customer_balances (customer_id, balance, updated_at)
    VALUES (NEW.customer_id, NEW.delta, now())
    ON CONFLICT (customer_id) DO UPDATE
        SET balance    = app.customer_balances.balance + EXCLUDED.balance,
            updated_at = now();
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_points_ledger_balance
    AFTER INSERT ON app.points_ledger
    FOR EACH ROW EXECUTE FUNCTION app.fn_apply_ledger_to_balance();

-- ============================================================================
-- GRANTs mínimos a paseo_app (AGENTS.md §5.3)
-- ============================================================================

GRANT SELECT, INSERT ON app.purchases        TO paseo_app;
GRANT SELECT, INSERT ON app.points_ledger    TO paseo_app;
GRANT SELECT        ON app.customer_balances TO paseo_app;

-- El ledger es insert-only y el saldo nunca se escribe desde la API.
REVOKE UPDATE, DELETE, TRUNCATE ON app.points_ledger    FROM paseo_app;
REVOKE UPDATE, DELETE, TRUNCATE ON app.customer_balances FROM paseo_app;
REVOKE UPDATE, DELETE, TRUNCATE ON app.purchases        FROM paseo_app;
