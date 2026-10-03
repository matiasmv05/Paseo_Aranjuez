# INFRASTRUCTURE.md — Paseo Points

Dónde corre cada cosa y cómo se levanta. Es la fuente de verdad de la infraestructura; el capítulo 9 la resume en el Anexo A. Base para la sección 9.12 de Brayan.

> **Versiones verificadas con `docker pull` el 03/10/2026** (pendiente original cumplido):
> - PostgreSQL: `postgres:18-alpine` = **18.6**; `PGDATA=/var/lib/postgresql/18/docker`, por eso el volumen monta el padre `/var/lib/postgresql`.
> - Flyway: `flyway/flyway:13.9.0` (existe; reemplaza a la candidata 13.8.1 del borrador).
> - Caddy: `caddy:2.11.6-alpine`; Mailpit (dev): `axllent/mailpit:v1.27.9`; build API: `dart:3.13.5`.

---

## 1. Principio
Todo se levanta con **un comando**, sin Kubernetes ni microservicios. Un VPS con Docker Compose es suficiente y es lo más simple de explicar y depurar en una demo.

## 2. Mapa de servicios

| Servicio | Imagen / origen | Rol de BD | Puerto (interno) | Persistencia | Función |
|----------|-----------------|-----------|------------------|--------------|---------|
| `db` | `postgres:18-alpine` | `postgres_admin` (solo init) | 5432 | volumen `db_data` | PostgreSQL |
| `migrate` | `flyway/flyway:<fija>` | `paseo_owner` | — | — | Aplica `V###`, termina |
| `api` | `infra/api.Dockerfile` | `paseo_app` | 8080 | volumen `uploads` | API REST; guarda las fotos de factura |
| `worker` | misma imagen que `api`, comando `worker` | `paseo_app` | — | — | Jobs programados |
| `caddy` | `caddy:2` | — | 80, **443** (web comercio) y **8443** (web administración), públicos | volúmenes `caddy_data`, `caddy_config` | TLS, proxy y dos builds web |
| `backup` | `postgres:18-alpine` + `infra/backup/backup.sh` | `paseo_backup` | — | volumen `backups` | `pg_dump` periódico |
| `mailpit` | `axllent/mailpit` (solo `dev`) | — | 8025 (UI), 1025 (SMTP), solo `127.0.0.1` | — | Captura correos de prueba |

### Orden de arranque
```
db (healthy) ──► migrate (completed_successfully) ──► api ──► caddy
                                                  └─► worker
```

## 3. Redes y exposición
- Red interna única `paseo_net`.
- **Solo `caddy` publica puertos al exterior (80, 443 y 8443).**
- `db` **no publica puerto**. En desarrollo, el override lo publica solo en `127.0.0.1:5432`.
- `api` usa `expose: 8080` (no `ports`); solo `caddy` llega a ella.
- Firewall del VPS: 80, 443, **8443** (administración; restringir por IP si es posible) y SSH restringido por IP o llave.
- `uploads` **no** está montado en Caddy: las fotos solo salen por la API.

## 4. Roles y credenciales de base de datos

La imagen oficial de PostgreSQL crea un **superusuario** con `POSTGRES_USER`. **Ese usuario no se usa en la aplicación**: los superusuarios saltan RLS.

| Rol | Atributos | Lo usa | Privilegios |
|-----|-----------|--------|-------------|
| `postgres_admin` | superusuario | solo `db` en el init | todos |
| `paseo_owner` | `NOSUPERUSER`, dueño de la BD y objetos | Flyway | DDL |
| `paseo_app` | `NOSUPERUSER NOBYPASSRLS`, no dueño | `api`, `worker` | `GRANT` explícitos por tabla |
| `paseo_backup` | `BYPASSRLS`, miembro de `pg_read_all_data` | `backup` | lectura total |

> `pg_dump` con RLS activo falla o devuelve datos incompletos si el rol no puede saltar RLS; por eso `paseo_backup` tiene `BYPASSRLS`.

### `infra/db/init/01-roles.sh`
Se ejecuta **solo la primera vez**, cuando el volumen de datos está vacío. Si cambias roles después, hazlo en una migración o manualmente, no editando este script.

```bash
#!/bin/sh
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
```
Los `GRANT` sobre tablas **no** se hacen aquí: van en cada migración, junto con RLS (ver `AGENTS.md` §5.3). Las extensiones (`citext`, `pgcrypto`) las crea la migración `V001`.

## 5. Flyway

| Aspecto | Valor |
|---------|-------|
| Imagen | `flyway/flyway:<versión fija>` |
| Usuario | `paseo_owner` |
| Carpeta de migraciones | `infra/migrations/` montada en `/flyway/sql` (solo lectura) |
| Nombre de archivos | `V<NNN>__descripcion_snake_case.sql` |
| Semillas dev | `infra/seed/R__seed_dev.sql`, solo con el override `dev` |
| Seguridad | `FLYWAY_CLEAN_DISABLED=true`, validación de nombres activa |
| Política | Migraciones aplicadas inmutables; solo hacia adelante |

Configuración por variables de entorno. **Confirma los nombres exactos contra la documentación de la versión fijada.**

```yaml
migrate:
  image: flyway/flyway:13.8.1          # fijar la última que 'docker pull' confirme
  command: migrate
  environment:
    FLYWAY_URL: jdbc:postgresql://db:5432/${POSTGRES_DB}
    FLYWAY_USER: paseo_owner
    FLYWAY_PASSWORD: ${PASEO_OWNER_PASSWORD}
    FLYWAY_LOCATIONS: filesystem:/flyway/sql
    FLYWAY_VALIDATE_MIGRATION_NAMING: "true"
    FLYWAY_CLEAN_DISABLED: "true"
    FLYWAY_CONNECT_RETRIES: "10"
  volumes:
    - ./migrations:/flyway/sql:ro
  depends_on:
    db: { condition: service_healthy }
  networks: [paseo_net]
  restart: "no"
```

Override de desarrollo (`docker-compose.dev.yml`) añade la semilla:
```yaml
migrate:
  environment:
    FLYWAY_LOCATIONS: filesystem:/flyway/sql,filesystem:/flyway/seed
  volumes:
    - ./migrations:/flyway/sql:ro
    - ./seed:/flyway/seed:ro
```

## 6. `docker-compose.yml` (esqueleto)

```yaml
name: paseo

services:
  db:
    image: postgres:18-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: postgres_admin
      POSTGRES_PASSWORD: ${DB_SUPERUSER_PASSWORD}
      PASEO_OWNER_PASSWORD: ${PASEO_OWNER_PASSWORD}
      PASEO_APP_PASSWORD: ${PASEO_APP_PASSWORD}
      PASEO_BACKUP_PASSWORD: ${PASEO_BACKUP_PASSWORD}
    volumes:
      # PostgreSQL 18 cambió la ruta interna de datos; verificar en el README de la imagen
      # si el montaje correcto es /var/lib/postgresql o /var/lib/postgresql/data.
      - db_data:/var/lib/postgresql
      - ./db/init:/docker-entrypoint-initdb.d:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres_admin -d ${POSTGRES_DB}"]
      interval: 5s
      timeout: 3s
      retries: 20
    networks: [paseo_net]
    restart: unless-stopped

  migrate:
    # ver sección 5

  api:
    build: { context: .., dockerfile: infra/api.Dockerfile }
    env_file: .env
    environment:
      DB_HOST: db
      DB_NAME: ${POSTGRES_DB}
      DB_USER: paseo_app
      DB_PASSWORD: ${PASEO_APP_PASSWORD}
    depends_on:
      migrate: { condition: service_completed_successfully }
    volumes:
      - uploads:/data/uploads            # fotos de factura (UPLOADS_DIR), nunca servido por Caddy
    expose: ["8080"]
    healthcheck:
      test: ["CMD", "/app/healthcheck"]   # llama a GET /health
      interval: 10s
    user: "10001:10001"
    read_only: true
    networks: [paseo_net]
    restart: unless-stopped

  worker:
    build: { context: .., dockerfile: infra/api.Dockerfile }
    command: ["/app/worker"]
    env_file: .env
    environment:
      DB_HOST: db
      DB_NAME: ${POSTGRES_DB}
      DB_USER: paseo_app
      DB_PASSWORD: ${PASEO_APP_PASSWORD}
    depends_on:
      migrate: { condition: service_completed_successfully }
    user: "10001:10001"
    networks: [paseo_net]
    restart: unless-stopped

  caddy:
    image: caddy:2
    ports: ["80:80", "443:443", "8443:8443"]
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ../apps/mobile/build/web-merchant:/srv/web-merchant:ro   # web comercio (443)
      - ../apps/mobile/build/web-admin:/srv/web-admin:ro         # web administración (8443)
      - caddy_data:/data
      - caddy_config:/config
    depends_on: [api]
    networks: [paseo_net]
    restart: unless-stopped

  backup:
    image: postgres:18-alpine
    environment:
      PGHOST: db
      PGDATABASE: ${POSTGRES_DB}
      PGUSER: paseo_backup
      PGPASSWORD: ${PASEO_BACKUP_PASSWORD}
    volumes:
      - ./backup/backup.sh:/backup.sh:ro
      - backups:/backups
      - uploads:/uploads:ro              # se respalda junto con la base
    entrypoint: ["/bin/sh", "/backup.sh"]
    depends_on:
      db: { condition: service_healthy }
    networks: [paseo_net]
    restart: unless-stopped

networks:
  paseo_net: {}

volumes:
  db_data: {}
  caddy_data: {}
  caddy_config: {}
  backups: {}
  uploads: {}
```

`docker-compose.dev.yml` añade: `db` publicado en `127.0.0.1:5432`, `mailpit` (perfil `dev`), semilla en `migrate` y variables de desarrollo (`OTP_SENDER=console`, `SMTP_HOST=mailpit`).

## 7. Variables de entorno

La plantilla `infra/.env.example` va en el repositorio con valores ficticios; `.env` real **nunca** se versiona.

| Variable | Usada por | Descripción |
|----------|-----------|-------------|
| `POSTGRES_DB` | db, migrate, api, backup | Nombre de la BD |
| `DB_SUPERUSER_PASSWORD` | db | Superusuario; solo init |
| `PASEO_OWNER_PASSWORD` | db (init), migrate | Contraseña de `paseo_owner` |
| `PASEO_APP_PASSWORD` | db (init), api, worker | Contraseña de `paseo_app` |
| `PASEO_BACKUP_PASSWORD` | db (init), backup | Contraseña de `paseo_backup` |
| `JWT_SECRET` | api | Secreto de firma (largo y aleatorio) |
| `JWT_KID` | api | Identificador de clave, para rotarla |
| `JWT_ACCESS_TTL_SECONDS` | api | 900 (15 min) |
| `REFRESH_TTL_DAYS` | api | 7 a 30 |
| `QR_TOKEN_TTL_SECONDS` | api | ~60 |
| `OTP_SENDER` | api, worker | `console` (dev) o el adaptador real elegido |
| `OTP_PROVIDER_*` | api | Credenciales del proveedor (**por decidir**) |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM` | api, worker | Correo saliente |
| `FCM_*` | api, worker | Credenciales push (cuando se implemente) |
| `PUBLIC_BASE_URL` | api, caddy | Dominio público |
| `PHONE_COUNTRY` | api | `BO`: solo teléfonos bolivianos (`+591`) |
| `UPLOADS_DIR` | api | Ruta del volumen de facturas (no servida por Caddy) |
| `UPLOAD_MAX_BYTES` | api | Tamaño máximo de la foto de factura (valor inicial propuesto: 5 MB) |
| `WEB_MERCHANT_ORIGIN`, `WEB_ADMIN_ORIGIN` | api | Orígenes CORS explícitos y distintos |
| `ADMIN_ALLOWED_IPS` | caddy | Lista de IP permitidas en el puerto 8443 (opcional) |
| `PUBLIC_HOST` | caddy | Nombre de host para los dos sitios |
| `REFUND_WINDOW_DAYS` | api, worker | Días máximos desde la compra para solicitar reembolso (**valor por decidir**) |
| `REFUND_REQUEST_TTL_DAYS` | worker | Días tras los cuales una solicitud `PENDING` pasa a `EXPIRED` (opcional; por decidir) |

## 8. Worker (jobs programados)
Mismo binario que la API, distinto punto de entrada (`bin/worker.dart`). Lo necesitan los requisitos de la encuesta.

| Job | Frecuencia | Qué hace |
|-----|-----------|----------|
| Resumen de ventas | diario/semanal | Genera notificación y correo por comercio |
| Recordatorio de fechas | diario | Revisa `special_dates` y avisa a dueños |
| Limpieza | cada hora | Borra OTP, tokens de recuperación y QR vencidos |
| Antifraude (si se agrupa) | cada pocos minutos | Evalúa reglas sobre compras y reembolsos recientes |
| Expiración de reembolsos | diario | Pasa a `EXPIRED` las solicitudes `PENDING` vencidas (solo si se adopta vencimiento) |
| Aviso de reembolsos pendientes | diario | Notifica al admin las solicitudes sin resolver |

Si el worker cae, la API sigue funcionando; solo se retrasan avisos y limpieza.

## 9. Caddy
- TLS automático para el dominio de `PUBLIC_HOST` (el DNS debe apuntar al VPS).
- **Dos sitios:** `PUBLIC_HOST` (443) sirve la **web de comercio**; `PUBLIC_HOST:8443` sirve la **web de administración**. En ambos, `/api/*` → `api:8080`.
- Las cookies **no se aíslan por puerto**: cada web usa su propio nombre de cookie y su propia audiencia `aud` (ver `AGENTS.md` §6).
- Validar el Caddyfile con `caddy validate` y comprobar en el servidor real que el HTTPS automático funciona en el puerto 8443.
- Alternativa más aislada si el DNS lo permite: dos subdominios en lugar de dos puertos.
- Cabeceras de seguridad básicas y compresión.
- La base de datos y el worker nunca están detrás de Caddy.

## 10. Entornos

| Entorno | Dónde | Notas |
|---------|-------|-------|
| Local | Compose en cada laptop (`-f` base + `dev`) | Semillas, Mailpit, OTP por consola |
| Demo/producción | VPS pequeño con el mismo Compose (sin override `dev`) | Sin semillas; OTP y SMTP reales |

Evitar planes gratuitos con cuotas que puedan apagar la demo.

## 11. CI/CD
1. **Pull Request:** formato, análisis, pruebas, validación de `openapi.yaml`, verificación de la regla hexagonal, **PostgreSQL efímero + Flyway desde cero + pruebas RLS**, rechazo de PR que modifique una migración ya presente en `main`.
2. **Merge a `main`:** construir imagen de la API y publicarla en un registro de contenedores.
3. **Despliegue:** SSH al VPS, `docker compose pull && docker compose up -d`. El servicio `migrate` corre antes que `api` y `worker`.
4. **Móvil/web:** build de APK de prueba y de `flutter build web` como artefactos.

## 12. Respaldos y recuperación
- `pg_dump` diario comprimido con `paseo_backup` **más copia del volumen `uploads`** (facturas), retención de varios días y **copia fuera del servidor**.
- **Probar la restauración al menos una vez** en una BD vacía, y comprobar que RLS, roles y triggers existen tras restaurar. Un respaldo no probado no cuenta (RNF-09).
- Recordar que `pg_dump` no incluye los roles del clúster: restaurar implica volver a ejecutar `infra/db/init/01-roles.sh` o `pg_dumpall --roles-only`.

## 13. Observabilidad mínima
- Logs JSON a stdout, con `correlation_id` por petición (presente en `audit_log`).
- `GET /health` (vivo) y `GET /ready` (con chequeo de BD).
- **Prohibido registrar** contraseñas, OTP, tokens, teléfonos y correos completos.

## 14. Seguridad de infraestructura
- Secretos solo por variables de entorno; `.env` fuera del repo.
- Imagen de la API mínima, usuario no root, sistema de archivos de solo lectura.
- Actualizar imágenes base y escanear dependencias en CI.
- Firewall: solo 80/443 y SSH restringido.
- Un MCP de base de datos para agentes: solo local, con rol de solo lectura; nunca `postgres_admin`, `paseo_owner` ni datos reales.

## 15. Mapa de directorios (dónde está qué)

| Ruta | Contenido | Quién lo modifica |
|------|-----------|-------------------|
| `infra/docker-compose.yml` | Servicios base | Infra |
| `infra/docker-compose.dev.yml` | Override de desarrollo | Infra |
| `infra/api.Dockerfile` | Imagen multi-stage de la API y el worker | Infra |
| `infra/Caddyfile` | Proxy y TLS; dos sitios (443 y 8443) | Infra |
| `apps/mobile/build/web-merchant`, `build/web-admin` | Salida de los dos builds web (no versionada) | CI / build |
| `infra/db/init/` | Roles (solo primer arranque) | Infra; cambios excepcionales |
| `infra/migrations/` | `V###__*.sql` Flyway | Cualquiera, **solo añadiendo** archivos |
| `infra/seed/` | `R__seed_dev.sql` | Solo desarrollo |
| `infra/backup/` | `backup.sh` y notas de restauración | Infra |
| `infra/.env.example` | Plantilla de variables | Infra |

## 16. Comandos útiles

```bash
# Levantar todo en desarrollo
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d

# Estado y validación de migraciones
docker compose -f infra/docker-compose.yml run --rm migrate info
docker compose -f infra/docker-compose.yml run --rm migrate validate

# Reiniciar la base de DESARROLLO desde cero (destruye datos; nunca en producción)
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml down -v
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d

# Ver correos de prueba: http://127.0.0.1:8025

# Restaurar un respaldo en una BD vacía (prueba de recuperación)
gunzip -c backups/<archivo>.sql.gz | psql -h <host> -U paseo_owner -d <bd_vacia>
```

## 17. Pendientes de infraestructura
1. ~~Confirmar etiquetas de imagen (PostgreSQL 18 y Flyway) con `docker pull`~~ — hecho 03/10/2026.
2. ~~Confirmar la ruta de montaje de datos de PostgreSQL 18~~ — hecho: `PGDATA=/var/lib/postgresql/18/docker`.
3. Confirmar los nombres de las variables `FLYWAY_*` en la documentación de la versión fijada.
4. Elegir proveedor de OTP por teléfono y de correo (no verificados) y su costo.
5. Dónde se despliega la demo y qué dominio se usa (sin decisión del equipo; recomendación: VPS con Docker Compose).
   Probar el HTTPS automático de Caddy en el puerto 8443.
6. Política de retención de respaldos y a dónde se copian.
7. Valor inicial de `REFUND_WINDOW_DAYS`, si las solicitudes `PENDING` vencen, tamaño máximo y **retención** de las fotos de factura.
8. Respaldos: confirmar que el script incluye el volumen `uploads` además de `pg_dump`.
