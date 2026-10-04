-- V006__recompensas.sql
-- Catálogo de recompensas (9-stack §9.6.3). Spec: specs/002-puntos-saldo-catalogo (HU-06).
-- Se ejecuta como paseo_owner. MVP SIN RLS (decisión 03/10/2026): GRANTs mínimos.
-- 002 aporta el MODELO DE LECTURA del cliente; el CRUD administrativo y la
-- aprobación de propuestas los implementa la feature 004 sobre estas tablas.
-- La reserva de stock del canje (fn_reserve_reward_stock, SECURITY DEFINER)
-- llega con la feature 005 junto a `redemptions`: aquí no hay UPDATE de stock
-- para paseo_app, solo lectura.
CREATE TABLE app.rewards (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    establishment_id  uuid NOT NULL REFERENCES app.establishments(id),
    name              text NOT NULL,
    description       text NOT NULL DEFAULT '',
    reward_type       text NOT NULL CHECK (reward_type IN ('PERCENT', 'FIXED', 'GIFT')),
    value_bp          int CHECK (value_bp IS NULL OR value_bp > 0),        -- PERCENT: puntos básicos
    value_cents       bigint CHECK (value_cents IS NULL OR value_cents > 0), -- FIXED
    discount_cap_cents bigint,                                              -- tope del descuento
    cost_points       bigint NOT NULL CHECK (cost_points >= 0),
    stock             int CHECK (stock IS NULL OR stock >= 0),             -- NULL = sin límite
    valid_from        timestamptz,
    valid_to          timestamptz,
    status            text NOT NULL DEFAULT 'DRAFT'
        CHECK (status IN ('DRAFT', 'PENDING', 'ACTIVE', 'PAUSED', 'RETIRED')),
    approved_by       uuid REFERENCES app.users(id),
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now(),
    CHECK (reward_type <> 'PERCENT' OR value_bp IS NOT NULL),
    CHECK (reward_type <> 'FIXED'  OR value_cents IS NOT NULL)
);
-- El listado del cliente filtra ACTIVE + vigencia; el índice lo cubre.
CREATE INDEX rewards_catalog_idx ON app.rewards (status, valid_to);

-- GRANT mínimo: el cliente solo lee el catálogo.
GRANT SELECT ON app.rewards TO paseo_app;
