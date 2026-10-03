-- V001__baseline_extensions.sql
-- Base: extensiones y esquema de la aplicación (9-stack §migraciones; INFRASTRUCTURE.md §4).
-- Se ejecuta como paseo_owner vía Flyway. La API nunca ejecuta DDL (AGENTS.md §5.1).

CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA app AUTHORIZATION paseo_owner;
GRANT USAGE ON SCHEMA app TO paseo_app;
GRANT USAGE ON SCHEMA app TO paseo_backup;
