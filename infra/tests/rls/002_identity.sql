-- 002_identity.sql — prueba de aislamiento RLS de V002.
-- Se ejecuta con el rol paseo_app (por ejemplo: psql -U paseo_app -v ON_ERROR_STOP=1).
-- Caso aislado por transacción con ROLLBACK: el test es idempotente.
\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------------
-- Caso 1: sin contexto, ninguna fila accesible.
-- ---------------------------------------------------------------------------
BEGIN;
DO $$
DECLARE
    n int;
BEGIN
    SELECT count(*) INTO n FROM app.users;
    ASSERT n = 0, 'Caso 1 FALLO: sin contexto app.users deberia devolver 0 filas';
END $$;
ROLLBACK;

-- ---------------------------------------------------------------------------
-- Caso 2: rol 'system' — insertar user+customer, leerlo, insertar audit_log;
--         UPDATE app.audit_log debe fallar (solo inserción).
-- ---------------------------------------------------------------------------
BEGIN;
SELECT set_config('app.role', 'system', true);

INSERT INTO app.users (email, password_hash, role)
VALUES ('rls_test@example.com', '$argon2id$test', 'customer');

INSERT INTO app.customers (user_id, phone, full_name)
SELECT id, '+59170000000', 'Prueba RLS' FROM app.users WHERE email = 'rls_test@example.com';

DO $$
DECLARE
    n int;
BEGIN
    SELECT count(*) INTO n FROM app.users WHERE email = 'rls_test@example.com';
    ASSERT n = 1, 'Caso 2a FALLO: system deberia leer el usuario recien creado';
END $$;

INSERT INTO app.audit_log (actor_role, action) VALUES ('system', 'rls_test');

DO $$
BEGIN
    BEGIN
        UPDATE app.audit_log SET action = 'x';
        ASSERT false, 'Caso 2b FALLO: UPDATE app.audit_log no deberia ser posible para paseo_app';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL; -- esperado
    END;
END $$;
ROLLBACK;

-- ---------------------------------------------------------------------------
-- Caso 3: rol 'customer' — solo ve su fila en app.users; no ve
--         verification_codes sin rol 'system'.
-- ---------------------------------------------------------------------------
BEGIN;
-- Preparar datos como system dentro de esta transacción.
SELECT set_config('app.role', 'system', true);

INSERT INTO app.users (id, email, password_hash, role)
VALUES ('00000000-0000-0000-0000-000000000002', 'rls_test3@example.com', '$argon2id$test', 'customer');

INSERT INTO app.verification_codes (phone, code_hash, purpose, expires_at)
VALUES ('+59170000001', 'hash', 'phone_verify', now() + interval '5 minutes');

-- Cambiar al rol del propio usuario (misma transacción: contexto local).
SELECT set_config('app.role', 'customer', true);
SELECT set_config('app.user_id', '00000000-0000-0000-0000-000000000002', true);

DO $$
BEGIN
    -- Su propia fila es visible.
    PERFORM 1 FROM app.users WHERE id = '00000000-0000-0000-0000-000000000002';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Caso 3a FALLO: el customer deberia ver su propia fila';
    END IF;

    -- Ninguna otra fila de users es visible con rol customer.
    IF EXISTS (SELECT 1 FROM app.users WHERE id <> '00000000-0000-0000-0000-000000000002') THEN
        RAISE EXCEPTION 'Caso 3b FALLO: el customer no deberia ver usuarios ajenos';
    END IF;

    -- verification_codes: 0 filas visibles sin rol system.
    IF EXISTS (SELECT 1 FROM app.verification_codes) THEN
        RAISE EXCEPTION 'Caso 3c FALLO: sin system no deberia ver verification_codes';
    END IF;
END $$;
ROLLBACK;

SELECT '002_identity.sql: OK' AS resultado;
