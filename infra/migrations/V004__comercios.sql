-- V004__comercios.sql
-- Comercios (establishments), sucursales (branches) y personal (establishment_staff).
-- Se ejecuta como paseo_owner vía Flyway.
-- DECISIÓN DE EQUIPO (03/10/2026): MVP SIN RLS (supersede AGENTS.md regla 7).
-- Estas tablas nacen solo con GRANTs mínimos a paseo_app; el aislamiento
-- multi-comercio se aplica en la capa de aplicación. RLS + pruebas de
-- aislamiento son deuda bloqueante antes de producción.
-- Todo comercio tiene al menos una sucursal "Principal" (decisión 03/10/2026),
-- creada por un trigger para no depender de que el alta se acuerde de crearla.

-- ============================================================================
-- Tablas
-- ============================================================================

CREATE TABLE app.establishments (
    id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name               text NOT NULL CHECK (length(btrim(name)) BETWEEN 2 AND 120),
    category_id        uuid,  -- sin FK: el catálogo de categorías es de Persona 4
    address            text,
    city               text,
    status             text NOT NULL DEFAULT 'ACTIVE'
                       CHECK (status IN ('ACTIVE', 'SUSPENDED', 'CLOSED')),
    max_purchase_cents bigint CHECK (max_purchase_cents IS NULL OR max_purchase_cents > 0),
    compliance_status  text NOT NULL DEFAULT 'ACTIVE'
                       CHECK (compliance_status IN ('ACTIVE', 'OBSERVED', 'SUSPENDED', 'BLOCKED')),
    created_at         timestamptz NOT NULL DEFAULT now(),
    updated_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE app.branches (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    establishment_id uuid NOT NULL REFERENCES app.establishments(id) ON DELETE CASCADE,
    name             text NOT NULL CHECK (length(btrim(name)) BETWEEN 2 AND 120),
    address          text,
    status           text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'CLOSED')),
    created_at       timestamptz NOT NULL DEFAULT now()
);

-- Clave candidata que permite la FK compuesta de establishment_staff y de
-- purchases: la sucursal de un cajero debe pertenecer a SU comercio.
CREATE UNIQUE INDEX branches_id_establishment_uk ON app.branches (id, establishment_id);
CREATE INDEX branches_establishment_idx ON app.branches (establishment_id);

CREATE TABLE app.establishment_staff (
    establishment_id uuid NOT NULL REFERENCES app.establishments(id) ON DELETE CASCADE,
    user_id          uuid NOT NULL REFERENCES app.users(id) ON DELETE CASCADE,
    staff_role       text NOT NULL CHECK (staff_role IN ('OWNER', 'CASHIER')),
    branch_id        uuid,
    created_at       timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (establishment_id, user_id),
    -- Cajero: una sucursal fija y obligatoria. Dueño: ninguna, opera en todas
    -- (AGENTS.md §10.1).
    CONSTRAINT establishment_staff_branch_role_ck CHECK (
        (staff_role = 'CASHIER' AND branch_id IS NOT NULL) OR
        (staff_role = 'OWNER'   AND branch_id IS NULL)
    ),
    CONSTRAINT establishment_staff_branch_fk
        FOREIGN KEY (branch_id, establishment_id)
        REFERENCES app.branches (id, establishment_id)
);

CREATE INDEX establishment_staff_user_idx ON app.establishment_staff (user_id);

-- ============================================================================
-- Trigger de la sucursal "Principal"
-- ============================================================================
-- SECURITY DEFINER permite que paseo_app inserte un comercio sin que el trigger
-- le exija INSERT sobre branches (esta feature solo necesita SELECT ahí).

CREATE FUNCTION app.fn_create_default_branch() RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = app, pg_temp
AS $$
BEGIN
    INSERT INTO app.branches (establishment_id, name, address)
    VALUES (NEW.id, 'Principal', NEW.address);
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_establishments_default_branch
    AFTER INSERT ON app.establishments
    FOR EACH ROW EXECUTE FUNCTION app.fn_create_default_branch();

-- ============================================================================
-- GRANTs mínimos a paseo_app (AGENTS.md §5.3)
-- ============================================================================
-- Solo lectura: esta feature lee comercios/sucursales/personal pero no los crea.
-- El alta de comercios (Persona 4) ampliará con INSERT/UPDATE en una migración
-- nueva.

GRANT SELECT ON app.establishments      TO paseo_app;
GRANT SELECT ON app.branches            TO paseo_app;
GRANT SELECT ON app.establishment_staff TO paseo_app;
