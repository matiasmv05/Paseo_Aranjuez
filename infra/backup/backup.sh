#!/bin/sh
# infra/backup/backup.sh — respaldo periódico: pg_dump + volumen `uploads`.
# Rol: paseo_backup (BYPASSRLS + pg_read_all_data). INFRASTRUCTURE.md §12.
# OJO: pg_dump no incluye los roles del clúster; al restaurar hay que recrear
# los roles con infra/db/init/01-roles.sh (o `pg_dumpall --roles-only`).
set -eu

KEEP_DAYS="${BACKUP_KEEP_DAYS:-14}"
INTERVAL="${BACKUP_INTERVAL_SECONDS:-86400}"

while true; do
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  dest="/backups/$ts"
  mkdir -p "$dest"

  pg_dump --format=custom --compress=9 --file="$dest/db.dump"
  tar -czf "$dest/uploads.tar.gz" -C / uploads

  find /backups -mindepth 1 -maxdepth 1 -type d -mtime "+$KEEP_DAYS" -exec rm -rf {} +

  echo "[backup] $ts listo"
  sleep "$INTERVAL"
done
