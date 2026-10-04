-- V004__comercios.sql
-- Comercios: establishments y branches (9-stack §9.6.3). Spec: specs/002-puntos-saldo-catalogo.
-- Se ejecuta como paseo_owner vía Flyway. MVP SIN RLS (decisión de equipo 03/10/2026):
-- solo GRANTs mínimos a paseo_app. RLS + políticas = deuda bloqueante pre-producción.
-- En 002 estas tablas son el modelo de LECTURA del catálogo del cliente (HU-09);
-- el alta/CRUD administrativo y el staff llegan con las features 003/004.
-- Campos administrativos (max_purchase_cents, compliance_status) existen en el
-- modelo pero NUNCA se exponen al cliente (spec 002, SEC/FR-004).

CREATE TABLE app.establishments (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name              text NOT NULL,
    category          text NOT NULL,
    max_purchase_cents bigint CHECK (max_purchase_cents IS NULL OR max_purchase_cents >= 0),
    compliance_status text NOT NULL DEFAULT 'ACTIVE'
        CHECK (compliance_status IN ('ACTIVE', 'REVIEW', 'SUSPENDED')),
    deleted_at        timestamptz,  -- baja lógica
    created_at        timestamptz NOT NULL DEFAULT now()
);
-- Los listados del cliente solo leen establecimientos sin baja lógica.
CREATE INDEX establishments_active_idx ON app.establishments (id)
    WHERE deleted_at IS NULL;

CREATE TABLE app.branches (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    establishment_id uuid NOT NULL REFERENCES app.establishments(id),
    name             text NOT NULL,
    address          text NOT NULL,
    status           text NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'INACTIVE')),
    created_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX branches_establishment_idx ON app.branches (establishment_id);
-- Todo comercio tiene al menos una sucursal ("Principal"): regla de negocio que
-- aplica 003/004 al dar de alta; aquí solo el modelo.

-- GRANTs mínimos: 002 solo lee el catálogo.
GRANT SELECT ON app.establishments TO paseo_app;
GRANT SELECT ON app.branches       TO paseo_app;
