# Feature Specification: Identidad de cliente y sesiones

**Feature**: `001-identidad`
**Branch**: `feat/001-identidad`
**Created**: 2026-10-03
**Status**: Approved (2026-10-03)
**Input**: User description: "Registro de cliente con correo + teléfono + contraseña, verificación de teléfono por SMS (OTP) y de correo, login para todos los roles, refresh rotativo, logout y recuperación de contraseña por correo."
**Authority**: `AGENTS.md` remains the governing repository policy. Reglas aplicadas: §2 (2, 4, 5, 7, 8, 10), §5.3, §6, §8, §9, §11, §16.

## Scope

- **Goal**: Que un cliente pueda registrarse, verificar su teléfono (requisito mínimo para acumular puntos) y su correo (requisito para recuperar la cuenta), y que cualquier actor inicie sesión con tokens de corta vida y refresh rotativo.
- **Non-goals**:
  - Alta de establecimientos, sucursales y staff (spec posterior; las tablas de V003).
  - QR del cliente, compra, canje, saldo (features posteriores).
  - Cambio de teléfono de una cuenta existente (segundo caso de envío de SMS; spec posterior).
  - Proveedor real de SMS/correo: la spec solo exige los puertos (`OtpSender`, `EmailSender`).
- **Actor(s)**: `customer` (registro/verificación), todos los roles (login/sesión), `system` (envío de OTP/correos).
- **Applications affected**: `api`, `worker` (limpieza de códigos/tokens vencidos), `mobile`, `web-merchant`, `web-admin` (solo flujos de sesión de su rol).
- **OPEN_DECISIONS** (AGENTS.md §15; esta spec NO las resuelve):
   - ~~Proveedor de correo~~ **DECIDIDO (03/10/2026)**: Gmail/Google Workspace SMTP con remitente del equipo; implementación propia `SmtpEmailSender`.
   - Proveedor de SMS y su costo (sigue abierto; en dev, `OTP_SENDER=console`).
   - ~~Librería concreta de Argon2id~~ **DECIDIDA (03/10/2026)**: `cryptography` 2.9.0. Ver `specs/001-identidad/research.md`.
  - Regex endurecida del móvil boliviano (`+591` + 8 dígitos iniciando en 6 o 7; hasta su verificación se valida `^\+591[0-9]{8}$`).
  - Confirmación de las interpretaciones de la encuesta: refresh web en cookie `HttpOnly`; SMS mínimo con correo adicional sin exigir el correo para acumular.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Registro y verificación del teléfono (Priority: P1)

Un cliente se registra con correo + teléfono `+591` + contraseña. El sistema crea la cuenta con `pv=false`, envía el OTP por SMS (mínimo obligatorio) y marca el correo como pendiente de verificación. El cliente introduce el código de 6 dígitos y queda `pv=true`; solo entonces la plataforma le permite acumular puntos (los endpoints de puntos verifican `pv`).

**Why this priority**: Sin teléfono verificado no hay QR ni acumulación (AGENTS.md §8); es el cuello de botella de todo el MVP.

**Independent Test**: Registro con OTP por consola (`OTP_SENDER=console` en dev), verificar `pv=true` en base y que el login devuelve `pv=true` en los claims. Demostrable sin ninguna otra feature.

**Acceptance Scenarios**:

1. **Given** un correo y teléfono `+591` no registrados, **When** `POST /auth/register`, **Then** 201, se envía el OTP (puerto `OtpSender`) y el correo de verificación (puerto `EmailSender`), y `phone_verified=false`.
2. **Given** un teléfono con prefijo distinto de `+591`, **When** `POST /auth/register`, **Then** 422 con `code=PHONE_NOT_SUPPORTED`.
3. **Given** un correo ya registrado, **When** `POST /auth/register` con ese correo, **Then** 409 con `code=CONFLICT` (mismo para teléfono duplicado).
4. **Given** un OTP correcto dentro de 5 minutos, **When** `POST /auth/phone/verify` con teléfono + código, **Then** 200 y `pv=true` en base.
5. **Given** un OTP incorrecto, **When** `POST /auth/phone/verify`, **Then** 422 con `OTP_INVALID`, incrementando el contador de intentos.
6. **Given** 5 intentos fallidos, **When** un sexto intento, **Then** 429/422 con `OTP_TOO_MANY_ATTEMPTS`/`OTP_RATE_LIMITED` y el código queda invalidado.
7. **Given** un reenvío solicitado antes de 60 segundos, **When** `POST /auth/phone/send-otp`, **Then** 429 con `OTP_RATE_LIMITED`.

### User Story 2 - Verificación del correo (Priority: P2)

El cliente abre el enlace/token recibido por correo y su cuenta queda con correo verificado, habilitando la recuperación de contraseña. No es requisito para acumular puntos.

**Why this priority**: Habilita recuperación de cuenta; no bloquea la acumulación (decisión del equipo).

**Independent Test**: Tras registrarse con SMTP real configurado (o `EMAIL_SENDER=console`), tomar el token del correo (buzón real o log) y verificar; comprobar el flag en base.

**Acceptance Scenarios**:

1. **Given** un token de correo válido, **When** `POST /auth/verify-email`, **Then** 204 y el correo queda verificado.
2. **Given** un token vencido o ya usado, **When** `POST /auth/verify-email`, **Then** 422 con `TOKEN_INVALID`.

### User Story 3 - Login y sesión por aplicación (Priority: P1)

Un actor inicia sesión con correo + contraseña indicando su aplicación (`X-Paseo-Client`). Recibe un access token de ≤ 15 min con claims de AGENTS.md §6 y un refresh token: en el cuerpo para `paseo-mobile`; en cookie `HttpOnly; Secure; SameSite=Strict; Path=/api/v1/auth` con nombre propio para las webs (`__Secure-rt_merchant`, `__Secure-rt_admin`).

**Why this priority**: Toda la API autenticada depende de la sesión.

**Independent Test**: Login de un cliente por `paseo-mobile` (refresh en cuerpo) y de un admin por `paseo-web-admin` (refresh en cookie propia); verificar `aud` distinto por aplicación.

**Acceptance Scenarios**:

1. **Given** credenciales válidas y `X-Paseo-Client: paseo-mobile`, **When** `POST /auth/login`, **Then** 200 con `access_token` (aud=`paseo-mobile`) y `refresh_token` en el cuerpo.
2. **Given** credenciales válidas y `X-Paseo-Client: paseo-web-admin`, **When** `POST /auth/login`, **Then** 200 con `Set-Cookie: __Secure-rt_admin=...; HttpOnly; Secure; SameSite=Strict; Path=/api/v1/auth` y aud=`paseo-web-admin`.
3. **Given** credenciales inválidas (existenta o no el correo), **When** `POST /auth/login`, **Then** 401 con `CREDENTIALS_INVALID` y respuesta uniforme.
4. **Given** `X-Paseo-Client: paseo-web-admin` y un usuario sin `role=admin`, **When** `POST /auth/login`, **Then** 403 `FORBIDDEN` (esa audiencia solo existe con rol admin).
5. **Given** tráfico repetido de login/OTP, **When** se supera el límite, **Then** 429 `RATE_LIMITED`.

### User Story 4 - Refresh rotativo y logout (Priority: P1)

El cliente renueva la sesión con su refresh token; el servidor rota el token y detecta reutilización. Cerrar sesión revoca el refresh actual.

**Why this priority**: El refresh rotativo con detección de reutilización es la defensa principal del robo de sesión (AGENTS.md §6).

**Independent Test**: Rotar un refresh y comprobar que el anterior quedó revocado; reutilizar el anterior y comprobar la revocación de la cadena.

**Acceptance Scenarios**:

1. **Given** un refresh válido, **When** `POST /auth/refresh`, **Then** 200 con tokens nuevos y el anterior revocado (hash nuevo en base).
2. **Given** el refresh ANTERIOR reutilizado, **When** `POST /auth/refresh`, **Then** 401 con `TOKEN_REUSE_DETECTED` y revocación de la cadena de esa sesión.
3. **Given** una web, **When** `POST /auth/refresh` sin `X-Paseo-Client` o con `Origin` inválido, **Then** 401/403 y no se emite nada.
4. **Given** sesión iniciada, **When** `POST /auth/logout`, **Then** 204 y el refresh actual revocado (y cookie web vencida).

### User Story 5 - Recuperación de contraseña (Priority: P2)

El cliente pide restablecer su contraseña por correo y la define con el token recibido.

**Why this priority**: Cuenta recuperable sin soporte manual; requiere correo verificado.

**Independent Test**: `forgot` con correo existente y no existente (misma respuesta 202), `reset` con el token recibido por correo (SMTP real vía `SmtpEmailSender`; en pruebas, un `EmailSender` de doble captura).

**Acceptance Scenarios**:

1. **Given** cualquier correo, **When** `POST /auth/password/forgot`, **Then** **siempre 202** (no revela existencia); si el correo existe y está verificado, se envía un token aleatorio de ≥ 32 bytes.
2. **Given** un token válido de un solo uso, **When** `POST /auth/password/reset`, **Then** 204, `token_version++` y revocación de todos los refresh tokens de la cuenta.
3. **Given** el mismo token por segunda vez, **When** `POST /auth/password/reset`, **Then** 422 `TOKEN_INVALID`.

### Edge Cases

- OTP vencido (> 5 min) → 422 `OTP_EXPIRED` y no consume intentos.
- Tope diario de OTP por teléfono y por IP (AGENTS.md §8) → 429 `OTP_RATE_LIMITED`.
- `pv=false` al entrar a funciones que lo exigen → 403 `PHONE_NOT_VERIFIED` (los endpoints de puntos lo aplicarán; aquí el claim viaja ya en el token).
- Concurrencia: dos `refresh` simultáneos con el mismo token → exactamente uno 200, el otro 401.
- Los claims pueden estar desactualizados ≤ 15 min: toda acción sensible futura consulta `users.status` y `token_version` en base (AGENTS.md §6); el login los lee de la base en ese momento.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El registro crea al cliente con `pv=false` y dispara SMS (OTP) + correo de verificación tras los puertos `OtpSender` y `EmailSender`.
- **FR-002**: Solo teléfonos `+591` (E.164); otro prefijo → `PHONE_NOT_SUPPORTED`. Regex laxa `^\+591[0-9]{8}$` hasta verificar la regla de numeración (OPEN_DECISIONS).
- **FR-003**: El SMS solo se envía al registrarse (y, en una spec posterior, al cambiar de teléfono); nunca en cada login.
- **FR-004**: OTP de 6 dígitos: solo su hash en base, vigencia 5 min, máximo 5 intentos, reenvío con espera de 60 s, topes por teléfono e IP.
- **FR-005**: Login único para todos los roles; responde por audiencia según `X-Paseo-Client`; `paseo-web-admin` solo con `role=admin`.
- **FR-006**: Claims exactamente: `iss, aud, sub, iat, exp, jti, role, cid, est, br, pv, ev, tv`; access ≤ 900 s; firma con `kid`.
- **FR-007**: Refresh rotativo guardado como hash con detección de reutilización; `logout` revoca el refresh actual.
- **FR-008**: `forgot` siempre 202; token de recuperación ≥ 32 bytes aleatorios, hasheado, 30 min, un solo uso; `reset` hace `token_version++` y revoca refresh tokens.
- **FR-009**: `docs/openapi.yaml` se actualiza ANTES de implementar cualquier ruta (ajustar `otp/verify`→`phone/verify`, `otp/resend`→`phone/send-otp`, añadir `verify-email`).
- **FR-010**: El worker limpia a intervalos los OTP, tokens de recuperación y QR vencidos (INFRASTRUCTURE.md §8); en esta spec: OTP y tokens de recuperación.
- **FR-011**: Toda escritura de identidad (registro, verificaciones, login, refresh, reset) queda en `audit_log` (regla 2.4). Como `audit_log` estaba prevista para V009, se adelanta una versión mínima a V002; la completa (con `fraud_*`) sigue en V009.

### Security, Privacy, and Integrity Requirements

- **SEC-001**: Contraseñas con **Argon2id** en formato PHC, parámetros mínimos OWASP, fuera del hilo principal (AOT/aislado); la librería concreta es OPEN.
- **SEC-002**: Sin datos personales en el JWT (regla 8); el comercio verá nombre enmascarado (fuera del alcance de esta spec, pero el modelo lo permite).
- **SEC-003**: Cookies web: `HttpOnly; Secure; SameSite=Strict; Path=/api/v1/auth`, nombre propio por aplicación; nunca compartidas entre webs.
- **SEC-004**: `POST /auth/refresh` de web exige `X-Paseo-Client` y valida `Origin`.
- **SEC-005**: ~~RLS desde la primera tabla~~ **SUPERSEDIDA (decisión del equipo 03/10/2026): MVP sin RLS** (AGENTS.md §2 regla 7). Las tablas nacen solo con `GRANT` mínimos para `paseo_app`; `audit_log` mantiene el `REVOKE UPDATE, DELETE, TRUNCATE`. La reintroducción de RLS + pruebas de aislamiento es deuda bloqueante pre-producción.
- **SEC-006**: Prohibido en logs: contraseñas, OTP, tokens, teléfonos y correos completos (AGENTS.md §8; INFRASTRUCTURE.md §13). Logs JSON con `correlation_id`.
- **SEC-007**: Límites de peticiones en login, OTP y recuperación (códigos 429).
- **SEC-008**: El rol `app.role='system'` quedaba reservado a los adaptadores de identidad para el contexto RLS. Sin RLS en el MVP, se mantiene la convención de contexto por transacción (`set_config(..., true)`) como preparación para la reintroducción, pero no es obligatoria.

### Key Entities *(include if data is involved)*

- **users**: identidad de todo actor. Correo `citext` único, hash de contraseña, `role`, `status`, `token_version`, flags de verificación. Sin teléfono en `users` de comercios/admin; el teléfono vive en clientes.
- **customers**: perfil del cliente: `user_id`, teléfono E.164 único, nombre (visible enmascarado), `phone_verified_at`.
- **verification_codes**: OTP: hash del código, teléfono, propósito, expiración, intentos, `consumed_at`. Nunca el código en claro.
- **password_resets**: hash del token, expiración 30 min, `used_at` (un solo uso).
- **refresh_tokens**: hash del token, `jti`, familia/cadena para detección de reutilización, expiración, `revoked_at`, usuario y audiencia.
- **audit_log** (mínima, adelantada): quién (`role`/`user_id` cuando exista), acción, entidad, `correlation_id`, fecha UTC. Sin payload con datos personales.

## API and Contract Impact

- [ ] No API impact
- [x] `docs/openapi.yaml` update required before implementation
- [x] New/changed RFC 9457 error code required: `OTP_TOO_MANY_ATTEMPTS`, `OTP_RATE_LIMITED`, `PHONE_NOT_VERIFIED`, `TOKEN_INVALID` (ya listados; confirmar contra contrato)
- [ ] Cursor pagination, UTC timestamps, or integer-cent amounts affected

## Database Impact

- [ ] No database impact
- [x] New Flyway migration required: `infra/migrations/V002__identidad.sql`
- [x] ~~RLS/policies/`GRANT` required~~ `GRANT` mínimos obligatorios (RLS diferido por decisión del equipo 03/10/2026)
- [x] ~~RLS isolation test required~~ Diferido junto con RLS (deuda bloqueante pre-producción)
- [ ] Migration immutability check affected

## Success Criteria *(mandatory)*

- **SC-001**: Flujo completo de la HU-01/HU-02 demostrable en local: registro → OTP por consola → `pv=true` → login con `aud` correcto por cliente.
- **SC-002**: Todos los escenarios de aceptación cubiertos por pruebas (unitarias de dominio + integración contra PostgreSQL con `paseo_app`), verdes en CI, y `redocly lint` sin errores tras actualizar el contrato.
- **SC-003**: Ningún log, claim ni respuesta contiene datos personales; verificado por revisión y prueba de forma de respuesta.

## Assumptions

- El registro es de **clientes**; staff/comercios se dan de alta en una spec posterior (V003+).
- La verificación de correo NO es requisito para acumular; solo habilita recuperación (interpretación de encuesta a confirmar por el equipo).
- `audit_log` mínima se adelanta a V002 (su versión completa con `fraud_*` sigue en V009).
- **OPEN**: proveedor de SMS y correo; librería Argon2id; regex de teléfono endurecida; interpretaciones de la encuesta.

## Persona 1 Enhancements

- **QR Endpoint**: `GET /api/v1/customers/me/qr` returns a signed QR ticket containing the customer ID and an expiry timestamp. The ticket is valid for 5 minutes and is intended for merchant‑side recognition.
- **Flutter UI** (in `apps/mobile/lib/features/identity`):
  - Registration flow screens – email, phone, password input and OTP entry view.
  - Phone OTP verification screen.
  - Login screen with `X‑Paseo‑Client: paseo‑mobile` and refresh handling.
  - Profile screen that displays and allows editing of customer data; includes a QR viewer component (`qr_view.dart`).
  - Responsive design: use `LayoutBuilder` and `MediaQuery` to adjust layout for mobile and desktop, passing tests for at least three common breakpoints.

- **New Tasks**: `T099–T104` in `tasks.md` cover the Flutter implementation.

## Definition of Done

- [ ] Spec reviewed and approved by a human
- [ ] Plan written and approved
- [ ] Tasks written and traceable
- [ ] Contract updated before implementation, if API changes
- [ ] Tests written before behavior changes
- [ ] Security, RLS, audit, and idempotency rules checked when applicable
