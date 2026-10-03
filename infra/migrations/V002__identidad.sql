-- V002__identidad.sql
-- Identidad: users, customers, verification_codes, password_resets, refresh_tokens, audit_log.
-- Se ejecuta como paseo_owner vía Flyway.
-- DECISIÓN DE EQUIPO (03/10/2026): MVP SIN RLS (supersede AGENTS.md regla 7).
-- Solo GRANTs mínimos a paseo_app y REVOKE de UPDATE/DELETE/TRUNCATE en
-- audit_log. RLS + políticas son deuda bloqueante antes de producción.
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
    purpose     text NOT NULL CHECK (purpose IN ('phone_verify', 'phone_change', 'email_verify')),
    expires_at  timestamptz NOT NULL,
    attempts    int NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    consumed_at timestamptz,
    created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX verification_codes_phone_idx ON app.verification_codes (phone);
-- Los tokens de correo/recuperación se buscan por su hash (VerifyEmail/ResetPassword).
CREATE INDEX verification_codes_code_hash_idx ON app.verification_codes (code_hash);

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
    jti                uuid NOT NULL UNIQUE DEFAULT gen_random_uuid(),
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
