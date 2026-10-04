-- V010__establishments_categoria_baja_logica.sql
-- Restaura sobre el V004 vigente lo que la spec 002 (data-model.md,
-- establishments) requiere y que el merge con main (0c8e51d) dejó fuera
-- al quedarse con el V004 de HU-Infra/003:
--   - category: etiqueta de texto visible al cliente en GET /establishments
--     (HU-09). El catálogo formal `category_id` sigue siendo de Persona 4;
--     cuando exista, una migración nueva podrá endurecer el esquema.
--   - deleted_at: baja lógica; los listados filtran `deleted_at IS NULL`
--     con índice parcial (data-model.md §establishments).
--
-- Filas preexistentes (seed dev anterior): backfill a 'OTRO' para poder
-- imponer NOT NULL. Bases migradas desde cero no tienen filas: el seed
-- dev siempre asigna la categoría al insertar.
--
-- Se ejecuta como paseo_owner vía Flyway. MVP sin RLS (decisión 03/10/2026).

ALTER TABLE app.establishments
    ADD COLUMN IF NOT EXISTS category   text,
    ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

UPDATE app.establishments SET category = 'OTRO' WHERE category IS NULL;

ALTER TABLE app.establishments
    ALTER COLUMN category SET NOT NULL,
    ALTER COLUMN category SET DEFAULT 'OTRO';

CREATE INDEX IF NOT EXISTS establishments_active_idx
    ON app.establishments (id) WHERE deleted_at IS NULL;
