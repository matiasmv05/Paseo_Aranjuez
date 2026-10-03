# 9. Stack Tecnológico — Paseo Points (v2)

> Borrador técnico de las secciones 9.1 a 9.18. Las secciones 9.10 a 9.18 (entorno, pruebas, despliegue, integración, trazabilidad, alternativas, decisiones y roadmap) corresponden a Brayan y quedan redactadas aquí como base para su revisión.
> **Fuentes de verdad:** este documento define *qué y por qué*. `INFRASTRUCTURE.md` define *dónde corre cada cosa y cómo se levanta*. `AGENTS.md` define *las reglas que obedece el agente de IA*. Si hay contradicción, se corrige en el mismo PR; nunca se deja una versión desactualizada.
> **v2 (02/10/2026):** incorpora la encuesta a comercios, Flyway versionado desde el inicio, claims JWT, RLS en PostgreSQL, motor de conversión variable y validación por teléfono + correo.
> **v2.1:** añade **reembolsos** (el personal solicita, el administrador aprueba, los puntos se revierten por el ledger) y **sucursales**.
> **v2.2:** añade las secciones 9.10 a 9.18 y aplica las decisiones del equipo (ver 'Decisiones del equipo y pendientes' al final).

---

## 0. Correcciones críticas antes de escribir (leer primero)

1. **"No hay backend/frontend" es incorrecto.** Una app Flutter no puede hablar directo con PostgreSQL: pondría credenciales dentro del APK, no protegería reglas de negocio y no garantizaría atomicidad de puntos (RNF-05) ni auditoría (RNF-06). La sección 3.1 del documento ya dice "backend expuesto mediante API REST" y RNF-07 exige "APIs REST documentadas". **Hay backend**; lo que no hace falta es otro lenguaje: todo en Dart.
2. **Monorepo:** se justifica por compartir un paquete de contratos (DTOs, enums, validaciones) entre cliente y servidor, no por "front y back separados".
3. **Hexagonal donde importa:** backend hexagonal completo; Flutter feature-first con capas ligeras (`presentation / application / data`). Si el tiempo aprieta, lo primero que se recorta es la hexagonal en el cliente.
4. **El servidor es la única fuente de verdad.** El cliente nunca calcula puntos de forma autoritativa. Esto incluye la conversión: el cliente puede mostrar una *vista previa*, pero el valor lo devuelve el backend.
5. **Plataformas (decisión del equipo):** tres artefactos de un mismo código Flutter: **app móvil** (cliente y comercio), **web de comercio** (computadora; 6 de 15 comercios la prefieren) y **web de administración**. Las dos webs son **builds separados servidos en dos puertos**. Ver 9.4.1 y 9.12.1.
6. **QR estático = fraude fácil.** El QR es un token firmado de ~60 s (9.8.5).
7. **Numeración del documento oficial:** hay dos secciones "3.1" y el índice salta del 1.3 al 3. Corregir antes de entregar.
8. **Uso correcto de la encuesta.** Son 15 respuestas, 14 de ellas recibidas en ~37 minutos el mismo día: es una **validación exploratoria por conveniencia**, no un estudio de mercado. En el documento oficial debe citarse así y con los conteos absolutos ("9 de 15"), no con porcentajes que aparenten precisión. Ver Anexo D.

### 0.1 Qué cambió en v2

| # | Cambio | Motivo |
|---|--------|--------|
| 1 | Flyway (versión fija) reemplaza a `dbmate`; migraciones `V001__…` desde el primer día | Pedido del equipo; versionado inmutable y validación de checksum |
| 2 | Claims JWT definidos (rol, comercio, cliente, verificación) | Pedido del equipo; base de la autorización |
| 3 | RLS en PostgreSQL con rol de aplicación sin privilegios de dueño | Pedido del equipo; defensa en profundidad contra fugas entre comercios |
| 4 | Motor de conversión de puntos variable (por alcance, campañas, redondeo, topes) | Pedido del equipo; encuesta: 7/15 cambian ofertas en fechas especiales |
| 5 | Registro con **teléfono + correo verificados**: correo para recuperar cuenta, teléfono para identificarse dictándolo en caja | Pedido del equipo; encuesta: 7/15 no prefieren QR |
| 6 | Roles de comercio: `merchant_owner` y `merchant_cashier`; `seller_user_id` en cada compra | Encuesta: 4/15 piden actividad por vendedor |
| 7 | Recompensas con tipo (`PERCENT`, `FIXED`, `GIFT`) y propuesta del comercio con aprobación del admin | Encuesta: 12/15 quieren descuento porcentual; ofertas cambian seguido |
| 8 | Dashboard del comercio (`/merchant/stats`) | Encuesta: 8/15 clientes que regresan, 5/15 puntos cargados |
| 9 | Alerta de canje y resumen periódico suben de prioridad; se añade `worker` programado | Encuesta: 8/15 alerta de canje, 8/15 resumen de ventas |
| 10 | Se elimina `SELECT … FOR UPDATE` sobre el saldo: el saldo lo mantiene un trigger sobre el ledger | Compatible con RLS (el rol de la API no tiene `UPDATE` sobre saldos) y sin condición de carrera |
| 11 | Identificación por **CI queda descartada** del MVP | Dato sensible innecesario: el teléfono verificado cumple la función |
| 12 | **Reembolsos:** el personal solicita, el admin aprueba o rechaza, y la reversión de puntos es un movimiento `REVERSAL` del ledger (9.5.7) | Requisito nuevo del equipo (no proviene de la encuesta) |
| 13 | **Sucursales:** nueva tabla `branches`; `purchases.branch_id`; claim `br` para el personal | La solicitud de reembolso debe indicar sucursal; el modelo anterior no la tenía |
| 14 | Regla antifraude 5: tasa anómala de reembolsos por vendedor o comercio | Los reembolsos son un vector de abuso nuevo |
| 15 | **v2.2:** decisiones del equipo aplicadas: dos builds web en dos puertos, Argon2id, SMS como mínimo + correo, solo `+591`, conversión fijada por el admin, puntos sobre monto neto, cajero puede solicitar reembolso, solo reembolso total, sucursal fija por cajero, factura = foto + número + razón social | Respuestas del equipo a los pendientes 1–18 |
| 16 | Se añaden las secciones 9.10 a 9.18 | Pedido del equipo |

---

## 9.1 Criterios de Selección Tecnológica

| # | Criterio | Origen | Peso |
|---|----------|--------|------|
| C1 | Tiempo de entrega (MVP en hackathon) | Restricción 5.2 | Alto |
| C2 | Una sola base de código Android/iOS/Web | Objetivo general + encuesta (6/15 usan PC) | Alto |
| C3 | Integridad transaccional de puntos | RNF-05, HUT-04 | Alto |
| C4 | API REST documentada | RNF-07, HUT-07 | Alto |
| C5 | Seguridad (hash, HTTPS, roles, aislamiento por comercio) | RNF-01, RNF-02 | Alto |
| C6 | Tecnologías libres / sin costo de licencia | Restricción 5.2 | Medio |
| C7 | Baja curva de aprendizaje y un solo lenguaje | Equipo de 4 | Medio |
| C8 | Reproducibilidad del entorno (Docker) | Demo en vivo | Medio |
| C9 | Compatibilidad con desarrollo asistido por agentes de IA | Metodología SDD | Medio |
| C10 | Evolución futura (Jarvis Paseo, PaseoYa) | RNF-07, RNF-10 | Bajo |
| C11 | Migraciones versionadas e inmutables | Pedido del equipo | Medio |

**Matriz de decisión resumida (1–5, mayor es mejor):**

| Opción de backend | C1 | C3 | C4 | C7 | C9 | Total |
|-------------------|----|----|----|----|----|-------|
| **Dart Frog + PostgreSQL** | 4 | 5 | 5 | 5 | 4 | **23** |
| Serverpod | 5 | 4 | 2 | 5 | 4 | 20 |
| NestJS (TypeScript) | 3 | 5 | 5 | 3 | 5 | 21 |
| Supabase / Firebase (BaaS) | 5 | 3 | 3 | 4 | 4 | 19 |

> Puntajes del autor: evaluación razonada, no medición. Serverpod pierde en C4 (RPC generado, no REST abierto). NestJS es válida pero rompe C7. Nota: RLS con claims en Postgres es la propuesta de valor de Supabase; aquí se replica con PostgreSQL propio (9.6.5) para conservar C3 y el requisito de PostgreSQL en Docker.

---

## 9.2 Arquitectura Tecnológica

### Vista general

```
┌────────────────────────────┐     HTTPS / JSON     ┌─────────────────────────┐
│ App Flutter (un código)    │ ───────────────────► │ Caddy (TLS, proxy)      │
│  · Móvil: cliente, comercio│                      └───────────┬─────────────┘
│  · Web comercio  (:443)    │                                  │
│  · Web admin     (:8443)   │                      ┌───────────▼─────────────┐
└────────────────────────────┘                      │ API Dart Frog           │
                                                    │ (hexagonal)             │
                              ┌─────────────────────┤  + claims JWT           │
                              │                     └───────────┬─────────────┘
                   ┌──────────▼─────────┐                       │ SQL (pool, rol paseo_app)
                   │ worker (mismo      │           ┌───────────▼─────────────┐
                   │ binario, jobs)     │──────────►│ PostgreSQL 18 + RLS     │
                   └────────────────────┘           │ migrado por Flyway      │
                                                    └─────────────────────────┘
        Salientes: SMTP (correo) · proveedor OTP (teléfono) · FCM (push)
```

### Arquitectura hexagonal del backend

```
          ┌──────────────── adapters/in ────────────────┐
          │  HTTP routes (Dart Frog), middlewares (JWT,  │
          │  rate limit), validación de DTOs, errores    │
          └───────────────────┬──────────────────────────┘
                              │ llama a
          ┌───────────────────▼──────────────────────────┐
          │              application                      │
          │  Casos de uso: RegistrarCompra, PrevisualizarCompra,
          │  CanjearRecompensa, ValidarCanje, IdentificarCliente,
          │  VerificarTelefono, RecuperarCuenta,          │
          │  SolicitarReembolso, ResolverReembolso ...    │
          │  Puertos: PointsLedgerPort, CustomerRepository,
          │  OtpSender, EmailSender, Clock, TokenSigner...│
          └───────────────────┬──────────────────────────┘
                              │ usa
          ┌───────────────────▼──────────────────────────┐
          │                 domain                        │
          │  Entidades, value objects (Points, Money, Phone),
          │  reglas (PointsCalculator, RuleResolver,      │
          │  FraudRules). Dart puro, sin framework        │
          └───────────────────▲──────────────────────────┘
                              │ implementa puertos
          ┌───────────────────┴──────────────────────────┐
          │              adapters/out                     │
          │  Postgres*Repository, JwtTokenSigner,         │
          │  SmtpEmailSender, SmsOtpSender, FcmPush ...   │
          └───────────────────────────────────────────────┘
```

**Regla de dependencia (verificable en CI):** `domain` no importa nada; `application` solo importa `domain`; `adapters` importan `application` y `domain`; nada importa a los `adapters`.

### Estructura del monorepo

```
paseo-points/
├── AGENTS.md                  # Reglas para agentes (CLAUDE.md importa este archivo)
├── INFRASTRUCTURE.md          # Dónde corre qué; cómo se levanta
├── apps/
│   ├── mobile/                # Flutter feature-first; entradas: main.dart (móvil), main_merchant_web.dart, main_admin_web.dart
│   └── api/                   # Dart Frog (hexagonal)
│       ├── bin/{server,worker}.dart
│       └── lib/{domain,application,adapters/{in,out}}/
├── packages/
│   └── paseo_shared/          # DTOs, enums, errores de contrato (Dart puro)
├── infra/
│   ├── docker-compose.yml     # + docker-compose.dev.yml (override)
│   ├── Caddyfile
│   ├── api.Dockerfile
│   ├── db/init/               # roles y extensiones (se ejecuta una vez)
│   ├── migrations/            # Flyway: V001__*.sql (inmutables)
│   ├── seed/                  # R__seed_dev.sql (solo desarrollo)
│   └── backup/
├── specs/                     # Especificaciones SDD
├── docs/openapi.yaml          # Contrato REST
├── .specify/                  # Constitución y plantillas de Spec Kit
└── pubspec.yaml               # workspace raíz
```

Se gestiona con **pub workspaces** y, opcionalmente, **Melos**. Se comparte solo `paseo_shared`; el dominio del backend **no** se comparte con Flutter.

---

## 9.3 Stack Tecnológico Seleccionado

### 9.3.1 Lenguajes
| Lenguaje | Uso | Justificación |
|----------|-----|---------------|
| **Dart** | App, backend, worker, paquete compartido | Un lenguaje (C7), contratos compartidos |
| **SQL** | Migraciones Flyway, RLS, triggers, restricciones | La integridad de puntos y el aislamiento se refuerzan en la base |
| **YAML** | OpenAPI, Docker Compose, CI | Estándar |
| **Markdown** | Specs SDD, `AGENTS.md`, `INFRASTRUCTURE.md` | Entrada de los agentes |

### 9.3.2 Frontend
Flutter (estable vigente; versión fijada con FVM), Riverpod, go_router, Dio, freezed + json_serializable, flutter_secure_storage, mobile_scanner, qr_flutter, fl_chart, firebase_messaging (alerta de canje).

### 9.3.3 Backend
Dart Frog (sobre Shelf), paquete `postgres`, `dart_jsonwebtoken`, **Argon2id** (librería a validar con benchmark, ver 9.15.5), `logging`, mocktail + `test`. Envío de correo por SMTP (paquete a confirmar en pub.dev).

### 9.3.4 Base de datos y migraciones
**PostgreSQL 18** en Docker (versión mayor fija; verificado como rama estable vigente, con 18.6 como última menor publicada en agosto de 2026) y **Flyway Community** en contenedor, con versión fija (9.6.6).

### 9.3.5 Comunicación e integración
REST sobre HTTPS, JSON, OpenAPI 3.x, prefijo `/api/v1`. FCM para push. SMTP para correo. Proveedor de OTP por teléfono tras un puerto (`OtpSender`), con adaptador de consola para desarrollo.

### 9.3.6 Seguridad
JWT de acceso corto con claims de rol/comercio/cliente, refresh rotativo, hash de contraseñas, RLS, TLS con Caddy, QR firmado y de corta vida, verificación de correo y teléfono, límite de peticiones, auditoría.

> **Verificar al inicializar el proyecto:** versiones de paquetes en pub.dev, y que la etiqueta Docker de Flyway y PostgreSQL existan (`docker pull`). Este documento fija la versión de Flyway y de PostgreSQL; no fija versiones de paquetes Dart.

---

## 9.4 Frontend

### 9.4.1 Framework
**Flutter**: Android, iOS y **Web**.

| Rol | Móvil | Web comercio (puerto 443) | Web administración (puerto 8443) |
|-----|-------|---------------------------|----------------------------------|
| Cliente | ✅ principal | — | — |
| Cajero / dueño | ✅ (9/15 lo prefieren) | ✅ (6/15 prefieren computadora) | — |
| Administrador | — | — | ✅ |

**Decisión del equipo:** el panel de comercio y el de administración son **dos builds web separados, servidos en dos puertos**. Es el mismo código con **tres puntos de entrada** (`main.dart`, `main_merchant_web.dart`, `main_admin_web.dart`); cada build incluye solo las rutas de su rol (9.12.1).

### 9.4.2 Lenguaje
**Dart** con análisis estricto (`very_good_analysis` o equivalente).

### 9.4.3 Librerías
| Necesidad | Librería |
|-----------|----------|
| Navegación y guardas por rol | `go_router` |
| HTTP | `dio` |
| Modelos | `freezed`, `json_serializable` |
| Tokens | `flutter_secure_storage` (móvil); en web ver nota |
| Mostrar QR | `qr_flutter` |
| Escanear QR | `mobile_scanner` |
| Gráficos | `fl_chart` |
| Push | `firebase_messaging` |
| Foto de factura (reembolsos) | `image_picker` |
| Pruebas | `flutter_test`, `mocktail` |

> **Web (aplicado):** `flutter_secure_storage` en web no ofrece la protección de Keychain/Keystore. En los builds web el access token vive **solo en memoria** y se renueva con un refresh token en cookie `HttpOnly; Secure; SameSite=Strict`, con nombre propio por aplicación. Detalle y riesgos en 9.8.3 y 9.12.1. *(Se interpreta que el "sí" del equipo aceptó esta propuesta; confirmar.)*

### 9.4.4 Estado
**Riverpod** con `AsyncNotifier`.

### 9.4.5 Comunicación con backend
`Dio` con interceptores (token, un refresh ante 401, `problem+json` → excepciones tipadas). DTOs de `paseo_shared`. Escrituras críticas con `Idempotency-Key`.

### 9.4.6 Pantalla de caja del comercio (requisito de la encuesta)
La encuesta muestra que 10/15 aceptan 10–30 s por operación y 4/15 piden menos de 10 s. Requisitos de diseño:

- Flujo en **máximo 3 interacciones**: identificar → monto → confirmar.
- Identificación con **tres métodos en la misma pantalla**: escanear QR (8/15), **dictar teléfono** (4/15) y, como referencia opcional, número de factura (3/15, ver 9.5.6).
- En web, **la entrada manual del teléfono es el camino principal**; el escaneo con webcam se ofrece pero debe probarse (no verificado: calidad de lectura de una pantalla de celular con webcam de laptop).
- **Vista previa de puntos** antes de confirmar (`/merchant/purchases/preview`).
- Meta de diseño propia (no proviene de la encuesta): p95 de identificar + registrar < 500 ms en servidor; el resto del tiempo es del usuario.

**Organización feature-first:**
```
lib/features/<feature>/{presentation, application, data}
```
Features: `auth`, `verification`, `profile_qr`, `points`, `rewards`, `promotions`, `establishments`, `merchant_pos`, `merchant_dashboard`, `refunds`, `admin`.

---

## 9.5 Backend

### 9.5.1 Framework
**Dart Frog** (REST explícito, middleware con DI).

### 9.5.2 Lenguaje
**Dart.**

### 9.5.3 Arquitectura interna
Hexagonal (9.2). Rutas = adaptadores finos. Ninguna regla de negocio en una ruta.

### 9.5.4 Acceso a datos
**Sin ORM.** SQL explícito sobre `postgres` con pool. Cada caso de uso abre una transacción, **fija el contexto RLS** (9.6.5) y ejecuta. Las migraciones las aplica **Flyway** (9.6.6), nunca la aplicación.

### 9.5.5 Servicios por contexto
`Identity` (registro, verificación, recuperación), `Loyalty` (compras, puntos, conversión), `Rewards`, `Refunds` (solicitud y resolución), `Promotions`, `Merchants` (staff, sucursales, dashboard), `Analytics`, `Notifications`, `Fraud`, `Audit`.

### 9.5.6 Motor de conversión de puntos (variable)

La conversión Bs → puntos **no es una constante**: es dato versionado en `points_rules`, resuelto por el dominio y fijado en cada compra.

**Fórmula (aritmética entera, sin `float`):**

```
puntos_base = redondear( monto_centavos × puntos_otorgados / monto_por_tramo_centavos )
puntos      = redondear( puntos_base × multiplicador_bp / 10000 )     -- campañas
puntos      = min(puntos, tope_puntos_por_compra)  si hay tope
puntos      = 0  si monto < compra_minima
```
`redondear` ∈ {`FLOOR`, `ROUND`, `CEIL`}, definido por la regla. Ejemplo: "1 punto cada Bs 10" = `monto_por_tramo=1000`, `puntos_otorgados=1`. Con `multiplicador_bp=20000` en una fecha especial, vale ×2.

**Alcances y resolución (de más a menos específico):**

| Tipo | Alcance | Quién lo define |
|------|---------|-----------------|
| `BASE` | `ESTABLISHMENT` (un comercio) | **Administrador** |
| `BASE` | `CATEGORY` (categoría de comercio) | Admin |
| `BASE` | `GLOBAL` (valor por defecto) | Admin |
| `CAMPAIGN` | Cualquiera de los anteriores, con `valid_from/valid_to` | **Administrador** |

Resolución: se elige **una** regla `BASE` activa (ESTABLISHMENT > CATEGORY > GLOBAL; empate por `priority`) y **como máximo una** `CAMPAIGN` activa aplicable (la de mayor `priority`). Las campañas no se acumulan entre sí.

**Decisión del equipo:** la conversión de cada comercio, y sus campañas, las fija **solo el administrador**. El comercio no propone ni edita reglas de conversión (sí propone recompensas, que el administrador aprueba).

**Invariantes:**
1. Una regla activa **nunca se edita**: se crea una nueva versión y la anterior se retira (`valid_to`). HU-17: el cambio aplica solo a compras futuras.
2. `purchases` guarda `rule_id`, `campaign_rule_id` (nullable) y un `rule_snapshot` JSON con los parámetros usados. La compra es reproducible aunque la regla cambie o se borre lógicamente.
3. El cálculo vive en `domain/PointsCalculator` y `domain/RuleResolver`, con pruebas basadas en tabla (monto, regla → puntos esperado), incluyendo bordes de redondeo.
4. El cliente jamás calcula: usa `/merchant/purchases/preview`, que invoca el mismo código que el registro.
5. Si no hay regla aplicable se rechaza con `NO_APPLICABLE_RULE`; nunca se asume un valor.

**Referencia de factura (3/15 en la encuesta):** `purchases.invoice_ref` es **opcional**, con unicidad `(establishment_id, invoice_ref)`. No identifica al cliente; sirve para impedir que el mismo ticket genere puntos dos veces. Si el comercio quiere hacerla obligatoria, es una opción por establecimiento.

**Descuentos canjeados (decisión del equipo):** los puntos se calculan sobre el **monto neto, es decir, el efectivamente pagado tras el descuento**. `purchases` guarda `gross_cents`, `discount_cents` y `net_cents`, y la fórmula usa `net_cents` donde dice "monto".

### 9.5.7 Reembolsos (reversión de puntos)

**Principio:** el personal **solicita**, solo el administrador **resuelve**, y los puntos se revierten **únicamente** con un movimiento `REVERSAL` en el ledger. Nadie edita ni borra la compra ni el crédito original.

**Contenido de la solicitud.** El equipo definió que el personal aporta solo **la foto de la factura, el número de la factura y la razón social**. Además, la solicitud debe mostrar sucursal y hora: **no las escribe el personal**, las copia el servidor desde la compra, para que no puedan falsearse.

| Dato | Quién lo aporta | Origen |
|------|-----------------|--------|
| **Foto de la factura** | Personal | Imagen obligatoria (ver almacenamiento más abajo) |
| **Número de la factura** | Personal | Texto obligatorio |
| **Razón social** (la que figura en la factura) | Personal | Texto obligatorio |
| Referencia registrada en la compra (`invoice_ref`) | Servidor | Si existe, se **compara** con el número ingresado; una diferencia genera una marca para el administrador (no bloquea la solicitud) |
| **Sucursal** (nombre y dirección) | Servidor | `purchases.branch_id`, con copia (*snapshot*) en la solicitud |
| **Fecha y hora de la compra** | Servidor | `purchases.created_at` |
| Fecha y hora de la solicitud | Servidor | `now()` |
| Solicitante (usuario y rol) | Servidor | Claims del JWT |
| Monto y puntos a revertir | Servidor | De la compra y del crédito en el ledger |
| Motivo (código de una lista corta) | Personal | **Opcional**, sugerencia del autor: el equipo definió solo los tres datos de la factura; sin motivo, el administrador decide solo con la evidencia |

**Flujo y estados:**

```
PENDING ──(admin aprueba)──► APPROVED   → se inserta REVERSAL en el ledger
   │
   ├────(admin rechaza, con nota obligatoria)──► REJECTED
   ├────(el solicitante cancela)────────────────► CANCELLED
   └────(vence la ventana, si se adopta)────────► EXPIRED
```

**Reglas:**
1. Solo se solicita sobre compras **con puntos acreditados** del propio comercio. El **cajero puede solicitar** (decisión del equipo), solo sobre las compras que él registró; el dueño, sobre cualquiera de su comercio.
2. **Una sola solicitud abierta por compra** (índice único parcial sobre `PENDING`) y **un solo `REVERSAL` por crédito** (índice único sobre `reverses_ledger_id`). Esto impide doble reembolso aunque dos admins aprueben a la vez.
3. **Separación de funciones:** quien solicita no puede aprobar. Aprobar o rechazar es exclusivo de `admin` (RLS y middleware).
4. **Solo reembolso total** de la compra (decisión del equipo); no existe reembolso parcial por monto.
5. **La aprobación es una sola transacción:** (a) pasar la solicitud a `APPROVED` con `WHERE status='PENDING'` (sin fila = ya resuelta, 409); (b) insertar el `REVERSAL` con `reverses_ledger_id`; (c) guardar `points_reversed`, `unrecovered_points` y `reversal_ledger_id`; (d) escribir `audit_log` y las notificaciones. Si algo falla, no queda nada a medias.
6. El cliente ve en su historial un movimiento de reversión con motivo genérico y recibe notificación. No ve la nota interna del administrador.
7. **Ventana configurable (decisión del equipo):** solo se puede solicitar dentro de `refund_window_days` desde la compra, parámetro de `system_settings` que el administrador puede cambiar; fuera de la ventana: `REFUND_WINDOW_EXPIRED`. El valor inicial lo define el equipo. Si además se configura `refund_request_ttl_days`, el `worker` pasa a `EXPIRED` las solicitudes `PENDING` vencidas.

**Foto de la factura: almacenamiento y manejo.**
- Formatos JPEG, PNG o WebP; tamaño máximo configurable (valor inicial propuesto: 5 MB tras comprimir en el cliente). El servidor valida por **contenido** (firma del archivo), no por extensión.
- Se recomprime en el servidor para eliminar metadatos EXIF (por ejemplo, la ubicación del dispositivo); la librería de imágenes está por confirmar.
- Se guarda en el volumen `uploads` con nombre aleatorio (UUID). `refund_attachments` guarda `sha256`, tipo, tamaño y comercio propietario. **No hay URL pública**: se entrega por la API tras comprobar rol y comercio, con `X-Content-Type-Options: nosniff`.
- La API recibe la solicitud como `multipart/form-data` (la lectura de formularios en la versión de Dart Frog usada debe verificarse en su documentación).
- Una factura puede contener datos de terceros (nombres, documentos): acceso solo del administrador y del comercio solicitante, cada descarga queda en `audit_log` y hace falta una **política de retención** (plazo por definir; no se han revisado aquí las obligaciones fiscales de conservación).
- La foto no prueba autenticidad: el administrador la contrasta con la compra y el sistema compara el número con `invoice_ref`. El equipo no precisó si la razón social es la del **comprador o la del emisor**; se guarda como texto y se muestra tal cual (pendiente).

**El problema que el requisito no resuelve: el cliente ya gastó los puntos.** Si el saldo es menor que los puntos a revertir, un `REVERSAL` completo dejaría saldo negativo, y eso viola la constitución (saldo nunca negativo). Opciones:

| Opción | Efecto | Evaluación |
|--------|--------|------------|
| A. Rechazar la aprobación | El comercio pierde el reembolso | Injusto para el comercio |
| **B. Reversión parcial hasta el saldo disponible** y registrar el faltante en `unrecovered_points` | Se mantiene el invariante; la diferencia queda trazada | **Propuesta por defecto** |
| C. Permitir saldo negativo (deuda) | Cambia el modelo y el `CHECK` | Descartada: complica canjes, RLS y la defensa del ledger |

Con B, el administrador ve el faltante antes de aprobar y decide `FULL` (falla con `INSUFFICIENT_POINTS_FOR_REVERSAL` si no alcanza) o `PARTIAL`. **Decisión del equipo: se aplica la opción B.**

**Si la compra usó un descuento canjeado:** en el MVP el reembolso **no** restituye el código de canje ni los puntos gastados en él; solo revierte los puntos ganados por esa compra. **Decisión del equipo: no se restituye.**

**Antifraude de reembolsos:** un reembolso aprobado quita puntos pero un comercio deshonesto puede abusar del flujo en ambos sentidos (acreditar y luego reembolsar para dejar rastro limpio, o reembolsar masivamente). Se añade la regla 5 (9.8.7) y todo queda en `audit_log`.

**Sin usuario de reembolso "directo":** no existe endpoint para que el comercio revierta por su cuenta. Un reembolso nunca es inmediato; la demora hasta que el admin responde es el costo de seguridad aceptado.

---

## 9.6 Base de Datos

### 9.6.1 Sistema gestor
PostgreSQL 18 en Docker.

### 9.6.2 Modelo de datos — principios
- **Ledger de solo inserción:** el saldo es la suma de movimientos. Nunca se edita ni borra un movimiento; las anulaciones son movimientos `REVERSAL` que referencian al original.
- **Conversión versionada** (9.5.6).
- **Dinero en centavos** (`BIGINT`) o `NUMERIC`, nunca `float`.
- **Saldo mantenido por trigger** sobre el ledger (el rol de la API no puede actualizar saldos directamente).
- Teléfonos en **E.164**, **solo bolivianos (`+591`)** por decisión del equipo.

### 9.6.3 Tablas

| Tabla | Descripción |
|-------|-------------|
| `users` | `email` (único, normalizado), `email_verified_at`, `phone_e164` (único, solo `+591`), `phone_verified_at`, `password_hash` (Argon2id, formato PHC), `role`, `status`, `token_version` |
| `verification_codes` | OTP de teléfono/correo: hash del código, propósito, expiración, intentos |
| `password_resets` | Token de recuperación (hash), expira, uso único |
| `customers` | Perfil (1:1 con `users`), nombre para mostrar |
| `establishments` | Comercio, categoría, ubicación, baja lógica, `max_purchase_cents`, `compliance_status` |
| `branches` | Sucursales: `establishment_id`, nombre, dirección, `status`. Todo comercio tiene al menos una (se crea una sucursal "Principal" automáticamente; propuesta del autor para comercios de una sola sede) |
| `establishment_staff` | `user_id`, `establishment_id`, `staff_role` (`OWNER`/`CASHIER`), `branch_id` (**un cajero tiene una sola sucursal fija**, obligatoria; nula para `OWNER`, que opera en todas) |
| `points_rules` | Reglas de conversión versionadas (9.5.6) |
| `purchases` | Comercio, **`branch_id`**, cliente, **`seller_user_id`**, `gross_cents`, `discount_cents`, `net_cents`, `invoice_ref`, reglas aplicadas + snapshot, `idempotency_key` único |
| `points_ledger` | `delta`, tipo (`CREDIT`, `REDEEM`, `ADJUST`, `BONUS`, `REVERSAL`), referencias, `reverses_ledger_id` (único cuando no es nulo) |
| `customer_balances` | Saldo derivado (trigger), `CHECK (balance >= 0)` |
| `rewards` | `reward_type` (`PERCENT`,`FIXED`,`GIFT`), valor, tope de descuento, costo en puntos, stock, vigencia, `establishment_id`, `status` (`DRAFT`,`PENDING`,`ACTIVE`,`PAUSED`,`RETIRED`), `approved_by` |
| `redemptions` | Código de un solo uso, `ISSUED/USED/EXPIRED`, comercio que lo validó |
| `promotions` | Promociones con estado de aprobación |
| `special_dates` | Calendario de fechas festivas (recordatorios y campañas) |
| `notifications` | Alertas por usuario (canje, resumen, recordatorio) |
| `device_tokens` | Tokens FCM por dispositivo |
| `refresh_tokens` | Hash, rotación y revocación |
| `audit_log` | Quién, qué, cuándo, `correlation_id` |
| `fraud_rules_config` | Parámetros de reglas antifraude (invisibles al comercio) |
| `fraud_flags` | Operaciones marcadas para revisión |
| `refund_requests` | Solicitud de reembolso (9.5.7): `purchase_id`, `establishment_id`, **`branch_id` y nombre de sucursal (copia)**, **`purchase_occurred_at`**, `requested_at`, `requested_by`, `invoice_ref` (de la compra), **`invoice_number`**, **`invoice_business_name`** (razón social), **`invoice_photo_id`**, `reason_code` (opcional), `amount_cents` y `points_to_reverse` (copias), `status`, `reviewed_by`, `reviewed_at`, `review_note`, `reversal_mode`, `points_reversed`, `unrecovered_points`, `reversal_ledger_id`, `idempotency_key` |
| `refund_attachments` | Foto de la factura: ruta en el volumen `uploads`, `sha256`, tipo, tamaño, `establishment_id`, `uploaded_by`. Sin URL pública |
| `system_settings` | Parámetros de negocio configurables (`refund_window_days`, `refund_request_ttl_days`, tamaño máximo de foto…): clave, valor, `updated_by`, `updated_at`; cada cambio va a `audit_log` |

Relaciones principales: `users 1—1 customers`; `users N—N establishments` vía `establishment_staff`; `establishments 1—N purchases`; `customers 1—N purchases`; `purchases 1—N points_ledger`; `rewards 1—N redemptions`.

### 9.6.4 Estrategia de acceso a datos
- Una transacción por caso de uso crítico, con contexto RLS fijado al inicio.
- **Registrar compra:** inserta `purchases` + `points_ledger`; el trigger actualiza `customer_balances`. La `Idempotency-Key` evita doble acreditación.
- **Canjear:** inserta en `points_ledger` un `REDEEM` con `delta` negativo. El trigger actualiza el saldo y el `CHECK (balance >= 0)` aborta la transacción si no alcanza (SQLSTATE `23514` → `INSUFFICIENT_POINTS`). El `UPDATE` del trigger toma el bloqueo de fila: no hay condición de carrera y **no se necesita `SELECT … FOR UPDATE`**. El stock se descuenta con la función `fn_reserve_reward_stock(reward_id)` (`SECURITY DEFINER`), porque el rol de la API no puede modificar recompensas ajenas.
- **Validar canje:** `UPDATE redemptions SET status='USED' WHERE code=$1 AND status='ISSUED' AND expires_at > now() RETURNING …`. Sin fila = ya usado, vencido o inexistente.
- **Aprobar reembolso:** una sola transacción que pasa `refund_requests` de `PENDING` a `APPROVED` (con `WHERE status='PENDING'`), inserta el `REVERSAL` en `points_ledger` con `reverses_ledger_id`, registra `points_reversed` / `unrecovered_points` y escribe auditoría y notificaciones (9.5.7). Un índice único sobre `reverses_ledger_id` impide revertir dos veces el mismo crédito.
- Índices en `(customer_id, created_at)`, `(establishment_id, created_at)`, `idempotency_key`, `(establishment_id, invoice_ref)` único parcial, `phone_e164` único.
- Estadísticas con consultas agregadas; no hay base analítica en el MVP.

### 9.6.5 Row Level Security (RLS)

**Qué protege:** que una consulta mal escrita o una ruta con un fallo de autorización no pueda leer o escribir filas de otro comercio u otro cliente. **Qué no protege:** código de la API comprometido que fije un contexto falso; por eso RLS complementa al middleware, no lo reemplaza.

**Roles de base de datos** (creados en `infra/db/init`, no en migraciones):

| Rol | Uso | Privilegios clave |
|-----|-----|-------------------|
| `postgres_admin` | Superusuario del contenedor, solo inicialización | Nunca lo usa la API |
| `paseo_owner` | Dueño de objetos; lo usa **Flyway** | `CREATE`, sin `SUPERUSER` |
| `paseo_app` | **Lo usa la API y el worker** | `NOSUPERUSER NOBYPASSRLS`, no es dueño; solo `GRANT` explícitos |
| `paseo_backup` | `pg_dump` | `BYPASSRLS` + `pg_read_all_data` |

> Los superusuarios y los dueños de tabla **saltan RLS**. Por eso la API nunca se conecta como superusuario ni como dueño. No se usa `FORCE ROW LEVEL SECURITY`, porque Flyway (dueño) debe poder migrar y sembrar; el aislamiento depende de que `paseo_app` no sea dueño.

**Contexto por transacción** (el pool de conexiones se reutiliza; por eso `is_local = true`, que limita el valor a la transacción):

```sql
BEGIN;
SELECT set_config('app.user_id',          $1, true),
       set_config('app.role',             $2, true),
       set_config('app.customer_id',      $3, true),
       set_config('app.establishment_id', $4, true),
       set_config('app.branch_id',        $5, true);
-- ... consultas del caso de uso ...
COMMIT;
```
Los valores salen de los **claims verificados del JWT** (9.8.1), nunca del cuerpo de la petición. Los flujos sin sesión (login, registro, recuperación) usan `app.role = 'system'`, que solo fijan los adaptadores de `Identity`.

**Funciones auxiliares y ejemplo de políticas:**

```sql
CREATE FUNCTION app.ctx_role() RETURNS text LANGUAGE sql STABLE
  AS $$ SELECT NULLIF(current_setting('app.role', true), '') $$;
CREATE FUNCTION app.ctx_user_id() RETURNS uuid LANGUAGE sql STABLE
  AS $$ SELECT NULLIF(current_setting('app.user_id', true), '')::uuid $$;
CREATE FUNCTION app.ctx_customer_id() RETURNS uuid LANGUAGE sql STABLE
  AS $$ SELECT NULLIF(current_setting('app.customer_id', true), '')::uuid $$;
CREATE FUNCTION app.ctx_establishment_id() RETURNS uuid LANGUAGE sql STABLE
  AS $$ SELECT NULLIF(current_setting('app.establishment_id', true), '')::uuid $$;
CREATE FUNCTION app.ctx_branch_id() RETURNS uuid LANGUAGE sql STABLE
  AS $$ SELECT NULLIF(current_setting('app.branch_id', true), '')::uuid $$;

ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;

CREATE POLICY purchases_customer_read ON purchases FOR SELECT
  USING (app.ctx_role() = 'customer' AND customer_id = app.ctx_customer_id());

CREATE POLICY purchases_owner_read ON purchases FOR SELECT
  USING (app.ctx_role() = 'merchant_owner'
         AND establishment_id = app.ctx_establishment_id());

CREATE POLICY purchases_cashier_read ON purchases FOR SELECT
  USING (app.ctx_role() = 'merchant_cashier'
         AND establishment_id = app.ctx_establishment_id()
         AND seller_user_id = app.ctx_user_id());

CREATE POLICY purchases_admin_read ON purchases FOR SELECT
  USING (app.ctx_role() = 'admin');

CREATE POLICY purchases_merchant_insert ON purchases FOR INSERT
  WITH CHECK (app.ctx_role() IN ('merchant_owner','merchant_cashier')
              AND establishment_id = app.ctx_establishment_id()
              AND seller_user_id   = app.ctx_user_id());
```

**Ledger y saldos:**
```sql
REVOKE UPDATE, DELETE, TRUNCATE ON points_ledger FROM paseo_app;
-- defensa adicional: trigger que lanza excepción ante UPDATE/DELETE
-- customer_balances: paseo_app solo tiene SELECT; lo actualiza el trigger
-- SECURITY DEFINER (ejecuta como paseo_owner, que no está sujeto a RLS al no usar FORCE)
```

**Matriz de acceso (resumen):**

| Tabla | customer | cashier | owner | admin |
|-------|----------|---------|-------|-------|
| `purchases` | las suyas (R) | las que registró (R/I) | su comercio (R/I) | todas (R) |
| `points_ledger` | el suyo (R) | inserta vía compra | su comercio (R) | todo (R) + `ADJUST`/`REVERSAL` |
| `customer_balances` | el suyo (R) | — | — | todos (R) |
| `rewards` | activas (R) | activas de su comercio (R) | su comercio (R/I/U propuesta) | todas (R/U) |
| `redemptions` | las suyas (R/I) | validar en su comercio (U) | su comercio (R) | todas (R) |
| `fraud_flags`, `fraud_rules_config` | — | — | — | (R/U) |
| `refund_requests` | — | las que solicitó (R/I); puede cancelar las suyas `PENDING` | las de su comercio (R/I; cancelar) | todas (R) y resolverlas (U) |
| `refund_attachments` | — | las que subió (R/I) | las de su comercio (R/I) | todas (R) |
| `system_settings` | — | — | — | (R/U); la API lee los valores como contexto `system` |

**Regla de proceso:** toda migración que cree una tabla incluye en el mismo archivo `ENABLE ROW LEVEL SECURITY`, sus políticas y sus `GRANT`. Una tabla sin RLS no se mergea. Hay pruebas de integración que, con el rol `paseo_app`, comprueban que un contexto de comercio A **no ve** filas del comercio B.

### 9.6.6 Migraciones con Flyway (versionado desde el inicio)

- **Herramienta:** Flyway Community en contenedor, **versión fija** `flyway/flyway:13.8.1`. Verificación: el listado de releases de GitHub marcaba 13.8.1 como última el 29/09/2026; la página de documentación de Redgate (actualizada el 01/10/2026) menciona 13.9.0. **Antes de iniciar, hacer `docker pull` y fijar la última que exista; no usar `latest`.**
- **Convención:** `V<NNN>__<descripcion_en_snake_case>.sql` (ej. `V001__baseline_extensions_schemas.sql`). Numeración correlativa, sin saltos.
- **Inmutabilidad:** una migración aplicada **no se edita jamás**; Flyway valida el checksum y falla si cambia. Cualquier corrección es una migración nueva. Solo avanzan (no hay *undo* en Community).
- **Se ejecutan antes de la API:** el servicio `migrate` corre y termina; `api` y `worker` arrancan solo cuando `migrate` terminó con éxito.
- **Configuración por variables de entorno** (`FLYWAY_URL`, `FLYWAY_USER`, `FLYWAY_PASSWORD`, `FLYWAY_LOCATIONS`, `FLYWAY_VALIDATE_MIGRATION_NAMING=true`, `FLYWAY_CLEAN_DISABLED=true`). Confirmar los nombres contra la documentación de la versión fijada.
- **Semillas** (datos de demo) solo en desarrollo, como migración repetible `R__seed_dev.sql` en un directorio aparte que únicamente el override de desarrollo monta. No se mezclan con las versionadas.
- **Orden inicial previsto:**

| Versión | Contenido |
|---------|-----------|
| V001 | Extensiones (`citext`, `pgcrypto`), esquema `app`, funciones de contexto |
| V002 | Identidad: `users`, `verification_codes`, `password_resets`, `refresh_tokens`, `customers` |
| V003 | Comercios: `establishments`, `branches`, `establishment_staff` |
| V004 | Conversión: `points_rules`, `special_dates` |
| V005 | Compras y ledger: `purchases`, `points_ledger`, `customer_balances`, triggers |
| V006 | Recompensas: `rewards`, `redemptions`, `promotions`, `fn_reserve_reward_stock` |
| V007 | Notificaciones: `notifications`, `device_tokens` |
| V008 | Reembolsos: `refund_requests`, índices únicos, políticas |
| V009 | Auditoría y antifraude: `audit_log`, `fraud_rules_config`, `fraud_flags` |
| V010 | Políticas RLS y `GRANT` finales (o repartidas por tabla, según la regla de 9.6.5) |

---

## 9.7 API y Comunicación entre Componentes

### 9.7.1 Arquitectura
REST, sin estado, prefijo `/api/v1`, contrato en `docs/openapi.yaml` (se escribe **antes** de implementar).

### 9.7.2 Endpoints (MVP "Must have")

| Método | Ruta | Rol | Nota |
|--------|------|-----|------|
| POST | `/auth/register` | público | correo + teléfono + contraseña |
| POST | `/auth/verify-email` | público | confirma correo |
| POST | `/auth/phone/send-otp` | autenticado | envía OTP al teléfono |
| POST | `/auth/phone/verify` | autenticado | confirma teléfono |
| POST | `/auth/login` | público | |
| POST | `/auth/refresh` | autenticado | |
| POST | `/auth/logout` | autenticado | |
| POST | `/auth/password/forgot` | público | siempre responde 202 |
| POST | `/auth/password/reset` | público | token de un solo uso |
| GET / PATCH | `/me` | cliente | |
| GET | `/me/qr-token` | cliente | solo si teléfono verificado |
| GET | `/me/balance` | cliente | |
| GET | `/me/movements` | cliente | |
| GET | `/rewards` | cliente | |
| POST | `/redemptions` | cliente | |
| POST | `/merchant/customers/identify` | comercio | `{method: QR\|PHONE, …}` |
| POST | `/merchant/purchases/preview` | comercio | calcula puntos sin guardar |
| POST | `/merchant/purchases` | comercio | `Idempotency-Key`; `invoice_ref` opcional |
| POST | `/merchant/redemptions/validate` | comercio | devuelve el beneficio a aplicar |
| POST | `/merchant/refund-requests` | comercio (cajero o dueño) | `multipart/form-data`: `purchase_id`, `invoice_number`, `invoice_business_name`, foto de la factura; sucursal y hora las pone el servidor; `Idempotency-Key` |
| GET | `/merchant/refund-requests/{id}/invoice-photo` | comercio | solo de su comercio |
| GET | `/merchant/refund-requests` | comercio | las propias (cajero) o todas las del comercio (dueño) |
| POST / PATCH | `/admin/establishments` | admin | |
| PUT | `/admin/points-rules` | admin | crea nueva versión |
| POST / PATCH | `/admin/rewards` | admin | |
| GET | `/admin/refund-requests` | admin | filtros por estado, comercio, sucursal, fecha |
| GET | `/admin/refund-requests/{id}` | admin | detalle con factura, sucursal, hora, saldo actual del cliente y faltante estimado |
| POST | `/admin/refund-requests/{id}/approve` | admin | `{reversal_mode: FULL\|PARTIAL}`; `Idempotency-Key` |
| POST | `/admin/refund-requests/{id}/reject` | admin | `{review_note}` obligatoria |
| GET | `/admin/refund-requests/{id}/invoice-photo` | admin | descarga auditada |
| GET / PUT | `/admin/settings` | admin | parámetros configurables (ventana de reembolso, vencimiento…) |

**"Should have":** `/merchant/stats/summary`, `/merchant/staff`, `/merchant/branches`, `POST /merchant/refund-requests/{id}/cancel`, `/merchant/rewards` (propuestas), `/admin/approvals` (recompensas y promociones), `/merchant/movements`, `/promotions`, `/establishments`, `/admin/users`, `/admin/stats`, `/admin/fraud-flags`, notificaciones (`/me/notifications`, registro de token FCM).

**Identificación en caja.** `identify` recibe `QR` (token firmado) o `PHONE` (número completo, normalizado a E.164) y devuelve un **ticket de identificación** firmado, ligado al comercio y válido ~5 min, más el nombre **enmascarado** (ej. "Carlos M."). `purchases` recibe el ticket, **no** el teléfono ni el ID. Así el dato personal viaja una sola vez.

### 9.7.3 Métodos HTTP
`GET` lectura, `POST` creación/acciones, `PUT` reemplazo de configuración, `PATCH` parcial. Compra y canje: `POST` con `Idempotency-Key`.

### 9.7.4 Formato
JSON UTF-8, fechas ISO 8601 UTC, montos en centavos, paginación por cursor.

### 9.7.5 Errores
**RFC 9457 (`application/problem+json`)** con `type`, `title`, `status`, `detail` y `code` estable (`INSUFFICIENT_POINTS`, `REDEMPTION_ALREADY_USED`, `PHONE_NOT_VERIFIED`, `NO_APPLICABLE_RULE`, `DUPLICATE_INVOICE`, `CUSTOMER_NOT_FOUND`, `OTP_INVALID`, `OTP_RATE_LIMITED`, `REFUND_ALREADY_REQUESTED`, `PURCHASE_ALREADY_REFUNDED`, `REFUND_WINDOW_EXPIRED`, `REFUND_ALREADY_RESOLVED`, `INSUFFICIENT_POINTS_FOR_REVERSAL`, `PHONE_NOT_SUPPORTED`, `INVALID_ATTACHMENT`, `ATTACHMENT_TOO_LARGE`).

| Situación | HTTP |
|-----------|------|
| Validación | 422 |
| No autenticado / token vencido | 401 |
| Sin permiso por rol | 403 |
| No existe | 404 |
| Conflicto (correo/teléfono duplicado, canje usado, factura repetida) | 409 |
| Reintento con misma `Idempotency-Key` | 200 con la respuesta original |
| Límite de peticiones / OTP | 429 |

### 9.7.6 Notificaciones (requisito de la encuesta)
| Alerta | Demanda (de 15) | Mecanismo | Prioridad |
|--------|-----------------|-----------|-----------|
| Cliente canjeó un cupón en mi comercio | 8 | Push FCM + lista en la app | **Should** (antes "Could") |
| Resumen diario/semanal de ventas ligadas a la app | 8 | `worker` programado → notificación en la app y correo | **Should** |
| Recordatorio de fechas festivas | 4 | `special_dates` + `worker` | Could |
| Nueva solicitud de reembolso (al administrador) y su resolución (al solicitante) | — (requisito del equipo) | Notificación en la app; push si FCM está activo | Should |
| Reversión de puntos (al cliente) | — | Movimiento en el historial + notificación | Should |

---

## 9.8 Seguridad

### 9.8.1 Autenticación y claims JWT
Access token de **15 minutos**; refresh de 7 a 30 días con **rotación** y detección de reutilización. Firma con secreto fuerte desde variable de entorno (con `kid` para poder rotar).

**Claims del access token:**

| Claim | Contenido | Uso |
|-------|-----------|-----|
| `iss` | Emisor fijo | Validado siempre |
| `aud` | Una audiencia por aplicación: `paseo-mobile`, `paseo-web-merchant`, `paseo-web-admin` | Validada siempre. `paseo-web-admin` solo se emite y acepta para `role=admin`; los tokens de comercio y cliente no se aceptan en endpoints de administración |
| `sub` | `user_id` (UUID) | `app.user_id` |
| `iat`, `exp` | Emisión y expiración (≤ 15 min) | |
| `jti` | Id único del token | Trazabilidad y revocación puntual |
| `role` | `customer`, `merchant_owner`, `merchant_cashier`, `admin` | `app.role` |
| `cid` | `customer_id` (solo cliente) | `app.customer_id` |
| `est` | `establishment_id` (solo comercio) | `app.establishment_id` |
| `br` | `branch_id` (solo `merchant_cashier`; ausente para el dueño) | `app.branch_id` |
| `pv` | Teléfono verificado (bool) | Bloquea QR y acumulación si es `false` |
| `ev` | Correo verificado (bool) | |
| `tv` | `token_version` del usuario | Invalida tokens al cambiar contraseña o suspender |

**Reglas:**
1. **Sin datos personales en claims** (nada de correo, teléfono ni nombre): el JWT está firmado, no cifrado.
2. **PostgreSQL no lee el JWT.** El middleware de la API lo valida y copia los claims al contexto de transacción (9.6.5). RLS confía en esa copia, no en el cuerpo de la petición.
3. **Los claims pueden quedar desactualizados hasta 15 minutos.** Para acciones sensibles (cambios de configuración, suspensión, anulaciones de admin) se **consulta `users.status` y `token_version` en la base**, no solo los claims.
4. `est`, `br` y `role` provienen de `establishment_staff` al emitir el token; un usuario con varios comercios elige uno al iniciar sesión. Una compra toma su `branch_id` del claim `br` (cajero) o de la sucursal que el dueño elija; nunca de un valor libre del cliente sin validar contra `branches`.

### 9.8.2 Autorización
RBAC en middleware **y** RLS en base de datos. Un comercio solo opera sobre su `establishment_id`. Permisos de comercio:

| Acción | Cajero | Dueño |
|--------|--------|-------|
| Identificar, previsualizar, registrar compra, validar canje | ✅ | ✅ |
| Ver sus propias operaciones | ✅ | ✅ |
| Ver todo el comercio y el dashboard | — | ✅ |
| Gestionar personal | — | ✅ |
| Proponer recompensas (la conversión la fija solo el administrador) | — | ✅ |
| Solicitar reembolso | ✅ solo de compras que registró | ✅ de cualquiera de su comercio |
| **Aprobar o rechazar** un reembolso | ❌ | ❌ (solo `admin`) |
| Modificar puntos manualmente, borrar o editar historial | ❌ | ❌ |
| Aprobar sus propias alertas | ❌ | ❌ |

### 9.8.3 Gestión de tokens
- Móvil: `flutter_secure_storage`, nunca `SharedPreferences`.
- Web (comercio y administración): access token **solo en memoria**; refresh token en cookie `HttpOnly; Secure; SameSite=Strict`, `Path=/api/v1/auth`, con nombre propio por aplicación (`__Secure-rt_merchant`, `__Secure-rt_admin`). `POST /auth/refresh` exige una cabecera personalizada (`X-Paseo-Client`) y valida `Origin`, como defensa contra CSRF. **Las cookies no se aíslan por puerto**: por eso el nombre de la cookie y la audiencia `aud` son propios de cada aplicación (9.12.1).
- Servidor: refresh tokens como **hash**, revocables.

### 9.8.4 Contraseñas
**Argon2id** (decisión del equipo), guardado en formato PHC (`$argon2id$v=19$m=…,t=…,p=…$sal$hash`). Parámetros iniciales: como mínimo los de OWASP (19 MiB de memoria, 2 iteraciones, paralelismo 1; verificar la guía vigente), ajustados tras **medir el tiempo por hash en el servidor real**. Librería: candidata `serverpod_argon2` (nativa, PHC, parámetros OWASP por defecto, pero versión 0.1.0) y alternativa `hashlib` (Dart puro); ver 9.15.5. El hash se calcula fuera del hilo principal (`Isolate`) para no bloquear la API. La contraseña nunca va a logs.

### 9.8.5 Protección de datos
- HTTPS obligatorio (Caddy).
- **QR firmado y rotativo:** token de ~60 s solicitado a `/me/qr-token` y renovado. No contiene el ID en claro. (Opcional Should: registrar el `jti` usado para que no se reutilice dentro de esos 60 s.)
- **Código de canje:** aleatorio, un solo uso, con vencimiento.
- **Privacidad mínima (RNF-11):** el comercio ve solo nombre enmascarado. No hay búsqueda parcial por teléfono.
- Límite de peticiones en login, OTP, `identify` y endpoints de comercio.
- Auditoría de compras, canjes y cambios de configuración.
- Secretos en variables de entorno; `.env` fuera del control de versiones.

### 9.8.6 Verificación de identidad: teléfono + correo

**Principio:** dos canales, dos funciones distintas.

| Canal | Función | Si no está verificado |
|-------|---------|-----------------------|
| **Correo** | Verificar la cuenta y **recuperarla** (restablecer contraseña) | No se puede recuperar la cuenta |
| **Teléfono** | **Identificar al cliente en caja** (el cliente lo dicta) y recibir puntos | `pv=false`: no genera QR ni puede ser identificado por teléfono |

**Registro:** correo + teléfono boliviano + contraseña. **Mínimo obligatorio: verificar el teléfono con un código SMS**; sin eso la cuenta existe pero no acumula puntos ni genera QR. El correo también se verifica con un código, pero **solo habilita la recuperación de cuenta**: una cuenta con correo sin verificar puede operar, y se le advierte que no podrá recuperarla.

> *Interpretación de la decisión "SMS del teléfono como mínimo o también con email": SMS obligatorio y correo adicional. Si el equipo prefiere exigir ambos para acumular puntos, el cambio es que la condición pase de `pv` a `pv && ev`.*

**Códigos OTP:** 6 dígitos, guardados como hash, vigencia de 5 min, máximo 5 intentos, reenvío con espera de 60 s y tope diario por teléfono y por IP.

**Solo teléfonos bolivianos (decisión del equipo):** se acepta únicamente `+591`; el móvil tiene 8 dígitos y empieza con 6 o 7 (verificar contra el plan de numeración vigente antes de fijar la expresión regular). Cualquier otro prefijo se rechaza con `PHONE_NOT_SUPPORTED`.

**Recuperación por correo:** `forgot` siempre responde 202 (no revela si el correo existe); el token es aleatorio (≥ 32 bytes), se guarda hasheado, vence en 30 min y es de un solo uso; al restablecer se incrementa `token_version` y se revocan los refresh tokens.

**Cambio de teléfono:** exige reverificación del nuevo número y confirmación por correo; se audita.

**Identificación dictando el teléfono — riesgos y controles** (esta es la parte más débil del diseño y conviene decirlo ante el jurado):
- Quien conozca un número puede intentar acreditarlo. El daño directo es bajo (los puntos van a otra persona), pero un comercio puede **acreditar puntos falsos a un cómplice**. Control: reglas antifraude (9.8.7) + el cliente ve cada crédito en su historial y recibe notificación.
- Se puede **enumerar** qué teléfonos están registrados. Control: número completo exacto, límite de peticiones por comercio, respuesta con nombre enmascarado, auditoría de cada consulta.
- **Should:** confirmación del cliente en su app (push "¿Reconoces esta compra de Bs X en Tienda Y?") antes de acreditar o dentro de un plazo para revertir.
- El **CI no se usa** como identificador: es un dato sensible que el teléfono verificado hace innecesario.

**Costo y dependencia:** el SMS tiene costo por mensaje y requiere un proveedor, **aún no elegido**. Hay referencias de costo, de fuentes de terceros y por confirmar con el proveedor, en 9.15.6 (orden de magnitud: centavos de dólar por SMS; un servicio administrado como Twilio Verify añade 0,05 USD por verificación). Por eso el SMS se envía **solo al registrarse y al cambiar de teléfono**, no en cada inicio de sesión, y el OTP lo gestiona la propia API. Todo queda tras el puerto `OtpSender`: en desarrollo y demo un adaptador de consola registra el código; el adaptador real se elige sin tocar el dominio. Para el correo, desarrollo usa Mailpit (ver `INFRASTRUCTURE.md`).

### 9.8.7 Antifraude para el MVP
Se adopta una versión **reducida** de la propuesta de control de fraude, por tres razones: ningún comercio la pidió en la encuesta, el detector estadístico necesita historial que no existirá en la demo, y el tiempo es limitado.

Reglas fijas (parámetros en `fraud_rules_config`, nunca visibles para el comercio) que escriben en `fraud_flags`:
1. **Velocidad:** más de N compras del mismo cliente con el mismo comercio en una ventana corta.
2. **Monto:** compra por encima de `establishments.max_purchase_cents`.
3. **Factura repetida:** `DUPLICATE_INVOICE` (rechazo duro, no flag).
4. **Concentración:** proporción alta de puntos de un comercio hacia un solo teléfono.
5. **Reembolsos:** tasa de solicitudes por vendedor o comercio por encima de un umbral, o solicitudes sobre compras muy recientes del mismo cliente repetidas en un patrón.

El administrador revisa las marcas y puede marcar como válida o sospechosa. Estados del comercio/vendedor: `ACTIVE → OBSERVED → POINTS_SUSPENDED → BLOCKED`, con auditoría. **Una anulación es siempre un movimiento `REVERSAL` en el ledger**, nunca una edición ni un borrado. Un motor de riesgo con puntajes queda como evolución futura.

> **Sobre el ranking de vendedores:** 4/15 lo pidieron. Un ranking por "puntos asignados" **incentiva inflar puntos**. Se implementa como **actividad por vendedor** (operaciones, monto vendido, puntos y relación puntos/monto), no como competencia.

---

## 9.9 Control de Versiones y Gestión del Código/Dependencias

- **Git + GitHub**, monorepo. `main` protegida; ramas `feat/<id-historia>-descripcion`; PR con revisión de al menos otra persona.
- **Commits:** Conventional Commits referenciando la HU.
- **Specs** versionadas en `specs/`. Ningún cambio de comportamiento sin spec y sin prueba.
- **Migraciones:** una migración Flyway por PR cuando cambia el esquema; CI **levanta PostgreSQL, aplica todas las migraciones desde cero y ejecuta las pruebas de RLS**. Se rechaza el PR si se modifica un archivo de migración ya existente en `main`.
- **Dependencias:** `pubspec.lock` versionado, Flutter fijado con FVM, `dart pub outdated` en revisiones.
- **CI (GitHub Actions):** `dart format --set-exit-if-changed`, `dart analyze`, pruebas, validación de `openapi.yaml`, verificación de la regla de dependencias hexagonal, migraciones + RLS, build de APK y de web.
- **Hooks locales:** formato y análisis antes del commit.

---

## 9.10 Entorno y Herramientas de Desarrollo

### 9.10.1 Herramientas

| Herramienta | Uso | Control de versión |
|-------------|-----|--------------------|
| **Git + GitHub** | Código, PR, CI | — |
| **Docker + Docker Compose** | Base de datos, Flyway, API, Caddy, Mailpit | Etiquetas fijas en `docker-compose.yml` |
| **FVM + Flutter (estable)** | App móvil y los dos builds web; incluye el SDK de Dart | `.fvmrc` |
| **Dart SDK** (el que trae Flutter) | Backend Dart Frog, worker y `paseo_shared` | Mismo SDK que Flutter, para evitar desfases |
| **IDE:** VS Code o Android Studio | Desarrollo | Extensiones de Dart/Flutter |
| **Android SDK / emulador** y un celular real | Pruebas del móvil y del escaneo de QR | — |
| **Chrome** | Depuración de los builds web | — |
| **Cliente SQL** (`psql` u otro) | Inspeccionar la base **local** | — |
| **Mailpit** (contenedor, solo `dev`) | Captura de correos de prueba | Etiqueta fija |
| **Flyway** (contenedor) | Migraciones | Etiqueta fija (ver 9.6.6) |
| **Spec Kit + plugins de agentes** | SDD y asistencia de IA | Ver Anexo B |

> No se instala PostgreSQL ni Flyway en la máquina del desarrollador: todo corre en contenedores, para que **todos tengan el mismo entorno** (C8).

### 9.10.2 Puertos locales

| Servicio | Puerto local | Publicación |
|----------|--------------|-------------|
| API | 8080 | `127.0.0.1` solo en dev |
| Web comercio (`flutter run -d chrome`) | 8081 | local |
| Web administración (`flutter run -d chrome`) | 8082 | local |
| PostgreSQL | 5432 | `127.0.0.1` solo en dev |
| Mailpit (interfaz / SMTP) | 8025 / 1025 | `127.0.0.1` |

En el servidor, el comercio sale por **443** y la administración por **8443** (9.12.1).

### 9.10.3 Puesta en marcha (onboarding)

```bash
git clone <repo> && cd paseo-points
cp infra/.env.example infra/.env            # completar secretos de desarrollo
fvm install && fvm flutter pub get          # fija y descarga la versión de Flutter
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d
# db → migrate (Flyway, V001…) → api → worker → mailpit

# Aplicaciones Flutter (tres puntos de entrada, un solo código)
cd apps/mobile
fvm flutter run                                                              # móvil: cliente y comercio
fvm flutter run -d chrome --web-port 8081 -t lib/main_merchant_web.dart      # web comercio
fvm flutter run -d chrome --web-port 8082 -t lib/main_admin_web.dart         # web administración
```

Objetivo: **de un clon limpio a una demo local en menos de 30 minutos**, con datos semilla y sin pasos manuales no escritos. Si el onboarding requiere un paso que no está en este documento o en `INFRASTRUCTURE.md`, es un defecto de la documentación.

### 9.10.4 Datos semilla de desarrollo (`infra/seed/R__seed_dev.sql`)
Un administrador; un comercio con **dos sucursales**, un dueño y dos cajeros (uno por sucursal); tres clientes con teléfonos ficticios `+591` válidos en formato; una regla `GLOBAL` y una de campaña; una recompensa de cada tipo (`PERCENT`, `FIXED`, `GIFT`); fechas especiales; y al menos una compra con su reembolso en estado `PENDING`. En desarrollo el OTP sale por consola (`OTP_SENDER=console`) y los correos llegan a Mailpit.

### 9.10.5 Calidad local
- `dart format`, `dart analyze` (reglas estrictas) y pruebas rápidas del dominio antes de cada commit (hook local).
- Estructura de `analysis_options.yaml` única para todo el monorepo; se añade una comprobación de la regla de dependencias hexagonal (9.2).
- `pubspec.lock` versionado; `dart pub outdated` en las revisiones.

### 9.10.6 Entorno para agentes de IA
Las reglas están en `AGENTS.md` (qué se puede y qué no) e `INFRASTRUCTURE.md` (dónde está cada cosa). El agente trabaja contra la base **local**, con el rol `paseo_app` o uno de solo lectura, nunca con el superusuario. Ver Anexo B.

---

## 9.11 Estrategia de Pruebas

### Enfoque
Pirámide con más peso en lo que protege el dinero y los puntos: dominio y base de datos. La regla del proyecto: **todo criterio de aceptación de una HU se convierte en una prueba**, y las pruebas las escribe o revisa alguien distinto de quien implementó.

| Nivel | Qué verifica | Herramienta | Dónde corre |
|-------|--------------|-------------|-------------|
| Unitarias | Reglas del dominio y casos de uso con dobles | `test`, `mocktail` | Local y CI |
| Integración | SQL real, RLS, triggers, transacciones, concurrencia | `test` contra PostgreSQL real | CI (contenedor) |
| API | Contrato OpenAPI, roles, errores, subida de archivos | `test` + cliente HTTP contra la API levantada | CI |
| Frontend | Lógica de estado, guardas por rol, flujos críticos | `flutter_test`, `integration_test` | Local y CI |
| Aceptación | Flujo completo de la demo | Guion manual + automatización parcial | Antes de la entrega |

### 9.11.1 Pruebas Unitarias

**Dominio (sin base de datos, sin red).** Casos por tabla:

| Caso | Regla | Entrada | Esperado |
|------|-------|---------|----------|
| Redondeo hacia abajo | 1 punto por Bs 10, `FLOOR` | Bs 25 | 2 |
| Bajo el tramo | 1 punto por Bs 10, `FLOOR` | Bs 9,99 | 0 |
| Tramo exacto | 1 punto por Bs 10, `FLOOR` | Bs 10 | 1 |
| Redondeo ordinario | 1 punto por Bs 10, `ROUND` | Bs 25 | 3 |
| Redondeo hacia arriba | 1 punto por Bs 10, `CEIL` | Bs 10,01 | 2 |
| Campaña ×2 | 1 punto por Bs 5, `FLOOR`, ×2 | Bs 23 | 8 (4 base × 2) |
| Campaña ×1,5 | 1 punto por Bs 10, `FLOOR`, ×1,5 | Bs 25 | 3 (2 base × 1,5) |
| Tope | Base 25, tope 20 | — | 20 |
| Compra mínima | Mínimo Bs 20 | Bs 19,99 | 0 |
| **Sobre monto neto** | 1 punto por Bs 10, `FLOOR` | Bs 100 con descuento de Bs 20 | 8 (sobre Bs 80) |
| Sin regla | — | cualquiera | `NO_APPLICABLE_RULE` |

Otras unidades del dominio:
- `RuleResolver`: precedencia `ESTABLISHMENT > CATEGORY > GLOBAL`, desempate por `priority`, una sola campaña, vigencia por fechas.
- `Phone`: **solo números bolivianos** (`+591`), normalización y rechazo de formatos no válidos.
- `Money` y `Points`: sin `float`; desbordes y signos.
- Reglas antifraude: velocidad, monto, concentración, tasa de reembolsos (con umbrales inyectados).
- Reembolso: transiciones de estado permitidas e inválidas (`PENDING → APPROVED/REJECTED/CANCELLED/EXPIRED`; ninguna sale de un estado final).
- Casos de uso con puertos simulados (`mocktail`): `RegistrarCompra`, `SolicitarReembolso`, `ResolverReembolso`, `IdentificarCliente`, `VerificarTelefono`, `RecuperarCuenta`.

**Flutter (lógica sin interfaz):** notifiers de Riverpod (autenticación, saldo, caja del comercio), mapeo de errores `problem+json` a excepciones tipadas, validación de formularios (teléfono boliviano, número de factura).

### 9.11.2 Pruebas de Integración
Contra **PostgreSQL 18 real**, creado desde cero con **Flyway** en cada ejecución de CI (esto verifica a la vez las migraciones y su orden). Todas las pruebas se conectan con el rol **`paseo_app`**, nunca con el superusuario.

| Área | Prueba | Resultado esperado |
|------|--------|--------------------|
| RLS | Contexto del comercio A consulta compras, reembolsos y fotos del comercio B | 0 filas |
| RLS | Cajero consulta compras de otro cajero | 0 filas |
| RLS | Cajero de la sucursal 1 registra compra en la sucursal 2 | Rechazado |
| RLS | Cliente consulta el ledger de otro cliente | 0 filas |
| Ledger | `UPDATE` / `DELETE` sobre `points_ledger` con `paseo_app` | Error de permisos |
| Saldo | Insertar crédito y débito | `customer_balances` coincide con la suma del ledger |
| Saldo | Débito mayor al saldo | Falla con `23514` → `INSUFFICIENT_POINTS` |
| Idempotencia | Dos compras simultáneas con la misma `Idempotency-Key` | Una compra, un crédito |
| Canje | Dos canjes simultáneos con saldo para uno | Uno exitoso, uno `INSUFFICIENT_POINTS` |
| Validación de canje | Dos validaciones del mismo código | Una exitosa, otra `REDEMPTION_ALREADY_USED` |
| Factura | Misma `(establecimiento, invoice_ref)` dos veces | `DUPLICATE_INVOICE` |
| Reembolso | Dos solicitudes `PENDING` de la misma compra | Segunda rechazada |
| Reembolso | Dos administradores aprueban a la vez | Un solo `REVERSAL`, la otra recibe `REFUND_ALREADY_RESOLVED` |
| Reembolso | Saldo insuficiente, modo `FULL` | `INSUFFICIENT_POINTS_FOR_REVERSAL`, sin cambios |
| Reembolso | Saldo insuficiente, modo `PARTIAL` | Reversión hasta el saldo y `unrecovered_points` registrado |
| Reembolso | Compra fuera de la ventana configurada | `REFUND_WINDOW_EXPIRED` |
| Reembolso | Sucursal y hora de la solicitud vs. los de la compra | Iguales, aunque el cliente HTTP envíe otros valores |
| Identidad | OTP: 6.º intento, reenvío antes de 60 s, tope diario | Bloqueado, `OTP_RATE_LIMITED` |
| Identidad | Token de recuperación usado dos veces o vencido | Rechazado |
| Identidad | Restablecer contraseña | `token_version` aumenta y los refresh tokens quedan revocados |
| Configuración | Cambiar `system_settings` | Aplica a solicitudes nuevas y queda en `audit_log` |
| Migraciones | Aplicar todas desde cero; modificar un archivo ya aplicado | Aplican; el checksum falla |
| Respaldo | Restaurar un `pg_dump` en una base vacía | Existen tablas, políticas RLS, triggers y roles |

### 9.11.3 Pruebas de API
- **Contrato:** cada endpoint de `openapi.yaml` se invoca y la respuesta se valida contra su esquema. Un endpoint que no está en el contrato falla en CI.
- **Matriz de autorización (rol × endpoint):** `customer`, `merchant_cashier`, `merchant_owner`, `admin` y sin sesión; cada celda espera 2xx, 401 o 403. Se genera a partir del contrato para que no se olvide ningún endpoint nuevo.
- **Errores:** todo error es `application/problem+json` con `code` estable.
- **Idempotencia:** mismo `Idempotency-Key` devuelve 200 con la respuesta original.
- **Límite de peticiones:** 429 en login, OTP, `identify` y endpoints de comercio.
- **Audiencias y claims:** un token de la web de administración no sirve en endpoints de comercio y viceversa; los claims no contienen datos personales.
- **Subida de factura (reembolsos):** formato permitido, tamaño máximo, archivo con extensión falsa (verificación por contenido, no por nombre), foto ausente, y descarga solo por administrador o por el comercio dueño de la solicitud.
- **Cookie de refresh en web:** `HttpOnly`, `Secure`, `SameSite=Strict`, nombre propio por aplicación, y rechazo si falta la cabecera de comprobación.
- **Opcional:** pruebas basadas en propiedades generadas desde el OpenAPI con una herramienta como Schemathesis (no verificada en este proyecto; evaluar si el tiempo lo permite).

### 9.11.4 Pruebas de Frontend
- **Widgets:** pantalla de caja (identificar → monto → vista previa → confirmar), solicitud de reembolso (campos y foto), lista de solicitudes del administrador.
- **Guardas por rol:** cada build web solo expone sus rutas; el build de administración no contiene pantallas de caja y el de comercio no contiene pantallas de administración (verificado en CI inspeccionando las rutas registradas).
- **Responsivo:** 360 px (celular) y 1366 px (computadora).
- **Flujos críticos en emulador (`integration_test`):** registro con OTP por consola, QR del cliente, compra, canje.
- **Manual (no automatizable de forma fiable):** lectura del QR con webcam en el build web; cámara para fotografiar la factura; comportamiento con conexión lenta.
- **Medición del requisito de la encuesta:** el flujo de caja se cronometra con 3 personas que no lo conocen; objetivo de diseño propio: **identificar y registrar en ≤ 3 interacciones** (la encuesta indica que 10 de 15 aceptan 10–30 s y 4 de 15 piden menos de 10 s).

### 9.11.5 Criterios de Aceptación

> Los umbrales numéricos son **propuestas del autor** para que el equipo las ratifique; no provienen de la encuesta ni de un estándar.

| Área | Criterio | Verificación |
|------|----------|--------------|
| Dominio | Cobertura de líneas ≥ 90 % en `domain/` | CI |
| Integridad | Ninguna prueba de ledger, saldo o idempotencia falla; el saldo nunca es negativo | CI |
| Aislamiento | Todas las pruebas RLS pasan con `paseo_app`; una tabla sin RLS bloquea el PR | CI |
| Contrato | 100 % de los endpoints en `openapi.yaml` y validados | CI |
| Seguridad | Contraseñas almacenadas con formato `$argon2id$`; sin secretos en el repositorio; sin PII en claims ni logs | CI + revisión |
| Rendimiento | p95 de `identify` + `purchases` < 500 ms en servidor, con datos semilla | Medición local |
| Usabilidad | Flujo de caja en ≤ 3 interacciones | Prueba con usuarios |
| Migraciones | Aplican desde cero; una migración modificada rompe la CI | CI |
| Recuperación | Restauración de respaldo probada al menos una vez | Manual documentado |

**Escenarios de aceptación mínimos (Dado/Cuando/Entonces):**

1. *Registro:* **dado** un número boliviano válido y un correo, **cuando** el usuario ingresa el código SMS, **entonces** `pv=true` y puede generar su QR; sin ese código no acumula puntos.
2. *Conversión:* **dado** "1 punto por Bs 10" con redondeo hacia abajo, **cuando** el cajero registra Bs 25, **entonces** el cliente recibe 2 puntos y la compra guarda la regla y su copia de parámetros.
3. *Descuento:* **dado** un descuento canjeado de Bs 20 sobre una compra de Bs 100, **cuando** se registra, **entonces** los puntos se calculan sobre Bs 80.
4. *Reembolso:* **dado** una compra con puntos acreditados, **cuando** un cajero solicita el reembolso con **foto de la factura, número y razón social**, **entonces** la solicitud queda `PENDING` con la **sucursal y la hora de la compra** copiadas por el servidor; al aprobar el administrador se inserta **un** `REVERSAL` y el cliente lo ve en su historial.
5. *Saldo insuficiente:* **dado** que el cliente ya gastó parte de los puntos, **cuando** el administrador aprueba en modo `PARTIAL`, **entonces** se revierte hasta el saldo disponible y queda registrado el faltante.
6. *Aislamiento:* **dado** un cajero de la sucursal A, **cuando** consulta o intenta registrar en la sucursal B, **entonces** no ve ni puede operar.

---

## 9.12 Despliegue e Infraestructura

Base: `INFRASTRUCTURE.md`, confirmado por el equipo como fuente de esta sección. Principio: reproducible con un comando; sin Kubernetes ni microservicios.

> **Destino de la demo:** el equipo aún no confirmó dónde se despliega. La recomendación de este documento es **un VPS con Docker Compose** (9.15.7); todo lo que sigue funciona igual en una máquina local para la demo si no hay servidor.

### 9.12.1 Despliegue del Frontend

**Tres artefactos del mismo código** (`apps/mobile`), con puntos de entrada distintos:

| Artefacto | Entrada | Salida | Quién lo usa | Dónde se sirve |
|-----------|---------|--------|--------------|----------------|
| Móvil | `lib/main.dart` | APK / AAB | Cliente y comercio (celular) | Distribución directa del APK para la demo |
| Web comercio | `lib/main_merchant_web.dart` | `build/web-merchant` | Dueño y cajero (computadora) | **Puerto 443** |
| Web administración | `lib/main_admin_web.dart` | `build/web-admin` | Administrador | **Puerto 8443** |

```bash
cd apps/mobile
fvm flutter build web -t lib/main_merchant_web.dart && mv build/web build/web-merchant
fvm flutter build web -t lib/main_admin_web.dart    && mv build/web build/web-admin
fvm flutter build apk
```

**Caddy** sirve los dos builds en puertos distintos. Esqueleto (validar con `caddy validate` antes de usar; el comportamiento del HTTPS automático en puertos no estándar debe comprobarse en el servidor real):

```
{$PUBLIC_HOST} {
    encode zstd gzip
    handle /api/* { reverse_proxy api:8080 }
    handle {
        root * /srv/web-merchant
        try_files {path} /index.html
        file_server
    }
}

{$PUBLIC_HOST}:8443 {
    encode zstd gzip
    handle /api/* { reverse_proxy api:8080 }
    handle {
        root * /srv/web-admin
        try_files {path} /index.html
        file_server
    }
}
```

**Aislamiento entre los dos puertos.** El navegador separa el almacenamiento y el origen por puerto, pero **las cookies no se separan por puerto**: una cookie de `host:443` también viaja a `host:8443`. Controles obligatorios:
- Nombre de cookie propio por aplicación (`__Secure-rt_merchant`, `__Secure-rt_admin`).
- El claim `aud` distingue las aplicaciones, y la API rechaza un token de una audiencia en la otra (y exige `role=admin` para la de administración).
- Orígenes CORS explícitos y distintos (`WEB_MERCHANT_ORIGIN`, `WEB_ADMIN_ORIGIN`).
- Recomendado: restringir el puerto 8443 por IP en el firewall del VPS.

**Móvil:** el APK se distribuye directamente para la demo. Publicar en tiendas, y el despliegue para iOS (que exige entorno de Apple), **no se cubren** en este documento y no se han verificado sus requisitos ni costos.

### 9.12.2 Despliegue del Backend
- **Imagen:** Dockerfile multi-stage de Dart que compila a ejecutable nativo; usuario no root, sistema de archivos de solo lectura, `GET /health` y `/ready`.
- **Procesos:** `api` y `worker` desde la misma imagen (distinto comando).
- **Orden de arranque:** `db` (healthy) → `migrate` (completado) → `api`/`worker` → `caddy`.
- **Archivos subidos (facturas):** volumen `uploads`, **nunca expuesto por Caddy**; solo se entregan a través de la API tras comprobar permisos. Incluido en los respaldos.
- **Publicación:** etiqueta de versión → CI construye y publica la imagen → en el servidor `docker compose pull && up -d`.
- **Reversión:** se vuelve a la etiqueta anterior de la imagen. Las migraciones **solo avanzan**, por lo que cada migración debe ser compatible con la versión anterior de la API durante un despliegue (añadir antes de quitar); un error de esquema se corrige con una migración nueva, no revirtiendo.
- **Tiempo de inactividad:** un reinicio breve de la API es aceptable para el MVP; no se propone despliegue sin interrupciones.

### 9.12.3 Despliegue de la Base de Datos
- **PostgreSQL 18** en contenedor con volumen persistente, **sin puerto público**.
- **Roles:** `postgres_admin` (solo init), `paseo_owner` (Flyway), `paseo_app` (API y worker, sin `BYPASSRLS`), `paseo_backup` (`BYPASSRLS`).
- **Flyway** aplica `V###` antes de la API; semillas solo en desarrollo.
- **Respaldos:** `pg_dump` diario comprimido, retención de varios días y copia fuera del servidor, **más el volumen `uploads`**. Con un respaldo diario, la pérdida máxima de datos es de hasta 24 h (RPO); si el equipo necesita menos, debe aumentar la frecuencia o añadir archivado de WAL, que **no** está en el alcance del MVP.
- **Restauración probada** al menos una vez, comprobando RLS, triggers y roles (los roles se recrean con el script de init, porque `pg_dump` no los incluye).

### 9.12.4 Gestión de Variables de Entorno

**Dónde vive cada tipo de dato:**

| Tipo | Ejemplos | Dónde | Cambia |
|------|----------|-------|--------|
| Secretos | Contraseñas de roles, `JWT_SECRET`, credenciales SMTP/SMS/FCM | `.env` (fuera del repo) | Con reinicio y rotación |
| Configuración de infraestructura | Host, puertos, `PUBLIC_HOST`, `UPLOADS_DIR`, orígenes CORS | `.env` | Con reinicio |
| **Parámetros de negocio** | Ventana de reembolso, vencimiento de solicitudes, umbrales antifraude, reglas de conversión | **Base de datos** (`system_settings`, `points_rules`, `fraud_rules_config`) con auditoría | **En caliente, por el administrador** |

Reglas:
1. `.env` nunca se versiona; `infra/.env.example` sí, con valores ficticios.
2. En el servidor, `.env` con permisos restringidos (`600`) y propietario no root del servicio.
3. Una variable nueva se añade en el mismo PR a `.env.example` y a la tabla de `INFRASTRUCTURE.md`.
4. Un secreto filtrado se rota y se invalida (`token_version` incrementa para JWT).
5. La ventana de reembolso es **configurable** (decisión del equipo): el valor inicial sale de `REFUND_WINDOW_DAYS` y luego lo gestiona el administrador desde `system_settings`.

Variables añadidas en v2.2: `PHONE_COUNTRY=BO`, `UPLOADS_DIR`, `UPLOAD_MAX_BYTES`, `WEB_MERCHANT_ORIGIN`, `WEB_ADMIN_ORIGIN`, `ADMIN_ALLOWED_IPS` (opcional). Lista completa en `INFRASTRUCTURE.md`.

---

## 9.13 Integración del Stack Tecnológico

### 9.13.1 Puntos de integración

| De | A | Protocolo / contrato | Autenticación |
|----|---|----------------------|---------------|
| App móvil | Caddy → API | HTTPS, REST, `openapi.yaml` | JWT de acceso; refresh en `flutter_secure_storage` |
| Web comercio (:443) | Caddy → API | HTTPS, REST | JWT en memoria; refresh en cookie `HttpOnly` propia |
| Web administración (:8443) | Caddy → API | HTTPS, REST | Ídem, cookie y `aud` propios, solo `admin` |
| API | PostgreSQL | SQL por pool, rol `paseo_app`, contexto RLS por transacción | Contraseña desde `.env` |
| API / worker | Proveedor SMS | `OtpSender` (puerto) | Credenciales en `.env` |
| API / worker | Servidor de correo | `EmailSender` por SMTP | Credenciales en `.env` |
| API / worker | FCM | Push | Credenciales en `.env` |
| API | Volumen `uploads` | Sistema de archivos | Usuario no root del contenedor |
| `migrate` (Flyway) | PostgreSQL | JDBC, rol `paseo_owner` | Contraseña desde `.env` |
| `backup` | PostgreSQL y `uploads` | `pg_dump`, copia de archivos | Rol `paseo_backup` |

### 9.13.2 Flujo: registrar una compra
```
Cajero (móvil o web) ── identify {QR | teléfono} ──► API ── RLS ──► BD
        ◄── ticket de identificación (5 min) + nombre enmascarado
Cajero ── preview {ticket, monto} ──► API ── RuleResolver + PointsCalculator
        ◄── puntos calculados (sin guardar)
Cajero ── purchases {ticket, monto, Idempotency-Key} ──► API
   API: BEGIN → set_config (claims) → INSERT purchases (sucursal del claim `br`)
        → INSERT points_ledger (CREDIT) → trigger actualiza saldo → audit_log → COMMIT
   Cliente: notificación y movimiento en su historial
```

### 9.13.3 Flujo: reembolso
```
Cajero/Dueño ── multipart {purchase_id, foto de factura, nº de factura, razón social}
   API: valida ventana, que la compra sea suya y esté sin reembolso
        guarda la foto (volumen), copia sucursal y hora de la compra
        INSERT refund_requests (PENDING) + notificación al administrador
Administrador (web :8443) ── ve foto, nº, razón social, sucursal, hora y saldo del cliente
   ├─ rechaza (nota obligatoria) ─────────────► REJECTED + aviso al solicitante
   └─ aprueba (FULL | PARTIAL) ─► una transacción:
        APPROVED (WHERE status='PENDING') → INSERT REVERSAL → faltante → audit_log
        Cliente ve la reversión en su historial
```

### 9.13.4 Flujo: registro y autenticación
```
Registro: correo + teléfono boliviano + contraseña (Argon2id)
   → SMS con OTP al teléfono (mínimo obligatorio)  → pv=true
   → código por correo (verifica el correo; habilita la recuperación)
Login: correo + contraseña → access token (15 min) con claims role/cid/est/br/pv + refresh
Recuperar cuenta: correo → token de un solo uso → nueva contraseña → token_version++
```

---

## 9.14 Matriz de Trazabilidad Requerimiento–Tecnología

> Solo se usan los identificadores que ya aparecen en este capítulo (RNF-01, 02, 04, 05, 06, 07, 09, 10, 11; HUT-03, 04, 07; HU-01 a 07, 10 a 12, 15, 17, 18, 21, 23). Las HU y RF que no se citan aquí deben completarse con las secciones 6.2 y 7 del documento oficial. Las funciones nuevas de v2 y v2.1 aparecen como "ID por asignar".

| Requisito | Descripción | Tecnología / decisión | Sección | Verificación |
|-----------|-------------|----------------------|---------|--------------|
| RNF-01 | Protección de contraseñas | **Argon2id** (formato PHC), parámetros OWASP como mínimo | 9.8.4 | Prueba de formato y de verificación |
| RNF-02 | Roles y acceso | RBAC + claims JWT + **RLS** | 9.6.5, 9.8.1–9.8.2 | Matriz rol × endpoint; pruebas RLS |
| RNF-04 / HUT-03 | Móvil y escritorio | Flutter móvil + web comercio (:443) + web administración (:8443) | 9.4.1, 9.12.1 | Builds en CI; pruebas responsivas |
| RNF-05 / HUT-04 | Integridad de puntos | Transacciones, ledger de solo inserción, trigger de saldo, `CHECK`, idempotencia | 9.6.2, 9.6.4 | Pruebas de integración de ledger y concurrencia |
| RNF-06 | Auditoría | `audit_log`, ledger inmutable, `correlation_id` | 9.6.3 | Prueba de escritura de auditoría |
| RNF-07 / HUT-07 | APIs REST documentadas | Dart Frog + `openapi.yaml` primero | 9.7 | Validación de contrato en CI |
| RNF-09 | Respaldos | `pg_dump` + volumen `uploads`, restauración probada | 9.12.3 | Prueba de restauración |
| RNF-10 | Evolución | Hexagonal en backend, contratos compartidos, puertos | 9.2, 9.5 | Regla de dependencias en CI |
| RNF-11 | Privacidad mínima | Nombre enmascarado, sin PII en claims, fotos con acceso restringido | 9.8.5 | Pruebas de API y revisión |
| HU-01, HU-02 | Registro e inicio de sesión | JWT, refresh rotativo, SMS + correo | 9.8 | Escenario 1 |
| HU-03 | Perfil y QR | `qr_flutter`, token firmado de ~60 s | 9.8.5 | Prueba de expiración |
| HU-04, HU-05 | Saldo y movimientos | `customer_balances`, `points_ledger` | 9.6 | API y RLS |
| HU-06, HU-07 | Recompensas y canje | `rewards`, `redemptions`, trigger de saldo | 9.6.4 | Canje concurrente |
| HU-10 | Identificar cliente | QR o teléfono → ticket firmado | 9.7.2 | API |
| HU-11 | Registrar compra | Caso de uso transaccional, conversión variable | 9.5.6 | Tabla de conversión |
| HU-12 | Validar canje | `UPDATE … WHERE status='ISSUED'` | 9.6.4 | Doble validación |
| HU-15 | Gestión de comercios | `/admin/establishments`, sucursales | 9.7.2 | API |
| HU-17 | Equivalencias de puntos | `points_rules` versionadas, **fijadas por el administrador** | 9.5.6 | Resolución y versionado |
| HU-18 | Recompensas (admin) | `/admin/rewards`, aprobación de propuestas | 9.7.2 | API |
| HU-21 | Marcas antifraude | `fraud_flags`, 5 reglas fijas | 9.8.7 | Unitarias de reglas |
| HU-23 | Notificaciones | FCM + notificaciones en la app | 9.7.6 | Manual |
| ID por asignar | Reembolsos con foto de factura | `refund_requests`, `refund_attachments`, `REVERSAL` | 9.5.7 | Escenarios 4 y 5 |
| ID por asignar | Sucursales (cajero con sucursal fija) | `branches`, claim `br` | 9.6.3 | RLS por sucursal |
| ID por asignar | Dashboard del comercio | `/merchant/stats/summary` | 9.7.2 | API |
| ID por asignar | Parámetros configurables | `system_settings` | 9.6.3 | Prueba de configuración |
| Encuesta | Preferencias de los comercios | Ver Anexo D | Anexo D | — |

---

## 9.15 Análisis Comparativo de Alternativas Tecnológicas

> Puntajes de 1 a 5 (mayor es mejor) del autor: evaluación razonada, no medición. Donde se citan datos externos, se indica su límite.

### 9.15.1 Backend
Ver la matriz de 9.1. **Dart Frog + PostgreSQL** (23) frente a NestJS (21), Serverpod (20) y BaaS (19). Ventaja decisiva: un solo lenguaje para el equipo y REST explícito.

### 9.15.2 Frontend

| Opción | C1 Tiempo | C2 Una base de código móvil/web | C7 Un solo lenguaje con el backend | QR y cámara | Total |
|--------|-----------|-------------------------------|------------------------------------|-------------|-------|
| **Flutter** | 4 | 5 | 5 | 4 | **18** |
| React Native + web aparte | 3 | 3 | 3 | 4 | 13 |
| Solo web (PWA) | 4 | 3 | 3 | 2 | 12 |

Una PWA haría más difícil el escaneo y el acceso a la cámara en el móvil, que es el uso principal del cliente.

### 9.15.3 Estado en Flutter
**Riverpod** (elegido) frente a Bloc y Provider: menor ceremonia que Bloc, más testeable que Provider sin contexto. Bloc es válido si el equipo ya lo domina.

### 9.15.4 Migraciones

| Opción | Pros | Contras | Decisión |
|--------|------|---------|----------|
| **Flyway** | SQL puro, versionado correlativo, validación de checksum, imagen Docker | Sin *undo* en la edición Community; requiere JVM (dentro del contenedor) | **Elegida** (pedido del equipo) |
| dbmate | Ligero, un binario | Menos validación de integridad | Descartada |
| Liquibase | Muy completo | Más configuración que el MVP necesita | Descartada |

### 9.15.5 Hash de contraseñas (decisión del equipo: Argon2id)

| Algoritmo | Evaluación |
|-----------|------------|
| **Argon2id** | Recomendado actualmente para contraseñas; resistente a ataques con GPU por consumo de memoria |
| bcrypt | Aceptable y ampliamente probado; límite de longitud de entrada y sin dureza de memoria |
| scrypt / PBKDF2 | Válidos; PBKDF2 solo si se exige cumplimiento específico |

**Librerías Dart para Argon2id** (consultadas en pub.dev el 02/10/2026; el estado de mantenimiento debe revisarse el día de integrarlas):

| Paquete | Tipo | Observaciones | Evaluación |
|---------|------|---------------|------------|
| `serverpod_argon2` | Nativa (librerías precompiladas) y WebAssembly para web | Versión **0.1.0** (reciente, madurez no demostrada); editor verificado `serverpod.dev`; formato PHC; por defecto parámetros OWASP (19 MiB, 2 iteraciones); incluye benchmark frente a implementaciones en Dart puro | **Candidata principal** |
| `hashlib` | Dart puro | Clase `Argon2` con `Argon2id`, codificación PHC (`encode`, `fromEncoded`) | **Alternativa** |
| `dargon2` | Enlaces a la implementación de referencia en C (FFI) | Solo para Dart nativo; hay variante para Flutter; la actualidad del paquete no se verificó | Posible |
| `argon2` | Dart puro | La última versión publicada tiene unos 5 años | **Descartada** (regla de no usar dependencias abandonadas) |
| `fargon2` | Plugin para Android/iOS | No sirve para el servidor | Descartada |

**Decisión práctica:** antes de fijar el paquete, medir en el servidor el tiempo por hash con los parámetros elegidos (un Argon2id en Dart puro puede ser lento) y verificar con vectores de prueba conocidos. El hash se guarda en formato PHC, lo que permite cambiar de librería sin invalidar contraseñas existentes.

### 9.15.6 Verificación por teléfono (decisión del equipo: SMS como mínimo; correo además)

| Opción | Pros | Contras |
|--------|------|---------|
| **SMS** (mínimo) | Llega a cualquier móvil, no exige internet de datos | Costo por mensaje; entrega variable |
| WhatsApp | Habitualmente más barato por mensaje | Su disponibilidad y costo para Bolivia **no se verificaron** |
| Solo correo | Costo casi nulo | No valida el teléfono que se dictará en caja |

Datos de costo encontrados (**fuentes de terceros, no oficiales; deben confirmarse con el proveedor**): una página comparativa de precios SMS indica que los operadores locales cobran entre 0,10 y 0,20 Bs por SMS estándar (0,014–0,029 USD) y lista a Twilio con un precio base de 0,1452 USD por mensaje a Bolivia, con una antigüedad de la página de unos 5 meses. Twilio Verify (servicio administrado) añade **0,05 USD por verificación exitosa** además del costo del canal, según varios análisis de agosto de 2026.

**Recomendación:** implementar el OTP propio (hash, expiración, intentos, límites, ya previsto en 9.8.6) y usar el proveedor solo para **enviar** el SMS, sin el cargo por verificación; y enviar SMS **únicamente al registrarse y al cambiar de teléfono** (no en cada inicio de sesión). Así el gasto escala con los clientes nuevos, no con el uso. El proveedor aún no está elegido.

### 9.15.7 Despliegue

| Opción | Pros | Contras |
|--------|------|---------|
| **VPS + Docker Compose** | Más simple de explicar y depurar; control total; sin cuotas que apaguen la demo | Hay que administrar el servidor |
| Plataforma de contenedores (PaaS) | Menos administración | Puertos adicionales, volúmenes persistentes y límites de planes pueden complicar el diseño de dos puertos y las facturas subidas |
| Serverless | Escala | Incompatible con el worker y el volumen de archivos sin rediseñar |

Pendiente de confirmación del equipo.

### 9.15.8 Exposición de los dos paneles web

| Opción | Pros | Contras |
|--------|------|---------|
| **Dos puertos** (elegida por el equipo) | Sin DNS adicional; un solo certificado de host | Las cookies **no se aíslan por puerto**; hay que abrir 8443; algunas redes corporativas bloquean puertos no estándar |
| **Dos subdominios** (`app.` y `admin.`) | Aislamiento real de cookies y orígenes; reglas de firewall y de Caddy más claras | Requiere un registro DNS más |
| Dos rutas en el mismo origen | Lo más simple | Comparten origen y almacenamiento; peor aislamiento |

La elección del equipo es válida con los controles de 9.12.1. **Mejor alternativa si el tiempo y el DNS lo permiten:** subdominios, porque el aislamiento deja de depender de convenciones de nombres de cookie.

---

## 9.16 Ventajas y Desventajas del Stack Seleccionado

| Ventajas | Desventajas / riesgos |
|----------|----------------------|
| Un solo lenguaje (Dart) en móvil, web, API y worker | Dart Frog y el ecosistema Dart en servidor son menos extensos que Node o Java; hay menos librerías maduras (por ejemplo, Argon2) |
| Un código Flutter para móvil y dos webs | El build web de Flutter y la lectura de QR con webcam requieren validación; el peso del build web es mayor que el de una web tradicional |
| Integridad de puntos reforzada **en la base de datos** (ledger, trigger, `CHECK`) | Más SQL y más pruebas de integración que con un ORM |
| RLS añade una segunda barrera de aislamiento entre comercios, sucursales y clientes | Mal configurada se salta (superusuario, dueño); exige disciplina en cada migración |
| Flyway da historial de esquema verificable | Solo avanza (sin *undo* en Community); exige migraciones compatibles |
| Hexagonal en backend aísla las reglas de negocio | Más estructura inicial; en Flutter se recorta (propuesta pendiente de confirmar) |
| Docker Compose reproducible; barato | Un solo servidor es un punto único de fallo; RPO de hasta 24 h con respaldo diario |
| Conversión variable y fijada por el administrador, versionada | Un único punto de configuración; un error del administrador afecta a muchos comercios |
| Reembolso controlado y trazable por el ledger | Fricción operativa: el comercio espera la aprobación del administrador |
| Dos paneles web separados | Más artefactos que mantener y desplegar; cookies compartidas entre puertos |
| SMS mínimo + correo: verificación fuerte del teléfono que se dicta | Costo por SMS y dependencia de un proveedor aún sin elegir |

---

## 9.17 Decisiones Arquitectónicas

Estado: **D** = decidido por el equipo; **P** = propuesta del autor aún sin confirmar; **A** = abierta.

| ID | Decisión | Motivo | Consecuencia | Estado |
|----|----------|--------|--------------|--------|
| ADR-01 | Backend propio en Dart Frog sobre PostgreSQL | Un lenguaje, REST, transacciones | Menos librerías maduras | D |
| ADR-02 | Monorepo con `pub workspaces` y `paseo_shared` | Contratos compartidos | Un solo repo que versionar | D |
| ADR-03 | Hexagonal completa en backend; feature-first ligera en Flutter | Aislar reglas donde importan | El recorte en Flutter no está confirmado | P |
| ADR-04 | PostgreSQL 18 sin ORM, SQL explícito | Control de transacciones y RLS | Más SQL manual | D |
| ADR-05 | Flyway con versión fija y migraciones `V###` inmutables | Historial verificable | Solo avanza | D |
| ADR-06 | JWT de 15 min con claims `role, cid, est, br, pv, ev, tv`, sin PII; `aud` por aplicación | Autorización y aislamiento | Claims pueden quedar 15 min desactualizados | D |
| ADR-07 | RLS con rol `paseo_app` sin privilegios de dueño | Defensa en profundidad | Disciplina por migración | D |
| ADR-08 | Ledger de solo inserción; saldo mantenido por trigger | Auditoría y sin condición de carrera | Sin `UPDATE` directo de saldo | D |
| ADR-09 | Conversión variable, versionada, **fijada solo por el administrador** | Control central | El administrador es cuello de botella | D |
| ADR-10 | Puntos sobre el **monto neto tras descuento** | Coherencia económica | Se guardan bruto, descuento y neto | D |
| ADR-11 | Verificación: **SMS del teléfono como mínimo** y correo además (recuperación) | Teléfono confiable; recuperación | Costo por SMS | D |
| ADR-12 | **Solo teléfonos bolivianos** (`+591`) | Alcance del producto | Sin usuarios extranjeros | D |
| ADR-13 | **Argon2id** para contraseñas | Algoritmo recomendado | Librería Dart a validar con benchmark | D |
| ADR-14 | **Dos builds web** (comercio y administración) en **dos puertos** | Separación de paneles | Aislar cookies y orígenes | D |
| ADR-15 | Reembolso: solicita el personal (incluido el cajero), **aprueba el administrador**; solo total | Control y trazabilidad | Demora hasta la aprobación | D |
| ADR-16 | Saldo insuficiente: reversión parcial con faltante registrado | Mantener el invariante | Pérdida parcial posible | D |
| ADR-17 | No se restituye el canje de un descuento al reembolsar | Simplicidad del MVP | Caso de borde sin cubrir | D |
| ADR-18 | Cajero con **sucursal fija**; cada comercio tiene al menos una sucursal | Trazabilidad por sede | Un cajero multi-sucursal requiere varias cuentas | D |
| ADR-19 | Solicitud de reembolso: **foto de la factura, número y razón social** | Evidencia verificable | Almacenamiento de archivos y datos personales en las fotos | D |
| ADR-20 | Parámetros de negocio **configurables** en base de datos (ventana de reembolso, etc.) | Cambiar sin redeploy | Requiere auditoría de cambios | D |
| ADR-21 | Antifraude con 5 reglas fijas | Alcance del MVP | Sin puntajes estadísticos | P |
| ADR-22 | Despliegue en VPS con Docker Compose | Simplicidad | Punto único de fallo | **A** (recomendado, sin confirmar) |

---

## 9.18 Roadmap Tecnológico

Sin fechas: el calendario real depende del plazo de la hackathon, que no consta en este capítulo. Cada fase termina con algo demostrable.

| Fase | Objetivo | Contenido principal |
|------|----------|---------------------|
| **0. Fundaciones** | Entorno reproducible | Monorepo, Compose, roles de BD, Flyway V001–V002, CI con migraciones y pruebas RLS, `AGENTS.md`, `openapi.yaml` inicial, **benchmark y elección de la librería Argon2id**, **elección del proveedor SMS** |
| **1. Rebanada vertical (Must)** | La demo de punta a punta | Registro con SMS y correo → login → QR o teléfono → vista previa → compra (con sucursal) → saldo → canje → validación |
| **2. Resto de Must** | Paneles y control | Web comercio y web administración en sus puertos; conversión fijada por el administrador; **reembolsos con foto, número y razón social**; sucursales; `system_settings`; auditoría |
| **3. Should** | Valor para el comercio | Dashboard (`/merchant/stats`), alerta de canje y resúmenes (worker), propuestas de recompensas, marcas antifraude |
| **4. Could** | Pulido | Recordatorios de fechas, confirmación del cliente al acreditar por teléfono, `jti` de QR de un solo uso |
| **Después del MVP** | Endurecimiento y evolución | Subdominios en lugar de puertos; almacenamiento de objetos para las facturas; archivado de WAL para reducir el RPO; reembolso parcial; WhatsApp como canal de OTP (si se verifica para Bolivia); motor de riesgo con puntajes; distribución en tiendas e iOS; evolución hacia Jarvis Paseo y PaseoYa (referidos en el documento oficial, RNF-07 y RNF-10) |

**Riesgos técnicos y mitigación:**

| Riesgo | Mitigación |
|--------|-----------|
| Librería Argon2 inmadura o lenta en Dart | Benchmark y vectores de prueba en la Fase 0; formato PHC para poder cambiarla |
| Costo y disponibilidad del SMS | Enviar solo al registro y cambio de teléfono; OTP propio; adaptador de consola para demo |
| Escaneo de QR con webcam en web | Entrada manual del teléfono como camino principal en computadora; probar pronto |
| Cookies compartidas entre puertos | Nombres y `aud` propios, CORS explícito; migrar a subdominios si es posible |
| Fotos de facturas: datos personales y espacio | Acceso solo por API con permisos, tamaño máximo, política de retención (valor por definir) |
| Alcance de los Must (reembolsos, sucursales, dos webs) | Si el tiempo aprieta, recortar primero Should/Could y el reembolso a su flujo mínimo |
| Un solo servidor | Respaldos probados y fuera del servidor |

---

# Anexo A — Infraestructura (resumen; el detalle está en `INFRASTRUCTURE.md`)

| Servicio | Imagen / origen | Función |
|----------|-----------------|---------|
| `db` | `postgres:18-alpine` | Base de datos, volumen persistente, healthcheck, init de roles |
| `migrate` | `flyway/flyway:13.8.1` (fijar la última existente) | Aplica `V###` y termina |
| `api` | Dockerfile multi-stage de Dart | API REST, rol `paseo_app`; volumen `uploads` (facturas) |
| `worker` | Mismo binario que `api` | Resúmenes, recordatorios, limpieza de códigos, expiración de solicitudes de reembolso (si se adopta ventana) |
| `caddy` | `caddy:2` | TLS y proxy; sirve web comercio (**443**) y web administración (**8443**) |
| `backup` | `pg_dump` programado, rol `paseo_backup` | Respaldos de la base y del volumen `uploads` (RNF-09) |
| `mailpit` | Solo perfil `dev` | Captura correos de prueba |

Orden de arranque: `db` (healthy) → `migrate` (completado con éxito) → `api` y `worker` → `caddy`. Recomendación para la demo: **un VPS con Docker Compose**; evitar planes gratuitos con cuotas que apaguen la demo.

---

# Anexo B — SDD y agentes

## B.1 Herramienta SDD
**GitHub Spec Kit** (greenfield; constitución → especificación → plan → tareas → implementación). Alternativa ligera: OpenSpec. **Riesgo conocido:** desvío entre spec y código; mitigación: ningún cambio de comportamiento sin tocar su spec y sin prueba.

## B.2 Encaje con el documento existente
| Documento | Artefacto SDD |
|-----------|---------------|
| Capítulo 9, `AGENTS.md` | **Constitución** |
| HU + criterios de aceptación | `spec.md` de cada feature |
| Arquitectura 9.2 / API 9.7 | `plan.md` y `contracts/openapi.yaml` |
| MoSCoW | `tasks.md` (Must primero) |

**Constitución propuesta (extracto):**
1. El dominio del backend no depende de ningún framework.
2. Los puntos se mueven solo mediante el ledger; el saldo nunca es negativo; el ledger no se edita.
3. Toda escritura crítica es idempotente y auditada.
4. Todo endpoint existe primero en `openapi.yaml`.
5. Ningún cambio de comportamiento sin spec y sin prueba.
6. El cliente nunca calcula puntos de forma autoritativa.
7. Toda tabla nace con RLS y su prueba; las migraciones aplicadas son inmutables.
8. Los claims JWT no contienen datos personales.
9. Un reembolso solo se ejecuta tras aprobación del administrador y solo como movimiento `REVERSAL` del ledger.

## B.2.1 Orden de trabajo sugerido
1. Constitución, `AGENTS.md`, `INFRASTRUCTURE.md`, `openapi.yaml`.
2. Esqueleto del monorepo, Compose con Flyway (V001–V002), roles de base y CI.
3. Rebanada vertical: **registro (correo + teléfono) → verificación → login → QR / teléfono → vista previa → registrar compra → ver puntos → canjear → validar canje.**
4. Paneles web de comercio y administración (dashboard, aprobaciones).
5. "Should have" (alerta de canje, resumen, propuestas de ofertas) y luego "Could have".

## B.3 Skills, plugins y MCP
**Instalar (oficiales):** plugin `dart-flutter` (`flutter/agent-plugins`), skills de `dart-lang/skills`, servidor MCP de Dart y Flutter, servidor MCP Developer Knowledge, Spec Kit, GitHub MCP. Las órdenes de instalación exactas deben tomarse de la documentación oficial de Flutter el día de configurar el entorno.

**Opcionales:** Very Good CLI MCP (marcado experimental por su documentación), `dart_pubdev_mcp`, y un MCP de PostgreSQL **solo lectura, con el rol `paseo_app` o uno de solo lectura sobre la base local**, nunca el superusuario ni datos de demostración reales.

**No recomendado:** decenas de skills de la comunidad sin auditar. Mejor: oficiales + 3 propios (`paseo-hexagonal-rules`, `paseo-api-contract`, `paseo-ledger-invariants`) y, añadido en v2, `paseo-db-migrations` (Flyway + RLS + `GRANT` por tabla).

**Archivos de reglas:** viven en la raíz: `AGENTS.md` (fuente) y `CLAUDE.md` con una línea que lo importe, para no mantener dos copias. Los plugins de Claude Code no empaquetan archivos de reglas automáticamente.

## B.4 Reglas de trabajo con agentes
- Un agente por feature y rama.
- El humano revisa el **spec y el plan** antes de implementar.
- Las pruebas de aceptación las escribe o revisa una persona distinta de quien implementó.
- El agente no ejecuta comandos destructivos, no toca `.env` y **no edita migraciones ya aplicadas**.

---

# Anexo C — Alternativas descartadas

| Alternativa | Motivo de descarte |
|-------------|--------------------|
| Flutter directo a PostgreSQL | Inseguro e inviable |
| Serverpod | RPC generado, no REST abierto (RNF-07) |
| Firebase / Supabase | El requisito de PostgreSQL en Docker y el control del ledger se debilitan; sus ventajas (RLS + claims) se replican con PostgreSQL propio |
| NestJS / Node | Segundo lenguaje para un equipo de cuatro |
| Microservicios / Kubernetes | Sobreingeniería para un MVP |
| Hexagonal completa en Flutter | Costo alto, valor demostrable bajo |
| `dbmate` | Reemplazado por Flyway por pedido del equipo (versionado y validación de checksum) |
| bcrypt | El equipo eligió Argon2id |
| Un solo build web para comercio y administración | El equipo decidió dos builds separados en dos puertos |
| Descripción libre de la factura en el reembolso | El equipo definió foto + número + razón social |
| Conversión propuesta por el comercio | El equipo decidió que la fija solo el administrador |
| Cajero multi-sucursal | El equipo decidió sucursal fija por cajero |
| Reembolso parcial por monto | Fuera del MVP por decisión del equipo |
| Identificación por CI | Dato sensible innecesario; el teléfono verificado cumple la función |
| Solo QR para identificar | 7/15 prefieren otra vía; además los usuarios de PC lo usarían con webcam |
| Motor de riesgo con puntajes (MVP) | Necesita historial; ningún comercio lo pidió; se reduce a 5 reglas fijas |
| Reembolso inmediato por el comercio | Sin control del administrador; abre abuso (acreditar y revertir) |
| Saldo negativo para absorber reembolsos | Rompe el invariante del ledger; se usa reversión parcial con faltante trazado |
| ORM en Dart | Control exacto de transacciones y RLS |

---

# Anexo D — Trazabilidad con la encuesta a comercios

**Alcance y límites.** 15 respuestas, 14 de ellas recibidas entre las 4:24 y las 5:01 p. m. del 02/10/2026. Es una muestra por conveniencia; no se sabe cuántas tiendas distintas representa ni si respondió el dueño o un vendedor. No se preguntó por conectividad a internet, uso previo de programas de fidelización ni disposición a pagar. Los resultados orientan el diseño; no lo demuestran.

| Pregunta | Resultado | Decisión | Sección |
|----------|-----------|----------|---------|
| Dispositivo | 9 celular, 6 computadora | Web para el rol comercio | 9.4.1 |
| Tiempo aceptable | 10 de 15 entre 10 y 30 s, 4 menos de 10 s, 1 más de 30 s | Flujo de 3 interacciones, vista previa | 9.4.6 |
| Identificar cliente | 8 QR, 4 CI o teléfono, 3 factura | QR + teléfono; factura solo como `invoice_ref` antifraude; CI descartado | 9.7.2, 9.8.6, 9.5.6 |
| Beneficio | 12 descuento %, 5 regalos, 1 monto fijo | `reward_type` `PERCENT`/`FIXED`/`GIFT` | 9.6.3 |
| Cambio de ofertas | 7 fechas especiales, 4 mensual, 4 semanal | Recompensas: propuesta del comercio + aprobación del admin; campañas de conversión con vigencia, **fijadas por el admin**; `special_dates` | 9.5.6, 9.6.3 |
| Dashboard | 8 clientes que regresan, 5 puntos cargados, 4 ranking | `/merchant/stats/summary`; actividad por vendedor | 9.7.2, 9.8.7 |
| Alertas | 8 canje, 8 resumen, 4 fechas festivas | Push de canje y `worker` de resúmenes | 9.7.6 |

**Definición operativa de "clientes que regresan gracias a la app":** cliente con 2 o más compras en el mismo comercio dentro de 30 días. Es una métrica de **recurrencia**, no de causalidad; no se puede afirmar que la app los hizo volver.

---

# Decisiones del equipo y pendientes

## Decisiones aplicadas (respuestas a los pendientes de la v2.1)

| Pendiente | Decisión del equipo | Dónde se aplicó |
|-----------|---------------------|-----------------|
| 1. Panel comercio y administración | **Dos builds web, dos puertos** | 9.4.1, 9.12.1, ADR-14 |
| 2. Argon2id o bcrypt | **Argon2id** (librería a validar) | 9.8.4, 9.15.5, ADR-13 |
| 3. Verificación de teléfono | **SMS del teléfono como mínimo; correo además** (interpretación explícita en 9.8.6) | 9.8.6, 9.15.6, ADR-11 |
| 6. Refresh en Flutter Web | "Sí" (se interpreta como aceptar la propuesta: access en memoria + refresh en cookie `HttpOnly`) | 9.4.3, 9.8.3 |
| 7. Conversión de un comercio | **La fija solo el administrador** | 9.5.6, ADR-09 |
| 8. Puntos con descuento | **Sobre el monto neto** | 9.5.6, ADR-10 |
| 9. País del teléfono | **Solo bolivianos (`+591`)** | 9.8.6, ADR-12 |
| 11. Base de 9.12 | **`INFRASTRUCTURE.md` y el Anexo A** (confirmado) | 9.12 |
| 12. Ventana de reembolso | **Configurable** (valor inicial sin definir) | 9.5.7, 9.12.4 |
| 13. Reembolso parcial | **No** | 9.5.7, ADR-15 |
| 14. Quién solicita reembolso | **El cajero** (y el dueño, con la restricción de 9.5.7) | 9.5.7, ADR-15 |
| 15. Saldo insuficiente | **Reversión parcial con faltante trazado** | 9.5.7, ADR-16 |
| 16. Canje en reembolso | **No se restituye** | 9.5.7, ADR-17 |
| 17. Sucursales | **Sucursal fija por cajero** | 9.6.3, ADR-18 |
| 18. Datos de la factura | **Foto, número y razón social** | 9.5.7, ADR-19 |

## Pendientes abiertos

1. **Destino de la demo** (sin respuesta): se mantiene la recomendación de VPS con Docker Compose (ADR-22).
2. **Recorte de la hexagonal en Flutter** (sin respuesta): se mantiene la propuesta de feature-first ligera (ADR-03).
3. **`invoice_ref` en las compras** (sin respuesta): se mantiene opcional por establecimiento. Nota: el reembolso ya exige el número de factura, de modo que la compra con `invoice_ref` permite compararlo.
4. **Confirmar las dos interpretaciones** de las respuestas ambiguas: "sí" en el refresh de la web (aceptar la propuesta de cookie) y SMS obligatorio con correo adicional (no exigido para acumular puntos).
5. **Proveedor de SMS y de correo**, y su costo real: confirmar con el proveedor; las cifras de 9.15.6 son de terceros.
6. **Librería de Argon2id:** benchmark y vectores de prueba (Fase 0).
7. **Valores iniciales:** ventana de reembolso, vencimiento de solicitudes pendientes, tamaño máximo y **retención** de las fotos de factura.
8. **Razón social:** ¿la del comprador o la del emisor?
9. **Numeración móvil de Bolivia:** verificar la regla de 8 dígitos que empiezan con 6 o 7.
10. **Motivo opcional** en el reembolso (sugerencia del autor): ¿se mantiene o se quita?
11. **Comercios de una sola sede:** ¿se acepta la sucursal "Principal" automática?
12. **HTTPS de Caddy en el puerto 8443:** probarlo en el servidor real; y reconsiderar subdominios si el DNS lo permite (9.15.8).
