# AGENTS.md — Paseo Points

Reglas para agentes de IA (y personas) que trabajan en este repositorio. Si algo aquí contradice tu intuición, **gana este archivo**. Si algo no está cubierto, **pregunta**; no lo decidas.

Fuentes complementarias: `9-stack-tecnologico-paseo-points.md` (por qué; incluye la lista completa de endpoints, el orden previsto de migraciones `V001`–`V010`, ejemplos de políticas RLS y la matriz de pruebas), `INFRASTRUCTURE.md` (dónde corre qué), `specs/` (qué construir), `docs/openapi.yaml` (contrato).

> `CLAUDE.md` debe contener solo la línea `@AGENTS.md` para no mantener dos copias.

---

## 1. Qué es el proyecto
Plataforma de puntos de fidelización para comercios. Tres actores: **cliente** (acumula y canjea), **comercio** (dueño y cajeros, repartidos en **sucursales**: registran compras, validan canjes, solicitan reembolsos), **administrador** (configura, aprueba, resuelve reembolsos, revisa fraude). Una app Flutter (móvil + web) y una API Dart Frog sobre PostgreSQL.

### 1.1 Estado del repositorio (a 03/10/2026)
- **Fase de fundación SDD:** existe el repo git activo (`main`), `.gitignore`, `CLAUDE.md` (`@AGENTS.md`), `.specify/` (constitución y plantillas), `specs/README.md`, `docs/agent-audit.md`, `docs/openapi.yaml` (línea base: health + auth), monorepo pub workspace con FVM (Flutter 3.47.6) e `infra/` base verificada en vivo (Compose, roles, `V001`). No hay aún `apps/` implementadas, `specs/<feature>/` aprobadas ni CI. Las rutas y comandos de este archivo describen el monorepo **objetivo**: verifica qué existe antes de usarlos y no asumas que algo ya está implementado. Estado detallado en `docs/agent-audit.md`.
- Monorepo gestionado con **pub workspaces** (raíz `pubspec.yaml`); Melos opcional. Flutter y Dart se fijan con **FVM** (`.fvmrc`), un solo SDK para apps y API: usa `fvm flutter` / `fvm dart`, nunca el Flutter global.
- SDD con GitHub Spec Kit: constitución (este archivo) → `specs/<feature>/` (spec, plan, tareas) → implementación. Plantillas en `.specify/`.

## 2. Reglas innegociables
1. **El servidor es la fuente de verdad.** El cliente Flutter nunca calcula puntos de forma autoritativa.
2. **Los puntos solo se mueven por `points_ledger`.** Ledger de solo inserción: nunca `UPDATE` ni `DELETE`. Una anulación es un movimiento `REVERSAL`.
3. **Saldo nunca negativo** (`CHECK (balance >= 0)`). El saldo lo mantiene un trigger; el código de la API no escribe en `customer_balances`.
4. **Toda escritura crítica es idempotente** (`Idempotency-Key`) **y auditada** (`audit_log`).
5. **Todo endpoint existe primero en `docs/openapi.yaml`**, luego la ruta, luego la prueba.
6. **Migraciones aplicadas = inmutables.** Nunca edites un `V###` existente en `main`; crea uno nuevo.
7. ~~Toda tabla nace con RLS, políticas, `GRANT` y prueba~~ **SUPERSEDIDA por decisión del equipo (03/10/2026): se trabaja SIN RLS durante el MVP.** Las tablas nacen solo con `GRANT` mínimos; el aislamiento multi-comercio se aplica en middleware de aplicación. RLS + pruebas de aislamiento son **deuda bloqueante** que debe reintroducirse antes de cualquier despliegue con datos reales (ver `docs/agent-audit.md` §BLOCKERS).
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
- Dependencias permitidas: `adapters → application → domain`. **Nada importa a `adapters`.** CI lo verifica.
- Las rutas son finas: validan, llaman **un** caso de uso, mapean el resultado. **Cero reglas de negocio en rutas.**
- Cliente Flutter: `lib/features/<feature>/{presentation,application,data}`. No hexagonal completa.
- `packages/paseo_shared` contiene solo DTOs, enums y errores de contrato. **No** pongas lógica de dominio del backend ahí.

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
| Roles y extensiones de la base | `infra/db/init/` (no en migraciones) |
| Datos de demo | `infra/seed/R__seed_dev.sql` (solo dev) |
| Servicios, redes, volúmenes | `infra/docker-compose*.yml` |
| Contrato REST | `docs/openapi.yaml` |
| Especificaciones | `specs/<feature>/` |

## 5. Base de datos
### 5.1 Flyway
- Imagen con versión **fija** (ver `INFRASTRUCTURE.md`). Nunca `latest`.
- Nombre: `V<NNN>__descripcion_snake_case.sql`, correlativo sin saltos.
- Solo avanzan; no hay *undo*. Un error se corrige con una migración nueva.
- **La aplicación nunca ejecuta migraciones ni DDL.** Lo hace el servicio `migrate`.
- No uses `flyway clean` ni habilites `clean`. No bajes `validate`.
- Semillas solo como `R__*.sql` en `infra/seed/`, nunca en `infra/migrations/`.

### 5.2 Roles de base de datos
| Rol | Quién lo usa | Nota |
|-----|--------------|------|
| `paseo_app` | API y worker | Sin superusuario, **sin `BYPASSRLS`**, no es dueño |
| `paseo_owner` | Flyway | Dueño de los objetos |
| `paseo_backup` | backup | `BYPASSRLS` + lectura |
| `postgres_admin` | solo init | **Nunca** en la API ni en un MCP |

Si la API se conecta como superusuario o dueño, **RLS deja de funcionar** (lo saltan). No lo hagas.

### 5.3 RLS
- Cada transacción empieza fijando contexto con `set_config(..., true)`: `app.user_id`, `app.role`, `app.customer_id`, `app.establishment_id`, `app.branch_id`. El `true` es obligatorio (el pool reutiliza conexiones).
- Los valores vienen **de los claims verificados del JWT**, nunca del cuerpo ni de parámetros de la petición.
- `app.role = 'system'` solo lo fijan los adaptadores de Identity (login, registro, OTP, recuperación).
- Usa `ENABLE ROW LEVEL SECURITY`; **no** `FORCE` (rompería a Flyway).
- Cada migración con tabla nueva incluye: `ENABLE RLS` + políticas + `GRANT` mínimos + prueba de aislamiento (comercio A no ve comercio B).
- `points_ledger`: `REVOKE UPDATE, DELETE, TRUNCATE` para `paseo_app`.

## 6. JWT y autorización
- Access token ≤ 15 min. Claims: `iss, aud, sub, iat, exp, jti, role, cid, est, br, pv, ev, tv`. `br` (sucursal) solo para `merchant_cashier`.
- `aud` es **por aplicación**: `paseo-mobile`, `paseo-web-merchant`, `paseo-web-admin`. `paseo-web-admin` solo se emite y acepta con `role=admin`; endpoints de administración rechazan tokens de otras audiencias.
- Roles: `customer`, `merchant_owner`, `merchant_cashier`, `admin`.
- `pv=false` (teléfono no verificado): no generar QR, no acreditar, no identificar por teléfono.
- Los claims pueden estar desactualizados hasta 15 min. En acciones sensibles consulta `users.status` y `token_version` en la base.
- Refresh token: rotativo, guardado como hash, con detección de reutilización.
- **Web** (comercio y administración): access token **solo en memoria**; refresh en cookie `HttpOnly; Secure; SameSite=Strict; Path=/api/v1/auth`, con nombre propio (`__Secure-rt_merchant`, `__Secure-rt_admin`). `POST /auth/refresh` exige la cabecera `X-Paseo-Client` y valida `Origin`. **Las cookies no se aíslan por puerto**: nunca reutilices el nombre de cookie entre las dos webs.
- Contraseñas: **Argon2id**, formato PHC, parámetros mínimos OWASP, calculado fuera del hilo principal. No cambies el algoritmo ni uses bcrypt.
- Un comercio opera **solo** sobre su `establishment_id` (middleware **y** RLS).

## 7. Conversión de puntos (variable)
- Reglas en `points_rules`, versionadas. **Nunca edites una regla activa**: crea versión nueva y retira la anterior.
- **Solo el `admin` crea o cambia reglas de conversión y campañas.** El comercio no las propone ni las edita (sí propone recompensas, que el admin aprueba). No crees endpoints de reglas para el comercio.
- Resolución: una `BASE` (ESTABLISHMENT > CATEGORY > GLOBAL, desempate por `priority`) + como máximo una `CAMPAIGN` activa. Sin acumulación de campañas.
- Los puntos se calculan sobre el **monto neto** (`net_cents`, tras el descuento canjeado). `purchases` guarda `gross_cents`, `discount_cents` y `net_cents`.
- Fórmula en aritmética entera: `puntos_base = redondear(monto_neto × puntos / tramo)`; `puntos = redondear(puntos_base × multiplicador_bp / 10000)`; luego tope y compra mínima. Redondeo `FLOOR | ROUND | CEIL` según la regla.
- Código en `domain/PointsCalculator` y `domain/RuleResolver`, con pruebas por tabla incluidos bordes de redondeo.
- Cada compra guarda `rule_id`, `campaign_rule_id` y `rule_snapshot`.
- Sin regla aplicable → error `NO_APPLICABLE_RULE`. **Nunca inventes un valor por defecto.**
- `/merchant/purchases/preview` y el registro usan el **mismo** código.

## 8. Identidad: teléfono + correo
- Registro: correo + teléfono + contraseña. **Mínimo obligatorio: teléfono verificado por SMS** (`pv`); sin él no hay QR ni acumulación. El correo se verifica también, pero solo habilita **recuperar la cuenta** (no es requisito para acumular).
- **Solo teléfonos bolivianos (`+591`)**, almacenados en E.164; otro prefijo → `PHONE_NOT_SUPPORTED`. Móvil de 8 dígitos que empieza con 6 o 7 (verificar la regla antes de fijar la expresión regular).
- **El SMS solo se envía al registrarse y al cambiar de teléfono**, nunca en cada login (costo).
- OTP: 6 dígitos, solo hash en base, 5 min, 5 intentos, reenvío cada 60 s, topes por teléfono e IP.
- `POST /auth/password/forgot` **siempre responde 202**. Token ≥ 32 bytes aleatorios, hasheado, 30 min, un solo uso. Al restablecer: `token_version++` y revocar refresh tokens.
- El comercio ve nombre **enmascarado**; teléfono completo exacto; sin búsquedas parciales.
- `identify` devuelve un **ticket firmado** (~5 min, ligado al comercio); `purchases` recibe el ticket, no el teléfono.
- Envío de OTP y correo **siempre tras puertos** (`OtpSender`, `EmailSender`). `EmailSender` tiene implementación **SMTP real propia** (`SmtpEmailSender`); sin Mailpit (decisión del equipo 03/10/2026). En dev, el OTP sale por consola (`OTP_SENDER=console`); el correo requiere credenciales SMTP reales, con `EMAIL_SENDER=console` solo como opción local. **No hardcodees un proveedor.**
- **CI no se usa como identificador.**
- Nunca registres en logs: contraseñas, OTP, tokens, teléfonos completos ni correos completos.

## 9. API
- Prefijo `/api/v1`. JSON UTF-8, fechas ISO 8601 UTC, montos en centavos, paginación por cursor.
- Errores `application/problem+json` (RFC 9457) con `code` estable. El cliente programa contra `code`.
- 422 validación · 401 sin sesión · 403 sin permiso · 404 no existe · 409 conflicto · 429 límite.
- Compra y canje: `POST` + `Idempotency-Key`. Mismo key → 200 con la respuesta original.
- Canje: el `CHECK` aborta con `23514` → `INSUFFICIENT_POINTS`. **No uses `SELECT … FOR UPDATE` sobre el saldo** (el rol no tiene `UPDATE` y el trigger ya serializa).
- `purchases.invoice_ref` es opcional; único por `(establishment_id, invoice_ref)`; **no** identifica al cliente.

## 10. Antifraude (MVP)
- Cinco reglas fijas en `fraud_rules_config`: velocidad, monto máximo, factura repetida, concentración y tasa anómala de reembolsos.
- **Nunca expongas al comercio los umbrales ni el motivo exacto.** Solo "requiere verificación".
- Anular = `REVERSAL` en el ledger. Nada de borrar compras.
- Estados: `ACTIVE → OBSERVED → POINTS_SUSPENDED → BLOCKED`, cada cambio auditado.
- No implementes ranking competitivo de vendedores: usa "actividad por vendedor".

## 10.1 Reembolsos
- **El personal solicita (cajero y dueño); solo `admin` resuelve.** El cajero solo puede solicitar sobre compras que él registró. No existe (ni debes crear) un endpoint que permita al comercio revertir puntos por su cuenta.
- La reversión es **siempre** un movimiento `REVERSAL` en `points_ledger` con `reverses_ledger_id` apuntando al crédito original. Nunca `UPDATE`/`DELETE` de la compra ni del crédito.
- El personal aporta **solo**: **foto de la factura, número de factura y razón social** (motivo opcional por código). El servidor **copia desde la compra**: sucursal (id y nombre), fecha y hora de la compra, `invoice_ref`, monto y puntos a revertir. **Nunca aceptes sucursal, hora o monto del cliente HTTP.** Si la compra tiene `invoice_ref` y difiere del número ingresado, genera una marca para el admin (no bloquea).
- La solicitud llega como `multipart/form-data`. La foto: JPEG/PNG/WebP, validada **por contenido**, tamaño máximo configurable, sin EXIF, guardada con nombre aleatorio en el volumen `uploads`, con fila en `refund_attachments`. **Sin URL pública**: se sirve solo por la API con comprobación de rol y comercio, con `X-Content-Type-Options: nosniff`, y cada descarga se audita.
- Reglas: una solicitud `PENDING` por compra (índice único parcial); un solo `REVERSAL` por crédito (índice único sobre `reverses_ledger_id`); quien solicita no aprueba; **solo reembolso total, nunca parcial por monto**; solo dentro de la ventana `refund_window_days` (parámetro de `system_settings`, configurable por el admin; fuera → `REFUND_WINDOW_EXPIRED`).
- Aprobar = **una transacción**: `UPDATE refund_requests SET status='APPROVED' … WHERE id=$1 AND status='PENDING' RETURNING` (sin fila → `REFUND_ALREADY_RESOLVED`, 409) → insertar `REVERSAL` → guardar `points_reversed`, `unrecovered_points`, `reversal_ledger_id` → `audit_log` → notificaciones.
- **Saldo insuficiente:** nunca permitas saldo negativo ni relajes el `CHECK`. Con `reversal_mode = PARTIAL` revierte hasta el saldo disponible y registra el faltante en `unrecovered_points`; con `FULL` y saldo insuficiente responde `INSUFFICIENT_POINTS_FOR_REVERSAL`. Un `23514` en carrera → reintentar o informar, no ignorar.
- Rechazar exige `review_note`. El cliente ve el movimiento de reversión con motivo genérico, **no** la nota interna.
- No restituyas el código de canje de un descuento usado en la compra (decisión del equipo: no).
- Cada solicitud y cada resolución van a `audit_log` y generan notificación.
- **Sucursales:** un cajero tiene **una sola sucursal fija** (`establishment_staff.branch_id`, claim `br`); el dueño opera en todas. Toda compra guarda `branch_id`. Todo comercio tiene al menos una sucursal ("Principal" por defecto).

## 11. Pruebas
- `domain`: pruebas unitarias sin base de datos, por tabla de casos.
- Repositorios y RLS: pruebas de integración contra PostgreSQL real (contenedor), con el rol `paseo_app`.
- Criterios de aceptación de cada HU → una prueba. Las escribe o revisa alguien distinto de quien implementó.
- CI aplica **todas las migraciones desde cero** antes de probar.

## 12. Flujo de trabajo
- Ramas `feat/<id-historia>-descripcion`; `main` protegida; PR con revisión.
- Conventional Commits con la HU: `feat(loyalty): HU-11 registrar compra`.
- Un `analysis_options.yaml` único para todo el monorepo, con análisis estricto (`very_good_analysis` o equivalente). `pubspec.lock` versionado; `dart pub outdated` en revisiones.
- Un agente por feature y rama; no dos agentes sobre los mismos archivos.
- El humano aprueba el **spec y el plan** antes de implementar.
- Antes de dar algo por hecho: `dart format`, `dart analyze`, pruebas, y si tocaste esquema, migraciones desde cero + pruebas RLS.

## 13. Comandos
```bash
# Onboarding: de un clon limpio a demo local
cp infra/.env.example infra/.env            # completar secretos de desarrollo; .env nunca se versiona
fvm install && fvm flutter pub get
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d   # todo en dev

docker compose -f infra/docker-compose.yml run --rm migrate info                    # estado de migraciones
docker compose -f infra/docker-compose.yml run --rm migrate validate

fvm dart format --set-exit-if-changed .
fvm dart analyze
fvm dart test                               # en apps/api y packages/*
fvm flutter test                            # en apps/mobile

# Desarrollo de las webs (un código, tres entradas; en apps/mobile)
fvm flutter run -d chrome --web-port 8081 -t lib/main_merchant_web.dart   # web comercio
fvm flutter run -d chrome --web-port 8082 -t lib/main_admin_web.dart      # web administración

# Dos builds web de producción; cada uno solo con las rutas de su rol
fvm flutter build web -t lib/main_merchant_web.dart && mv build/web build/web-merchant
fvm flutter build web -t lib/main_admin_web.dart    && mv build/web build/web-admin
```
Puertos: web comercio **443**, web administración **8443**; en desarrollo 8081 y 8082.
Detalle de servicios, puertos y variables: `INFRASTRUCTURE.md`.

## 14. Prohibido
- Editar o borrar una migración ya aplicada; usar `flyway clean`; ejecutar DDL desde la API.
- Conectar la API como `postgres_admin` o `paseo_owner`; crear tablas sin RLS.
- Leer, imprimir, modificar o commitear `.env` o secretos.
- Comandos destructivos (`rm -rf`, `DROP`, `TRUNCATE`, `git push --force`) sin aprobación explícita.
- Apuntar un MCP de base de datos a datos reales; usar solo la base local con rol de solo lectura.
- Usar `latest` en imágenes; fijar versiones de paquetes "de memoria" (consulta pub.dev).
- Meter lógica de negocio en rutas, en `paseo_shared` o en Flutter.
- Instalar skills o plugins no auditados.
- Exponer `uploads` por Caddy o por URL pública; aceptar sucursal/hora/monto del cliente en reembolsos; mezclar rutas de comercio y administración en un mismo build web; reutilizar cookies o `aud` entre las dos webs.
- Guardar contraseñas con otro algoritmo que Argon2id; enviar SMS en cada login; aceptar teléfonos no bolivianos.
- Dar al comercio endpoints para editar reglas de conversión.

## 15. Decisiones abiertas (no las resuelvas tú; pregunta)
Decididas por el equipo (**no las reabras**): dos builds web en dos puertos · Argon2id · SMS mínimo + correo · solo `+591` · conversión solo del admin · puntos sobre monto neto · cajero puede solicitar reembolso · solo reembolso total · saldo insuficiente = reversión parcial · no se restituye el canje · sucursal fija por cajero · factura = foto + número + razón social · ventana de reembolso configurable.

Abiertas (**pregunta, no decidas**): proveedor de SMS y de correo · librería concreta de Argon2id (benchmark) · valores iniciales de ventana de reembolso, vencimiento, tamaño máximo y retención de fotos · razón social del comprador o del emisor · `invoice_ref` obligatorio u opcional por comercio · destino del despliegue · recorte de hexagonal en Flutter · motivo opcional del reembolso · sucursal "Principal" automática · confirmación de las dos interpretaciones de la encuesta (refresh web en cookie `HttpOnly`; SMS mínimo con correo adicional, sin exigir el correo para acumular).

## 16. Definición de terminado
- [ ] Spec actualizado y aprobado.
- [ ] Endpoint en `openapi.yaml` (si aplica).
- [ ] Regla de dependencia hexagonal respetada.
- [ ] Migración nueva (si hay cambio de esquema) con RLS, `GRANT` y prueba.
- [ ] Idempotencia y auditoría en escrituras críticas.
- [ ] Sin datos personales en claims ni en logs.
- [ ] Si toca reembolsos: sucursal y hora vienen del servidor; un solo `REVERSAL` por crédito; prueba de saldo insuficiente.
- [ ] Pruebas verdes en CI desde migraciones limpias.
