# Agent Audit — Paseo Points

Fecha de auditoría: 02/10/2026
Estado: DONE (auditoría documental inicial). No se implementaron cambios de comportamiento ni infraestructura.

## CURRENT_STATE

DOCUMENTED:
- El repositorio está en fase de documentación, no en fase implementada.
- Existen solo 3 archivos de contexto en la raíz: `AGENTS.md`, `INFRASTRUCTURE.md`, `9-stack-tecnologico-paseo-points.md`.
- `AGENTS.md` declara reglas innegociables, arquitectura objetivo, endpoints/contratos esperados y decisiones abiertas.
- `INFRASTRUCTURE.md` define servicios objetivo, roles de base de datos, Flyway, variables de entorno, CI/CD, respaldos y pendientes de infraestructura.
- `9-stack-tecnologico-paseo-points.md` define stack, arquitectura, ADR/roadmap, endpoints MVP, matriz de pruebas y decisiones del equipo.

IMPLEMENTED:
- No hay código fuente (`apps/`, `packages/` no existen).
- No hay infraestructura implementada (`infra/` no existe).
- No hay contrato OpenAPI (`docs/openapi.yaml` no existe).
- Base SDD inicial creada: `.specify/memory/constitution.md`, `.specify/templates/*.md` y `specs/README.md`.
- No hay specs de features aprobadas (`specs/<feature>/` aún no existe).
- Plan de esta fase documentado en `docs/superpowers/plans/sdd-foundation.md`.
- Contrato base `docs/openapi.yaml` creado el 03/10/2026 (OpenAPI 3.1): sobre común (servidor `/api/v1`, `Problem` RFC 9457, `bearerAuth` con audiencias, `Idempotency-Key`, `MoneyCents`, `CursorPage`), `GET /health`, `GET /ready` y los 8 endpoints de auth ya decididos en `AGENTS.md` §6/§8. Validado con `redocly lint` (0 errores, 7 warnings intencionales).
- Monorepo pub workspaces creado el 03/10/2026: `.fvmrc` (Flutter 3.47.6 / Dart 3.13.5, estable oficial 01/10/2026), `pubspec.yaml` con miembros `apps/api`, `apps/mobile`, `packages/paseo_shared` (stubs sin lógica), `pubspec.lock` versionado y `analysis_options.yaml` único con `very_good_analysis` 11.0.0. FVM 4.3.1 instalado (scoop). `fvm flutter pub get`, `fvm dart analyze` y `fvm dart format` en verde.
- No hay configuración CI (`.github/` no existe).
- Existe `CLAUDE.md` con la línea requerida `@AGENTS.md`.

TESTED:
- No existen pruebas ni harness de pruebas.

VERIFIED:
- Al inicio de la auditoría `git status` falló; después el repositorio fue conectado y quedó activo en `main...origin/main`.
- Inicialmente la raíz contenía solo los tres documentos citados; luego se añadieron `.gitignore`, `CLAUDE.md`, `.specify/` y `specs/README.md`.
- Se leyeron `AGENTS.md`, `INFRASTRUCTURE.md` y `9-stack-tecnologico-paseo-points.md`.
- Se verificó la ausencia inicial de `.fvmrc`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `apps/`, `packages/`, `infra/` y `.github/`; esas ausencias siguen vigentes.

## MISSING

- Inicialización git completada; faltan reglas efectivas de rama/protección verificadas en GitHub.
- `CLAUDE.md` con contenido `@AGENTS.md` ya existe.
- Estructura objective completada como stubs; pendiente poblar: esqueleto Dart Frog (`bin/server.dart`, `bin/worker.dart`), entradas web `main_merchant_web.dart`/`main_admin_web.dart` y contenido de `paseo_shared`.
- Infraestructura base creada el 03/10/2026: `infra/docker-compose.yml` (+`dev`), `db/init/01-roles.sh`, `.env.example`, `Caddyfile`, `api.Dockerfile`, `backup/backup.sh`, `seed/R__seed_dev.sql` y `migrations/V001__baseline_extensions_y_esquema.sql`. Imágenes verificadas con `docker pull`: `postgres:18-alpine` (18.6, PGDATA=/var/lib/postgresql/18/docker), `flyway/flyway:13.9.0`, `caddy:2.11.6-alpine`, `dart:3.13.5`. Verificado en vivo: `migrate info` (V001 Success), roles sin superuser y `paseo_app` NOBYPASSRLS, extensiones citext/pgcrypto, esquema `app` con USAGE y DDL denegado a `paseo_app`, `caddy validate` OK. Proyecto Compose renombrado a `paseo-aranjuez` (03/10). **Decisión 03/10/2026: sin Mailpit**; correo real vía `SmtpEmailSender` propio tras el puerto `EmailSender` (proveedor SMTP sigue abierto).
- Migraciones `V002`–`V010` (según 9-stack) y pruebas RLS asociadas: **V002 (identidad) queda BLOCKED hasta la spec de identidad** y la decisión del proveedor/regex de teléfono.
- CI inicial creado el 03/10/2026: `.github/workflows/ci.yml` con jobs `dart` (format/analyze/test condicionales), `openapi` (redocly), `migrations` (DB desde cero + Flyway + chequeos de roles/extensiones/DDL denegado + hook de pruebas RLS `infra/tests/rls/`) y `migration-immutability` (rechaza mutar `V###` existentes en `main`). YAML validado localmente y comandos de los jobs verificados contra el stack local; la ejecución real en GitHub Actions queda pendiente del primer PR/push.
- Monorepo pub workspaces: creado 03/10/2026 (`.fvmrc`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`); pendiente poblar los paquetes.
- Estructura objetivo: directorios creados como stubs; faltan Dart Frog, las tres entradas web y features de Flutter.
- Esqueleto Dart Frog de API y worker.
- Esqueleto Flutter con tres entradas: `main.dart`, `main_merchant_web.dart`, `main_admin_web.dart`.
- `packages/paseo_shared` con DTOs/enums/errores de contrato.
- `docs/openapi.yaml` línea base creada (03/10/2026); pendiente extenderla con cada spec de feature.
- Specs de features aprobadas en `specs/<feature>/`.
- `infra/docker-compose.yml`, `infra/docker-compose.dev.yml`, `infra/api.Dockerfile`, `infra/Caddyfile`, `infra/.env.example`, `infra/db/init/`, `infra/migrations/`, `infra/seed/`, `infra/backup/`.
- Migraciones Flyway iniciales previstas (`V001`–`V010`) y pruebas RLS asociadas.
- CI para formato, análisis, pruebas, OpenAPI, arquitectura, migraciones desde cero, RLS, builds y escaneo.
- Configuración local de agentes/MCP auditada y de solo lectura para base local.

## CONTRADICTIONS

- `AGENTS.md` y el stack citan `specs/` y `docs/openapi.yaml`; ambos existen ya en su forma base (respectivamente 02/10 y 03/10/2026). La extensión del contrato queda sujeta a specs de feature aprobadas.
- ~~`INFRASTRUCTURE.md` fija `postgres:18-alpine` y Flyway candidato pendiente de `docker pull`~~ **RESUELTA (03/10):** postgres 18.6, flyway 13.9.0 y demás etiquetas confirmadas con pull real.
- No se detectó contradicción entre decisiones cerradas y reglas actuales, pero faltan artefactos normativos (`specs/`, OpenAPI, CI) para validarlas contra implementación.

## DECISIONES DE EQUIPO (03/10/2026)

- **MVP sin RLS** (supersede AGENTS.md §2 regla 7 y §5.3 para el MVP): decisión explícita del dueño. Las tablas nacen solo con `GRANT` mínimos; el aislamiento multi-comercio se aplica en middleware de aplicación. Ver §BLOCKERS.

## BLOCKERS

- **RLS + pruebas de aislamiento**: deuda **bloqueante** que debe reintroducirse antes de cualquier despliegue con datos reales (decisión 03/10/2026: se quitó RLS del MVP a pedido del dueño). Mientras tanto el aislamiento descansa en el middleware de la API, y `paseo_app` conserva `NOBYPASSRLS` y `GRANT` mínimos como mitigación parcial.

## OPEN_DECISIONS

No resolver sin decisión humana:
- Destino del despliegue/demo.
- Recorte de hexagonal en Flutter.
- `invoice_ref` obligatorio u opcional por comercio.
- Confirmación de interpretaciones de encuesta: refresh web en cookie `HttpOnly`; SMS mínimo con correo adicional sin exigir correo para acumular.
- ~~Proveedor de SMS y correo, con costo real~~ — correo **DECIDIDO 03/10/2026**: Gmail/Google Workspace SMTP, `SmtpEmailSender` propio ; SMS: **sigue ABIERTO**.
- ~~Librería Argon2id tras benchmark~~ — **DECIDIDA 03/10/2026**: `cryptography` 2.9.0 (PHC verificado contra el binario C oficial; ~190 ms con parámetros OWASP). Detalle: `specs/001-identidad/research.md`.
- Valores iniciales de `refund_window_days`, vencimiento de solicitudes, tamaño máximo y retención de fotos.
- Razón social del comprador o del emisor.
- Verificación del plan de numeración boliviano (`+591`, 8 dígitos, inicia 6 o 7).
- Motivo opcional en reembolso.
- Sucursal "Principal" automática.
- HTTPS de Caddy en puerto 8443 y posible migración a subdominios.

## SECURITY_RISKS

- Existen `.gitignore` básico y git activo; falta `infra/.env.example` y controles CI para reducir el riesgo de filtrar secretos.
- No hay aislamiento reproducible de base de datos local ni rol de solo lectura para agentes/MCP.
- No hay CI que bloquee migraciones mutadas, ausencia de RLS, PII en claims/logs o infracciones de arquitectura.
- No se han verificado imágenes Docker fijas; usar etiquetas no confirmadas puede romper reproducibilidad.
- No hay controles implementados para cookies web separadas, CORS explícito, auditoría, subida segura de fotos, Argon2id, OTP/SMS ni recuperación.
- No hay política de retención definida para fotos de factura con posibles datos personales.

## INFRASTRUCTURE_GAPS

- No existe `infra/`: faltan Compose base/dev, Dockerfile de API/worker, Caddyfile, scripts de init, migraciones, semillas, backup y `.env.example`.
- Pendiente fijar versiones con `docker pull` antes de escribir Compose definitivo.
- Pendiente confirmar ruta de datos de PostgreSQL 18 en la imagen oficial.
- Pendiente confirmar variables `FLYWAY_*` exactas para la versión fijada.
- Pendiente validar `caddy validate` y HTTPS automático en puerto 8443 en el servidor real.
- Pendiente definir respaldo/restauración probada, incluyendo volumen `uploads` y recreación de roles tras restaurar.
- Pendiente definir retención/copia externa de respaldos.

## AGENT_SYSTEM_GAPS

- `.specify/` y plantillas base de Spec Kit ya existen; no se instaló ningún CLI/plugin externo.
- `CLAUDE.md` exigido por `AGENTS.md` ya existe con `@AGENTS.md`.
- No hay configuración de CI ni chequeos automáticos para delegación segura.
- No hay definición operativa de gates ejecutables (comandos CI) más allá de los comandos objetivo descritos.
- No hay configuración local de herramientas/MCP para base local de solo lectura.
- No hay pruebas ni fixtures que permitan verificar que los agentes no violan RLS, cookies, auditoría o contratos.

## DEPENDENCIES

- Git inicializado y reglas de rama antes de PR/CI.
- Decisión/confirmación humana sobre pendientes abiertos antes de implementaciones bloqueantes.
- Herramientas locales: Docker, Docker Compose, FVM/Flutter/Dart.
- Imágenes Docker verificadas por `docker pull`: PostgreSQL 18, Flyway fijo, Caddy 2, Mailpit dev.
- Spec Kit local ya tiene constitución, plantillas y punto de entrada de `specs/`; la primera spec de feature aún requiere aprobación humana.
- OpenAPI inicial antes de rutas y uso compartido de contratos.
- Migraciones base antes de pruebas RLS/integración.
- Puertos/adaptadores de identidad antes de elegir proveedor SMS/correo concreto.

## EXECUTION_ORDER

1. GATE 0: Mantener este audit como línea base y no iniciar features sobre supuestos.
2. DONE: Inicializar git y archivos base mínimos no conductuales: `.gitignore`, `CLAUDE.md` (`@AGENTS.md`).
3. DONE: Crear/instalar SDD local: `.specify/`, constitución referenciando `AGENTS.md`, plantillas de spec/plan/tasks y `specs/README.md`.
4. DONE (03/10): Contrato inicial `docs/openapi.yaml` (sobre común + health + auth, alcance aprobado por usuario).
5. DONE (03/10): Monorepo con FVM (3.47.6), `pubspec.yaml` workspace y `analysis_options.yaml` estricto; verificado con pub get/analyze/format.
6. DONE (03/10, parcial): Compose base/dev, roles, `.env.example`, Dockerfile API/worker, Caddyfile, backup, `V001` con verificación en vivo. Pendiente: `V002` (identidad, BLOCKED por spec), imagen de la API buildable (requiere esqueleto Dart Frog) y pruebas RLS automatizadas.
7. DONE (03/10, parcial): CI inicial con formato, análisis, OpenAPI, migraciones desde cero, chequeos RLS/roles y protección de inmutabilidad. Pendiente: job de arquitectura hexagonal y de builds cuando exista código; verificación real en GitHub Actions con el primer PR.
8. Fundaciones de identidad: Argon2id benchmark, proveedor SMS/correo tras puertos, OTP/recuperación.
9. Rebanada vertical Must: registro/verificación/login/QR/teléfono/preview/compra/saldo/canje/validación.
10. Resto de Must: dos webs, reglas admin, reembolsos, sucursales, `system_settings`, auditoría.
11. Should/Could solo después de verify/integrate de Must.

## BLOCKERS

- `BLOCKED`: feature implementation general, porque faltan specs de features aprobadas, `docs/openapi.yaml`, código, infraestructura y CI.
- `BLOCKED`: validación de migraciones y RLS, porque no existe `infra/` ni base local reproducible.
- `BLOCKED`: verificación de imágenes/versiones, porque requiere `docker pull` real y aún no hay Compose.
- `BLOCKED`: elección irreversible de proveedor SMS/correo, librería Argon2id y valores de reembolso; son decisiones abiertas.
- `NEEDS_REVIEW`: flujo git/protección de rama/CI, porque git está conectado pero no se verificaron protecciones remotas ni CI.

## NEXT_GATES

- GATE 0 — source-of-truth audit: DONE para documentación disponible.
- GATE 1 — contradictions resolved: NEEDS_REVIEW por `docs/openapi.yaml`/CI ausentes y versiones Docker pendientes.
- GATE 2 — spec valid/approved: BLOCKED hasta crear/aprobar la primera spec de feature.
- GATE 3 — plan valid: BLOCKED.
- GATE 4 — API contract valid: DONE para la línea base (health + auth); BLOCKED para endpoints de negocio hasta sus specs.
- GATE 5 — architecture valid: DOCUMENTED, no VERIFIED.
- GATE 6 — migrations valid: `V001` VERIFIED en vivo (flyway info Success + chequeos de permisos); `V002` BLOCKED por spec de identidad.
- GATE 7 — RLS tests valid: BLOCKED.
- GATE 12 — CI valid: DOCUMENTED + comandos verificados localmente; PENDING ejecución real en GitHub.
- GATE 13 — human review: REQUIRED antes de fundaciones amplias y antes de resolver decisiones abiertas.
