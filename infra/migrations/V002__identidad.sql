-- V002__identidad.sql
-- Identidad: users, customers, verification_codes, password_resets, refresh_tokens, audit_log.
-- Se ejecuta como paseo_owner vía Flyway. Toda tabla nace con RLS, políticas y GRANTs (AGENTS.md §5.3).
-- PII fuera de users: teléfono vive solo en customers. Sin códigos en claro (solo hashes).

-- ============================================================================
-- Tablas
-- ============================================================================

CREATE TABLE app.users (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email           citext NOT NULL UNIQUE,
    password_hash   text NOT NULL,
    role            text NOT NULL CHECK (role IN ('customer', 'merchant_owner', 'merchant_cashier', 'admin')),
    status          text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'OBSERVED', 'POINTS_SUSPENDED', 'BLOCKED')),
    token_version   int NOT NULL DEFAULT 0,
    phone_verified  boolean NOT NULL DEFAULT false,
    email_verified_at timestamptz,
    created_at      timestamptz NOT NULL DEFAULT now()
);
-- Sin teléfono en users (vive en customers).

CREATE TABLE app.customers (
    user_id           uuid PRIMARY KEY REFERENCES app.users(id),
    phone             text NOT NULL UNIQUE CHECK (phone ~ '^\+591[0-9]{8}$'),
    full_name         text NOT NULL,
    phone_verified_at timestamptz
);

CREATE TABLE app.verification_codes (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    phone       text NOT NULL,
    code_hash   text NOT NULL,
    purpose     text NOT NULL CHECK (purpose IN ('phone_verify', 'phone_change')),
    expires_at  timestamptz NOT NULL,
    attempts    int NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    consumed_at timestamptz,
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX verification_codes_phone_idx ON app.verification_codes (phone);

CREATE TABLE app.password_resets (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    uuid NOT NULL REFERENCES app.users(id),
    token_hash text NOT NULL UNIQUE,
    expires_at timestamptz NOT NULL,
    used_at    timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE app.refresh_tokens (
    id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            uuid NOT NULL REFERENCES app.users(id),
    aud                text NOT NULL CHECK (aud IN ('paseo-mobile', 'paseo-web-merchant', 'paseo-web-admin')),
    jti                uuid NOT NULL UNIQUE,
    token_hash         text NOT NULL UNIQUE,
    family_id          uuid NOT NULL,
    expires_at         timestamptz NOT NULL,
    revoked_at         timestamptz,
    reused_detected_at timestamptz,
    created_at         timestamptz NOT NULL DEFAULT now()
);

-- audit_log: solo inserción, jamás UPDATE/DELETE (se revoca a paseo_app abajo).
CREATE TABLE app.audit_log (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    at             timestamptz NOT NULL DEFAULT now(),
    actor_role     text,
    actor_user_id  uuid,
    action         text NOT NULL,
    entity         text,
    entity_id      text,
    correlation_id uuid,
    metadata       jsonb NOT NULL DEFAULT '{}'
);

-- ============================================================================
-- GRANTs mínimos a paseo_app (AGENTS.md §5.3: solo lo que el caso de uso necesita)
-- ============================================================================

GRANT SELECT, INSERT, UPDATE ON app.users              TO paseo_app;  -- pv/token_version/status cambian
GRANT SELECT, INSERT, UPDATE ON app.customers          TO paseo_app;
GRANT SELECT, INSERT, UPDATE ON app.verification_codes TO paseo_app;  -- attempts/consumed_at
GRANT SELECT, INSERT, UPDATE ON app.password_resets    TO paseo_app;  -- used_at
GRANT SELECT, INSERT, UPDATE ON app.refresh_tokens     TO paseo_app;  -- revoked_at
GRANT INSERT ON app.audit_log                          TO paseo_app;  -- solo inserción
REVOKE UPDATE, DELETE, TRUNCATE ON app.audit_log FROM paseo_app;

-- ============================================================================
-- RLS: sin contexto válido, ninguna fila. 'system' solo para identidad.
-- ============================================================================

ALTER TABLE app.users              ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.customers          ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.verification_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.password_resets    ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.refresh_tokens     ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.audit_log          ENABLE ROW LEVEL SECURITY;

-- users: acceso de identidad (system) + lectura de la propia fila (prepara /me).
CREATE POLICY users_system_all ON app.users
    FOR ALL USING (current_setting('app.role', true) = 'system')
    WITH CHECK (current_setting('app.role', true) = 'system');
CREATE POLICY users_self_read ON app.users
    FOR SELECT USING (nullif(current_setting('app.user_id', true), '')::uuid = id);

-- customers: acceso de identidad (system); el propio cliente lee su fila (user_id es PK).
CREATE POLICY customers_system_all ON app.customers
    FOR ALL USING (current_setting('app.role', true) = 'system')
    WITH CHECK (current_setting('app.role', true) = 'system');
CREATE POLICY customers_self_read ON app.customers
    FOR SELECT USING (nullif(current_setting('app.user_id', true), '')::uuid = user_id);

-- verification_codes: solo identidad (system). Nadie más ve códigos de otros teléfonos.
CREATE POLICY verification_codes_system_all ON app.verification_codes
    FOR ALL USING (current_setting('app.role', true) = 'system')
    WITH CHECK (current_setting('app.role', true) = 'system');

-- password_resets: solo identidad (system).
CREATE POLICY password_resets_system_all ON app.password_resets
    FOR ALL USING (current_setting('app.role', true) = 'system')
    WITH CHECK (current_setting('app.role', true) = 'system');

-- refresh_tokens: solo identidad (system).
CREATE POLICY refresh_tokens_system_all ON app.refresh_tokens
    FOR ALL USING (current_setting('app.role', true) = 'system')
    WITH CHECK (current_setting('app.role', true) = 'system');

-- audit_log: system inserta y audita; sin SELECT para paseo_app en este MVP.
CREATE POLICY audit_log_system_insert ON app.audit_log
    FOR INSERT WITH CHECK (current_setting('app.role', true) = 'system');
