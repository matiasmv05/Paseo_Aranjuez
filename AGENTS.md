# AGENTS.md — Paseo Points

Reglas gobernantes del repositorio (es la constitución SDD). Si algo aquí contradice tu intuición, **gana este archivo**. Si algo no está cubierto, **pregunta**; no lo decidas.

> **La numeración de secciones y reglas (§2 regla N, §5.2, §6, §8, §10.1, §15, §16, …) está citada literalmente desde CI, `docs/openapi.yaml`, `specs/` y comentarios de código. No reenumeres ni borres secciones.**
> `CLAUDE.md` solo contiene `@AGENTS.md`.

Fuentes complementarias: `9-stack-tecnologico-paseo-points.md` (por qué; endpoints del MVP, orden previsto de migraciones `V001`–`V010`, matrices de pruebas) · `INFRASTRUCTURE.md` (dónde corre qué, variables de entorno) · `specs/` (qué construir) · `docs/openapi.yaml` (contrato REST).

---

## 1. Qué es el proyecto
Plataforma de puntos de fidelización para comercios. Tres actores: **cliente** (acumula y canjea), **comercio** (dueño y cajeros, repartidos en **sucursales**: registran compras, validan canjes, solicitan reembolsos), **administrador** (configura, aprueba, resuelve reembolsos, revisa fraude). Una app Flutter (móvil + dos entradas web) y una API Dart Frog sobre PostgreSQL.

### 1.1 Estado del repositorio (verificado 03/10/2026)
**Implementando `001-identidad`** en la rama `feat/001-identidad` (árbol git limpio).

> ⚠️ Las casillas de `specs/001-identidad/tasks.md` están **todas sin marcar** aunque el trabajo avanzó: no son fiables como estado. Verifica archivos, no casillas.

- **Existe:** `docs/openapi.yaml` (health, ready y los 8 endpoints de auth); esqueleto Dart Frog (`routes/health.dart`, `ready.dart`, `_middleware.dart` RFC 9457); `domain`/`application`/`adapters/out/postgres/` de identidad (HU-01–HU-05) con pruebas unitarias y de integración; `packages/paseo_shared` (DTOs de auth, `ApiErrorCode`); migraciones `V001` (roles, extensiones `citext`/`pgcrypto`, esquema `app`) y `V002` (identidad, **sin RLS**, con `GRANT`; ver regla 2.7); `bin/server.dart`, `bin/worker.dart`, `bin/healthcheck.dart`; CI completo (`.github/workflows/ci.yml`: formato, análisis, pruebas, lint OpenAPI, migraciones desde cero, chequeos de roles, inmutabilidad de `V###`, job `integration`).
- **Falta:** `routes/auth/*` y `adapters/in` (T013–T021); `Argon2idPasswordHasher`, `SmtpEmailSender`, senders de consola (T031); middleware de rate limit (T032); job real del worker (T033); apps Flutter (solo `apps/mobile/lib/main.dart`, stub; sin entradas web); specs de features 002+.
- Estado documental adicional (parcialmente desactualizado): `docs/agent-audit.md`.

Monorepo gestionado con **pub workspaces** (raíz `pubspec.yaml`: `apps/api`, `apps/mobile`, `packages/paseo_shared`). Un solo SDK con **FVM** (`.fvmrc` → Flutter 3.47.6 / Dart 3.13): usa `fvm flutter` / `fvm dart`, nunca el Flutter global. SDD con Spec Kit: este archivo → `specs/<feature>/` (spec, plan, tasks; plantillas en `.specify/`) → implementación.

## 2. Reglas innegociables
1. **El servidor es la fuente de verdad.** El cliente Flutter nunca calcula puntos de forma autoritativa.
2. **Los puntos solo se mueven por `points_ledger`.** Ledger de solo inserción: nunca `UPDATE` ni `DELETE`. Una anulación es un movimiento `REVERSAL`.
3. **Saldo nunca negativo** (`CHECK (balance >= 0)`). El saldo lo mantiene un trigger; el código de la API no escribe en `customer_balances`.
4. **Toda escritura crítica es idempotente** (`Idempotency-Key`) **y auditada** (`audit_log`).
5. **Todo endpoint existe primero en `docs/openapi.yaml`**, luego la ruta, luego la prueba.
6. **Migraciones aplicadas = inmutables.** Nunca edites un `V###` existente en `main`; crea uno nuevo. CI lo rechaza (job `migration-immutability`).
7. ~~Toda tabla nace con RLS, políticas, `GRANT` y prueba~~ **SUPERSEDIDA (03/10/2026): MVP sin RLS.** Las tablas nacen solo con `GRANT` mínimos; el aislamiento multi-comercio se aplica en middleware de aplicación. RLS + pruebas de aislamiento son **deuda bloqueante** antes de cualquier despliegue con datos reales (ver `docs/agent-audit.md` §BLOCKERS).
8. **Sin datos personales en el JWT.**
9. **Dinero en centavos enteros.** Nunca `double`/`float` para dinero ni puntos.
10. **Ningún cambio de comportamiento sin spec y sin prueba.**

## 3. Arquitectura (backend `apps/api`)
```
lib/domain        → Dart puro. No importa nada (ni framework, ni postgres).
lib/application   → casos de uso y puertos. Solo importa domain.
lib/adapters/in   → rutas Dart Frog, middlewares, DTOs, mapeo de errores.
lib/adapters/out  → Postgres*, Jwt*, SmtpEmailSender, OtpSender, Fcm*.
```
- Dependencias permitidas: `adapters → application → domain`. **Nada importa a `adapters`.**
- Las rutas son finas: validan, llaman **un** caso de uso, mapean el resultado a RFC 9457. **Cero reglas de negocio en rutas.**
- Cliente Flutter: `lib/features/<feature>/{presentation,application,data}` (no hexagonal completa).
- `packages/paseo_shared`: solo DTOs, enums y errores de contrato. **No** lógica de dominio.

## 4. Dónde vive cada cosa
| Necesitas… | Va en… |
|------------|--------|
| Regla de negocio (conversión, redondeo, fraude) | `apps/api/lib/domain/` |
| Caso de uso / puerto | `apps/api/lib/application/` |
| SQL, JWT, SMTP, SMS, FCM | `apps/api/lib/adapters/out/` |
| Ruta HTTP | `apps/api/lib/adapters/in/` (`routes/` de Dart Frog) |
| Job programado | `apps/api/bin/worker.dart` + casos de uso |
| Pantalla / estado del cliente | `apps/mobile/lib/features/` |
| Punto de entrada de cada app | `apps/mobile/lib/main.dart` (móvil), `main_merchant_web.dart` (web comercio), `main_admin_web.dart` (web admin) |
| Archivos subidos (facturas) | Volumen `uploads` (solo vía API) |
| Parámetros de negocio configurables | Tabla `system_settings` (no en `.env`) |
| Cambio de esquema, RLS, trigger | `infra/migrations/V###__*.sql` |
| Roles y extensiones de la base | `infra/db/init/` (roles; corre solo con volumen vacío) y `V001` (extensiones) |
| Datos de demo | `infra/seed/R__seed_dev.sql` (solo dev) |
| Servicios, redes, volúmenes | `infra/docker-compose*.yml` |
| Contrato REST | `docs/openapi.yaml` |
| Especificaciones | `specs/<feature>/` |

## 5. Base de datos
### 5.1 Flyway
- Imagen fija: `flyway/flyway:13.9.0` (`infra/docker-compose.yml`). Nunca `latest`.
- Nombre: `V<NNN>__descripcion_snake_case.sql`, correlativo sin saltos. Solo avanzan; un error se corrige con una migración nueva.
- **La aplicación nunca ejecuta migraciones ni DDL** (CI verifica DDL denegado a `paseo_app`). Lo hace el servicio `migrate`.
- No uses `flyway clean` (`FLYWAY_CLEAN_DISABLED=true`) ni bajes `validate`.
- Semillas solo como `R__*.sql` en `infra/seed/`, aplicadas solo con el override `dev`.

### 5.2 Roles de base de datos
| Rol | Quién lo usa | Nota |
|-----|--------------|------|
| `paseo_app` | API y worker | Sin superusuario, **sin `BYPASSRLS`**, no es dueño |
| `paseo_owner` | Flyway | Dueño de los objetos |
| `paseo_backup` | backup | `BYPASSRLS` + `pg_read_all_data` |
| `postgres_admin` | solo init | **Nunca** en la API ni en un MCP |

Si la API se conecta como superusuario o dueño, RLS deja de funcionar. No lo hagas.

### 5.3 RLS
- **SUPERSEDIDO para el MVP** (regla 2.7): hoy se trabaja sin RLS; lo que sigue aplica cuando se reintroduzca.
- Cada transacción empieza fijando contexto con `set_config(..., true)`: `app.user_id`, `app.role`, `app.customer_id`, `app.establishment_id`, `app.branch_id` (el `true` es obligatorio: el pool reutiliza conexiones). Valores **solo de los claims verificados del JWT**.
- `app.role = 'system'` solo lo fijan los adaptadores de Identity (login, registro, OTP, recuperación).
- `ENABLE ROW LEVEL SECURITY`; **no** `FORCE` (rompería a Flyway).
- Cada migración con tabla nueva incluirá: `ENABLE RLS` + políticas + `GRANT` mínimos + prueba de aislamiento en `infra/tests/rls/<Vxxx>_*.sql` (CI las ejecuta con `paseo_app` cuando existan).
- `points_ledger`: `REVOKE UPDATE, DELETE, TRUNCATE` para `paseo_app`.

## 6. JWT y autorización
- Access token ≤ 15 min (`JWT_ACCESS_TTL_SECONDS=900`). Claims: `iss, aud, sub, iat, exp, jti, role, cid, est, br, pv, ev, tv`. `br` (sucursal) solo para `merchant_cashier`.
- `aud` por aplicación: `paseo-mobile`, `paseo-web-merchant`, `paseo-web-admin`. `paseo-web-admin` solo se emite y acepta con `role=admin`; endpoints de admin rechazan otras audiencias.
- Roles: `customer`, `merchant_owner`, `merchant_cashier`, `admin`.
- `pv=false` (teléfono no verificado): no generar QR, no acreditar, no identificar por teléfono.
- Los claims pueden estar desactualizados hasta 15 min. En acciones sensibles consulta `users.status` y `token_version` en la base.
- Refresh token: rotativo, guardado como hash, con detección de reutilización → revoca la familia.
- **Web** (ambas): access token **solo en memoria**; refresh en cookie `HttpOnly; Secure; SameSite=Strict; Path=/api/v1/auth`, con nombre propio (`__Secure-rt_merchant`, `__Secure-rt_admin`). `POST /auth/refresh` exige `X-Paseo-Client` y valida `Origin`. Las cookies no se aíslan por puerto: nunca reutilices nombre de cookie ni `aud` entre las dos webs.
- Contraseñas: **Argon2id** (`cryptography` 2.9.0, decisión 03/10/2026), formato PHC, parámetros OWASP mínimos (m=19 MiB, t=2, p=1), fuera del hilo principal (Isolate). Detalle: `specs/001-identidad/research.md`.
- Un comercio opera **solo** sobre su `establishment_id` (middleware **y**, cuando se reintroduzca, RLS).

## 7. Conversión de puntos (variable)
- Reglas en `points_rules`, versionadas. **Nunca edites una regla activa**: crea versión nueva y retira la anterior.
- **Solo el `admin` crea o cambia reglas y campañas.** El comercio no tiene endpoints de reglas (sí propone recompensas, que el admin aprueba).
- Resolución: una `BASE` (ESTABLISHMENT > CATEGORY > GLOBAL, desempate por `priority`) + como máximo una `CAMPAIGN` activa. Sin acumulación de campañas.
- Puntos sobre el **monto neto** (`net_cents`). `purchases` guarda `gross_cents`, `discount_cents` y `net_cents`.
- Fórmula entera: `puntos_base = redondear(monto_neto × puntos / tramo)`; `puntos = redondear(puntos_base × multiplicador_bp / 10000)`; luego tope y compra mínima. Redondeo `FLOOR | ROUND | CEIL` según la regla.
- Código en `domain/PointsCalculator` y `domain/RuleResolver` con pruebas por tabla (bordes de redondeo incluidos).
- Cada compra guarda `rule_id`, `campaign_rule_id` y `rule_snapshot`.
- Sin regla aplicable → `NO_APPLICABLE_RULE`. **Nunca inventes un valor por defecto.**
- `/merchant/purchases/preview` y el registro usan el **mismo** código.

## 8. Identidad: teléfono + correo
- Registro: correo + teléfono + contraseña. **Mínimo obligatorio: teléfono verificado por SMS** (`pv`); sin él no hay QR ni acumulación. El correo verificado solo habilita **recuperar la cuenta**.
- **Solo teléfonos bolivianos (`+591`)**, E.164; otro prefijo → `PHONE_NOT_SUPPORTED`. Después de `+591`, **8 dígitos cualesquiera**: no se exige que empiece con 6 o 7 (decisión 03/10/2026). La expresión regular es `^\+591[0-9]{8}$`.
- **SMS solo al registrarse y al cambiar de teléfono**, nunca en cada login (costo).
- OTP: 6 dígitos, solo hash en base, 5 min, 5 intentos, reenvío cada 60 s, topes por teléfono e IP.
- `POST /auth/password/forgot` **siempre responde 202** (cuerpos idénticos). Token ≥ 32 bytes aleatorios, hasheado, 30 min, un solo uso. Al restablecer: `token_version++` y revocar refresh tokens.
- El comercio ve nombre **enmascarado**; teléfono completo exacto; sin búsquedas parciales.
- `identify` devuelve un **ticket firmado** (~5 min, ligado al comercio); `purchases` recibe el ticket, no el teléfono.
- Envío de OTP y correo **siempre tras puertos** (`OtpSender`, `EmailSender`). Correo: **`SmtpEmailSender` propio** contra Gmail/Google Workspace (sin Mailpit, 03/10/2026). En dev, OTP por consola (`OTP_SENDER=console`); `EMAIL_SENDER=console` admisible localmente.
- **CI no se usa como identificador.**
- Nunca en logs: contraseñas, OTP, tokens, teléfonos ni correos completos.

## 9. API
- Prefijo `/api/v1`. JSON UTF-8, fechas ISO 8601 UTC, montos en centavos, paginación por cursor (`CursorPage`).
- Errores `application/problem+json` (RFC 9457) con `code` estable; el cliente programa contra `code`.
- 422 validación · 401 sin sesión · 403 sin permiso · 404 no existe · 409 conflicto · 429 límite.
- Compra y canje: `POST` + `Idempotency-Key`. Mismo key → 200 con la respuesta original.
- Canje: el `CHECK` aborta con `23514` → `INSUFFICIENT_POINTS`. **No uses `SELECT … FOR UPDATE` sobre el saldo** (el rol no tiene `UPDATE` y el trigger ya serializa).
- `purchases.invoice_ref` es **obligatorio** (decisión 03/10/2026); único por `(establishment_id, invoice_ref)`; **no** identifica al cliente.

## 10. Antifraude (MVP)
- Cinco reglas fijas en `fraud_rules_config`: velocidad, monto máximo, factura repetida, concentración y tasa anómala de reembolsos.
- **Nunca expongas al comercio los umbrales ni el motivo exacto.** Solo "requiere verificación".
- Anular = `REVERSAL` en el ledger. Nada de borrar compras.
- Estados: `ACTIVE → OBSERVED → POINTS_SUSPENDED → BLOCKED`, cada cambio auditado.
- No implementes ranking competitivo de vendedores: usa "actividad por vendedor".

## 10.1 Reembolsos
- **El personal solicita (cajero y dueño); solo `admin` resuelve.** El cajero solo sobre compras que él registró. No existe endpoint para que el comercio revierta puntos por su cuenta.
- La reversión es **siempre** un `REVERSAL` en `points_ledger` con `reverses_ledger_id` al crédito original. Nunca `UPDATE`/`DELETE`.
- El personal aporta **solo**: **foto de la factura, número de factura y razón social** (motivo opcional por código). El servidor copia desde la compra: sucursal (id y nombre), fecha/hora, `invoice_ref`, monto y puntos a revertir. **Nunca aceptes sucursal, hora o monto del cliente HTTP.** `invoice_ref` discrepante → marca para el admin (no bloquea).
- `multipart/form-data`. La foto: JPEG/PNG/WebP validada **por contenido**, tamaño máximo configurable, sin EXIF, nombre aleatorio en el volumen `uploads`, fila en `refund_attachments`. **Sin URL pública**: se sirve por la API con comprobación de rol y comercio, `X-Content-Type-Options: nosniff`, descarga auditada.
- Reglas: una solicitud `PENDING` por compra (índice único parcial); un solo `REVERSAL` por crédito (índice único sobre `reverses_ledger_id`); quien solicita no aprueba; **solo reembolso total**; ventana `refund_window_days` (`system_settings`; fuera → `REFUND_WINDOW_EXPIRED`).
- Aprobar = **una transacción**: `UPDATE refund_requests SET status='APPROVED' … WHERE id=$1 AND status='PENDING' RETURNING` (sin fila → `REFUND_ALREADY_RESOLVED`, 409) → insertar `REVERSAL` → `points_reversed`, `unrecovered_points`, `reversal_ledger_id` → `audit_log` → notificaciones.
- **Saldo insuficiente:** nunca saldo negativo ni relajar el `CHECK`. `reversal_mode = PARTIAL` revierte hasta el disponible y registra el faltante en `unrecovered_points`; `FULL` → `INSUFFICIENT_POINTS_FOR_REVERSAL`. Un `23514` en carrera → reintentar o informar, no ignorar.
- Rechazar exige `review_note` (interna; el cliente ve motivo genérico).
- No restituyas el código de canje de un descuento usado (decisión del equipo: no).
- Cada solicitud y resolución a `audit_log` + notificación.
- **Sucursales:** cajero con **una sucursal fija** (`establishment_staff.branch_id`, claim `br`); el dueño opera en todas. Toda compra guarda `branch_id`. Todo comercio tiene al menos una sucursal ("Principal" por defecto).

## 11. Pruebas
- `domain`: unitarias sin base de datos, por tabla de casos.
- Repositorios (y futuras RLS): integración contra PostgreSQL real con el rol `paseo_app`.
- **Integración (`apps/api/test/integration/`)** requiere la base dev levantada en el puerto **5433**:
  `docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d --wait db`
  con `DB_DEV_PORT=5433` (en `infra/.env` o en el shell; el override publica `127.0.0.1:${DB_DEV_PORT:-5432}` y CI usa 5433). Helpers de `test/integration/support.dart` (`uniqueEmail()`, `uniquePhone()`, `newId()`), valores dev por defecto (`paseo_app`/`dev-app`, base `paseo`). **Los tests no limpian la base.** Los tests de integración **no tienen tags**: correr solo unitarios = `fvm dart test test/domain test/application test/routes` (como hace CI; `dart test` a secas falla sin BD).
- Criterios de aceptación de cada HU → una prueba, escrita o revisada por alguien distinto de quien implementó.
- CI aplica **todas las migraciones desde cero** antes de probar.

## 12. Flujo de trabajo
- Ramas `feat/<id-historia>-descripcion`; `main` protegida; PR con revisión.
- Conventional Commits con la HU: `feat(loyalty): HU-11 registrar compra`.
- `analysis_options.yaml` único (very_good_analysis 11); `pubspec.lock` versionado (CI usa `--enforce-lockfile`); `dart pub outdated` en revisiones.
- Un agente por feature y rama; no dos agentes sobre los mismos archivos.
- El humano aprueba **spec y plan** antes de implementar.
- Antes de dar algo por hecho: `fvm dart format --set-exit-if-changed .`, `fvm dart analyze --fatal-warnings`, pruebas, y si tocaste esquema, migraciones desde cero.
- Si cambias comandos, rutas o reglas referidas aquí, actualiza este archivo (tu numeración es un contrato; ver nota inicial).

## 13. Comandos
```bash
# Onboarding
cp infra/.env.example infra/.env            # completar secretos de desarrollo; .env nunca se versiona
fvm install && fvm flutter pub get
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d   # todo en dev

# Migraciones
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml run --rm migrate info
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml run --rm migrate validate

# Verificación (igual que CI)
fvm dart format --set-exit-if-changed .
fvm dart analyze --fatal-warnings
fvm dart test                               # en packages/*
fvm dart test test/domain test/application test/routes   # en apps/api: unitarias (sin BD)
fvm flutter test                            # en apps/mobile (cuando exista test/)

# Pruebas de integración de la API (BD dev en loopback:5433, §11)
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d --wait db
cd apps/api && fvm dart test test/integration

# API en desarrollo
cd apps/api && fvm dart pub global run dart_frog_cli:dart_frog dev   # igual: dart_frog dev

# Lint del contrato (igual que CI)
npx --yes @redocly/cli@2 lint docs/openapi.yaml

# Webs de desarrollo (en apps/mobile)
fvm flutter run -d chrome --web-port 8081 -t lib/main_merchant_web.dart   # web comercio
fvm flutter run -d chrome --web-port 8082 -t lib/main_admin_web.dart      # web administración

# Builds web de producción (cada uno solo con las rutas de su rol)
fvm flutter build web -t lib/main_merchant_web.dart && mv build/web build/web-merchant
fvm flutter build web -t lib/main_admin_web.dart    && mv build/web build/web-admin
```
Puertos servidos por Caddy: web comercio **443**, web administración **8443**; en desarrollo 8081 y 8082. Servicios, puertos y variables: `INFRASTRUCTURE.md` (§2, §3, §7).

## 14. Prohibido
- Editar o borrar una migración ya aplicada; usar `flyway clean`; ejecutar DDL desde la API.
- Conectar la API como `postgres_admin` o `paseo_owner`; crear tablas sin `GRANT` mínimos (RLS suspendida solo en el MVP, regla 2.7).
- Leer, imprimir, modificar o commitear `.env` o secretos.
- Comandos destructivos (`rm -rf`, `DROP`, `TRUNCATE`, `git push --force`) sin aprobación explícita.
- Apuntar un MCP de base de datos a datos reales; usar solo la base local con rol de solo lectura.
- Usar `latest` en imágenes; fijar versiones de paquetes "de memoria" (consulta pub.dev).
- Meter lógica de negocio en rutas, en `paseo_shared` o en Flutter.
- Instalar skills o plugins no auditados.
- Exponer `uploads` por Caddy o por URL pública; aceptar sucursal/hora/monto del cliente en reembolsos; mezclar rutas de comercio y administración en un mismo build web; reutilizar cookies o `aud` entre las dos webs.
- Guardar contraseñas con otro algoritmo que Argon2id; enviar SMS en cada login; aceptar teléfonos no bolivianos.
- Dar al comercio endpoints para editar reglas de conversión.

## 15. Decisiones
**Cerradas (no las reabras):** dos builds web en dos puertos · Argon2id con `cryptography` 2.9.0 (PHC verificado contra el binario C oficial) · correo Gmail/Google Workspace SMTP con `SmtpEmailSender` propio (sin Mailpit) · SMS mínimo + correo · solo `+591`, con 8 dígitos cualesquiera (no se exige inicio 6/7) · conversión solo del admin · puntos sobre monto neto · cajero puede solicitar reembolso · solo reembolso total · saldo insuficiente = reversión parcial · no se restituye el canje · sucursal fija por cajero · factura = foto + número + razón social · ventana de reembolso configurable · `purchases.invoice_ref` **obligatorio** para todos los comercios · sucursal **"Principal" creada automáticamente** al registrar el comercio · **MVP sin RLS** (regla 2.7).

**Abiertas (pregunta, no decidas):** proveedor de SMS · valores iniciales de ventana de reembolso, vencimiento, tamaño máximo y retención de fotos · razón social del comprador o del emisor · destino del despliegue · recorte de hexagonal en Flutter · motivo opcional del reembolso · confirmación de las dos interpretaciones de la encuesta (refresh web en cookie `HttpOnly`; SMS mínimo con correo, sin exigir el correo para acumular).

## 16. Definición de terminado
- [ ] Spec actualizado y aprobado.
- [ ] Endpoint en `openapi.yaml` (si aplica).
- [ ] Regla de dependencia hexagonal respetada.
- [ ] Migración nueva (si hay cambio de esquema) con `GRANT` mínimos; RLS + prueba de aislamiento al reintroducirla (deuda bloqueante, regla 2.7).
- [ ] Idempotencia y auditoría en escrituras críticas.
- [ ] Sin datos personales en claims ni en logs.
- [ ] Si toca reembolsos: sucursal y hora vienen del servidor; un solo `REVERSAL` por crédito; prueba de saldo insuficiente.
- [ ] Pruebas verdes en CI desde migraciones limpias.
