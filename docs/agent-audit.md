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
- No hay especificaciones SDD (`specs/` no existe).
- No hay plantillas Spec Kit (`.specify/` no existe).
- No hay workspace Dart (`pubspec.yaml` no existe).
- No hay configuración Flutter/Dart/FVM (`.fvmrc` no existe).
- No hay configuración CI (`.github/` no existe).
- No hay `CLAUDE.md` con la línea requerida `@AGENTS.md`.

TESTED:
- No existen pruebas ni harness de pruebas.

VERIFIED:
- `git status` falló: el directorio no es un repositorio git.
- La raíz contiene solo los tres documentos citados.
- Se leyeron `AGENTS.md`, `INFRASTRUCTURE.md` y `9-stack-tecnologico-paseo-points.md`.
- Se verificó la ausencia de `.git`, `.fvmrc`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `docs/`, `specs/`, `.specify/`, `apps/`, `packages/`, `infra/`, `.github/` y `CLAUDE.md`.

## MISSING

- Inicialización git y rama/protección base.
- `CLAUDE.md` con contenido `@AGENTS.md`.
- Monorepo pub workspaces: `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`.
- FVM: `.fvmrc` y versión fijada de Flutter/Dart.
- Estructura objetivo: `apps/mobile`, `apps/api`, `packages/paseo_shared`.
- Esqueleto Dart Frog de API y worker.
- Esqueleto Flutter con tres entradas: `main.dart`, `main_merchant_web.dart`, `main_admin_web.dart`.
- `packages/paseo_shared` con DTOs/enums/errores de contrato.
- `docs/openapi.yaml` inicial.
- `specs/` con flujo SDD por feature.
- `.specify/` con constitución/plantillas de Spec Kit.
- `infra/docker-compose.yml`, `infra/docker-compose.dev.yml`, `infra/api.Dockerfile`, `infra/Caddyfile`, `infra/.env.example`, `infra/db/init/`, `infra/migrations/`, `infra/seed/`, `infra/backup/`.
- Migraciones Flyway iniciales previstas (`V001`–`V010`) y pruebas RLS asociadas.
- CI para formato, análisis, pruebas, OpenAPI, arquitectura, migraciones desde cero, RLS, builds y escaneo.
- Configuración local de agentes/MCP auditada y de solo lectura para base local.

## CONTRADICTIONS

- `AGENTS.md` y el stack citan como fuentes complementarias `specs/` y `docs/openapi.yaml`, pero esos artefactos aún no existen. No es una contradicción semántica si se interpreta como monorepo objetivo, pero bloquea cualquier trabajo que exija esos contratos.
- `INFRASTRUCTURE.md` fija `postgres:18-alpine` y una versión Flyway candidata, pero marca que las etiquetas deben verificarse con `docker pull`; hasta hacerlo, la reproducibilidad queda pendiente.
- El stack indica una versión concreta de Flyway (`13.8.1`) y a la vez ordena fijar la más reciente confirmada; no debe implementarse una versión sin verificación real.
- No se detectó contradicción entre decisiones cerradas y reglas actuales, pero faltan artefactos normativos (`specs/`, OpenAPI, CI) para validarlas contra implementación.

## OPEN_DECISIONS

No resolver sin decisión humana:
- Destino del despliegue/demo.
- Recorte de hexagonal en Flutter.
- `invoice_ref` obligatorio u opcional por comercio.
- Confirmación de interpretaciones de encuesta: refresh web en cookie `HttpOnly`; SMS mínimo con correo adicional sin exigir correo para acumular.
- Proveedor de SMS y correo, con costo real.
- Librería Argon2id tras benchmark y vectores de prueba.
- Valores iniciales de `refund_window_days`, vencimiento de solicitudes, tamaño máximo y retención de fotos.
- Razón social del comprador o del emisor.
- Verificación del plan de numeración boliviano (`+591`, 8 dígitos, inicia 6 o 7).
- Motivo opcional en reembolso.
- Sucursal "Principal" automática.
- HTTPS de Caddy en puerto 8443 y posible migración a subdominios.

## SECURITY_RISKS

- No hay `.gitignore`, `.env.example` ni control de versiones activo: riesgo alto de filtrar secretos si se inicializa sin plantillas.
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

- No existe `.specify/` para SDD; no hay plantillas de spec/plan/tasks.
- No existe `CLAUDE.md` exigido por `AGENTS.md` con `@AGENTS.md`.
- No hay configuración de CI ni chequeos automáticos para delegación segura.
- No hay definición operativa de gates ejecutables (comandos CI) más allá de los comandos objetivo descritos.
- No hay configuración local de herramientas/MCP para base local de solo lectura.
- No hay pruebas ni fixtures que permitan verificar que los agentes no violan RLS, cookies, auditoría o contratos.

## DEPENDENCIES

- Git inicializado y reglas de rama antes de PR/CI.
- Decisión/confirmación humana sobre pendientes abiertos antes de implementaciones bloqueantes.
- Herramientas locales: Docker, Docker Compose, FVM/Flutter/Dart.
- Imágenes Docker verificadas por `docker pull`: PostgreSQL 18, Flyway fijo, Caddy 2, Mailpit dev.
- Spec Kit disponible antes de formalizar `specs/` y `.specify/`.
- OpenAPI inicial antes de rutas y uso compartido de contratos.
- Migraciones base antes de pruebas RLS/integración.
- Puertos/adaptadores de identidad antes de elegir proveedor SMS/correo concreto.

## EXECUTION_ORDER

1. GATE 0: Mantener este audit como línea base y no iniciar features sobre supuestos.
2. Inicializar git y archivos base mínimos no conductuales: `.gitignore`, `CLAUDE.md` (`@AGENTS.md`), estructura de directorios vacía controlada.
3. Crear/instalar SDD: `.specify/`, constitución referenciando `AGENTS.md`, plantillas de spec/plan/tasks.
4. Crear contrato inicial `docs/openapi.yaml` para el primer alcance aprobado (sin feature implementation).
5. Crear monorepo con FVM, `pubspec.yaml` workspace y `analysis_options.yaml` estricto.
6. Crear infraestructura base: Compose base/dev, roles, `.env.example`, Dockerfile API/worker, Caddyfile, backup esqueleto, migraciones `V001`–`V002` mínimas con RLS/grants/pruebas.
7. CI inicial: formato, análisis, validación OpenAPI, arquitectura, migraciones desde cero, pruebas RLS, builds.
8. Fundaciones de identidad: Argon2id benchmark, proveedor SMS/correo tras puertos, OTP/recuperación.
9. Rebanada vertical Must: registro/verificación/login/QR/teléfono/preview/compra/saldo/canje/validación.
10. Resto de Must: dos webs, reglas admin, reembolsos, sucursales, `system_settings`, auditoría.
11. Should/Could solo después de verify/integrate de Must.

## BLOCKERS

- `BLOCKED`: feature implementation general, porque faltan `specs/`, `docs/openapi.yaml`, `.specify/`, código, infraestructura y CI.
- `BLOCKED`: validación de migraciones y RLS, porque no existe `infra/` ni base local reproducible.
- `BLOCKED`: verificación de imágenes/versiones, porque requiere `docker pull` real y aún no hay Compose.
- `BLOCKED`: elección irreversible de proveedor SMS/correo, librería Argon2id y valores de reembolso; son decisiones abiertas.
- `BLOCKED`: flujo git/PR/CI, porque el directorio no es un repositorio git.

## NEXT_GATES

- GATE 0 — source-of-truth audit: DONE para documentación disponible.
- GATE 1 — contradictions resolved: NEEDS_REVIEW por artefactos citados pero ausentes y versiones Docker pendientes.
- GATE 2 — spec valid/approved: BLOCKED hasta crear/aprobar specs.
- GATE 3 — plan valid: BLOCKED.
- GATE 4 — API contract valid: BLOCKED hasta `docs/openapi.yaml`.
- GATE 5 — architecture valid: DOCUMENTED, no VERIFIED.
- GATE 6 — migrations valid: BLOCKED.
- GATE 7 — RLS tests valid: BLOCKED.
- GATE 8–12 — tests/security/CI: BLOCKED hasta fundaciones.
- GATE 13 — human review: REQUIRED antes de fundaciones amplias y antes de resolver decisiones abiertas.
