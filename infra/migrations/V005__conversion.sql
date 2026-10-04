-- V005__conversion.sql
-- Reglas de conversión de puntos (points_rules), versionadas.
-- Se ejecuta como paseo_owner vía Flyway.
-- Una regla activa NUNCA se edita: para cambiarla se inserta una versión nueva y
-- a la anterior se le pone valid_to. "Activa" = valid_to IS NULL AND valid_from <= now().
-- Solo `admin` escribe reglas (Persona 4); esta feature las lee.
-- category_id sin FK: el catálogo de categorías es de Persona 4.

-- ============================================================================
-- Tablas
-- ============================================================================

CREATE TABLE app.points_rules (
    id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    scope                   text NOT NULL CHECK (scope IN ('ESTABLISHMENT', 'CATEGORY', 'GLOBAL')),
    type                    text NOT NULL CHECK (type IN ('BASE', 'CAMPAIGN')),
    establishment_id        uuid REFERENCES app.establishments(id) ON DELETE CASCADE,
    category_id             uuid,
    priority                int NOT NULL DEFAULT 100,
    points_awarded          int NOT NULL CHECK (points_awarded > 0),
    amount_per_tier_cents   bigint NOT NULL CHECK (amount_per_tier_cents > 0),
    multiplier_bp           int NOT NULL DEFAULT 10000 CHECK (multiplier_bp >= 0),
    max_points_per_purchase int CHECK (max_points_per_purchase IS NULL OR max_points_per_purchase >= 0),
    min_purchase_cents      bigint NOT NULL DEFAULT 0 CHECK (min_purchase_cents >= 0),
    rounding                text NOT NULL DEFAULT 'FLOOR' CHECK (rounding IN ('FLOOR', 'ROUND', 'CEIL')),
    valid_from              timestamptz NOT NULL DEFAULT now(),
    valid_to                timestamptz,
    created_at              timestamptz NOT NULL DEFAULT now(),
    -- El alcance determina qué columna de destino es obligatoria y cuál nula.
    CONSTRAINT points_rules_scope_target_ck CHECK (
        (scope = 'ESTABLISHMENT' AND establishment_id IS NOT NULL AND category_id IS NULL) OR
        (scope = 'CATEGORY'      AND category_id      IS NOT NULL AND establishment_id IS NULL) OR
        (scope = 'GLOBAL'        AND establishment_id IS NULL     AND category_id IS NULL)
    ),
    CONSTRAINT points_rules_validity_ck CHECK (valid_to IS NULL OR valid_to > valid_from)
);

CREATE INDEX points_rules_active_idx         ON app.points_rules (scope, priority) WHERE valid_to IS NULL;
CREATE INDEX points_rules_establishment_idx ON app.points_rules (establishment_id) WHERE establishment_id IS NOT NULL;
CREATE INDEX points_rules_category_idx      ON app.points_rules (category_id)      WHERE category_id IS NOT NULL;

-- ============================================================================
-- GRANTs mínimos a paseo_app (AGENTS.md §5.3)
-- ============================================================================
-- Solo lectura, y es deliberado: el comercio no tiene endpoints de reglas.
-- Solo `admin` escribe y lo hará Persona 4 con su propia migración.

GRANT SELECT ON app.points_rules TO paseo_app;
