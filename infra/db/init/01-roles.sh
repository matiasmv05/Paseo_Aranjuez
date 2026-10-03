#!/bin/sh
# infra/db/init/01-roles.sh — se ejecuta SOLO la primera vez (volumen vacío).
# Cambios posteriores: migración nueva, no editar este script (INFRASTRUCTURE.md §4).
set -eu
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<SQL
CREATE ROLE paseo_owner  LOGIN PASSWORD '${PASEO_OWNER_PASSWORD}'  NOSUPERUSER NOCREATEROLE;
CREATE ROLE paseo_app    LOGIN PASSWORD '${PASEO_APP_PASSWORD}'    NOSUPERUSER NOCREATEROLE NOBYPASSRLS;
CREATE ROLE paseo_backup LOGIN PASSWORD '${PASEO_BACKUP_PASSWORD}' NOSUPERUSER NOCREATEROLE BYPASSRLS;
GRANT pg_read_all_data TO paseo_backup;

ALTER DATABASE ${POSTGRES_DB} OWNER TO paseo_owner;
GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO paseo_app, paseo_backup;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO paseo_app, paseo_backup;
ALTER SCHEMA public OWNER TO paseo_owner;
SQL
