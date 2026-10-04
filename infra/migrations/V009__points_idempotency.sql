-- V009__points_idempotency.sql
-- Parche al points_ledger de V006 + tabla de idempotencia.
--
-- V006 creó points_ledger con la estructura mínima de la feature 003; aquí se
-- añaden las columnas que la feature 002 (motor de puntos) necesita:
--   - idempotency_key: unicidad por operación (AGENTS.md §2 regla 4)
--   - occurred_at: timestamp de negocio fijado por el servidor (FR-002)
--   - balance_after: saldo resultante, rellenado por el trigger BEFORE INSERT
--
-- El trigger de V006 (AFTER INSERT, ON CONFLICT) se reemplaza por el diseño
-- robusto BEFORE INSERT + loop UPDATE → INSERT que evita el bug de carrera en
-- la seed (cubierto por test/integration/ledger_trigger_test.dart) y rellena
-- balance_after en el RETURNING de la misma transacción.
--
-- Se ejecuta como paseo_owner vía Flyway. MVP sin RLS (decisión 03/10/2026).

-- ============================================================================
-- Ampliar points_ledger
-- ============================================================================
ALTER TABLE app.points_ledger
    ADD COLUMN IF NOT EXISTS idempotency_key text,
    ADD COLUMN IF NOT EXISTS occurred_at     timestamptz NOT NULL DEFAULT now(),
    ADD COLUMN IF NOT EXISTS balance_after   bigint      NOT NULL DEFAULT 0;

-- Unicidad de la idempotency_key (solo filas con clave; las de 003 son NULL).
CREATE UNIQUE INDEX points_ledger_idempotency_uk
    ON app.points_ledger (idempotency_key)
    WHERE idempotency_key IS NOT NULL;

-- Índice de cursor del historial del cliente (occurred_at, id DESC).
-- V006 ya tiene points_ledger_customer_idx; este cubre la paginación de 002.
CREATE INDEX IF NOT EXISTS points_ledger_customer_cursor_idx
    ON app.points_ledger (customer_id, occurred_at DESC, id DESC);

-- ============================================================================
-- Reemplazar el trigger de V006 por el diseño BEFORE INSERT con loop
-- ============================================================================
DROP TRIGGER IF EXISTS trg_points_ledger_balance ON app.points_ledger;
DROP FUNCTION IF EXISTS app.fn_apply_ledger_to_balance();

CREATE OR REPLACE FUNCTION app.fn_apply_ledger_movement()
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
GRANT SELECT, INSERT ON app.points_idempotency TO paseo_app;
