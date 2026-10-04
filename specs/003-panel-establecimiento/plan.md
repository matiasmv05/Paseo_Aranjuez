# Implementation Plan: Panel del Establecimiento (Acreditación y Canje)

**Branch**: `feat/003-panel-establecimiento` | **Date**: 2026-10-03 | **Spec**: `specs/003-panel-establecimiento/spec.md`

**Input**: Feature specification from `specs/003-panel-establecimiento/spec.md`

**Authority**: `AGENTS.md` and `.specify/memory/constitution.md` govern this plan.

## Summary

Se construye el panel operativo del comercio: identificar al cliente por QR o teléfono, registrar la compra con los puntos acreditados por el servidor, previsualizar el cálculo y listar los movimientos del local. El núcleo es un motor de conversión en Dart puro (`domain/PointsCalculator` + `domain/RuleResolver`) con aritmética entera, que preview y registro comparten literalmente; sobre él se apoyan cuatro casos de uso, tres migraciones nuevas (`V004`–`V006`) y las pantallas del panel web del comercio.

## Technical Context

**Language/Version**: Dart 3.13 / Flutter 3.47.6 vía FVM (`.fvmrc`); usar siempre `fvm dart` y `fvm flutter`, nunca el Flutter global.

**Primary Dependencies**:
- Sin dependencias nuevas en `apps/api`. Reutiliza `dart_frog`, `postgres` (vía `PgDatabase` existente), `cryptography` (Argon2id) y `crypto`/`dart:convert` de la plataforma.
- **Añadidas en `apps/mobile`**: `http` (cliente REST, parseo de `problem+json`) y `flutter_riverpod` (estado). Decidido el 2026-10-03; se fijan versiones exactas en `pubspec.yaml` y se versiona `pubspec.lock` (CI usa `--enforce-lockfile`).
- Sin dependencias nuevas en `packages/paseo_shared`.

**Storage**: PostgreSQL 16 por Flyway `flyway/flyway:13.9.0`. Migraciones nuevas `V004`, `V005`, `V006`. La API conecta como `paseo_app`.

**Testing**: `dart test` (unitarias sin BD), integración contra PostgreSQL real en `127.0.0.1:5433` con rol `paseo_app`, pruebas de contrato OpenAPI con Redocly, pruebas de widget y estado en Flutter.

**Target Platform**: `api` y `web-merchant`. El build `web-merchant` se compila desde `apps/mobile` con `-t lib/main_merchant_web.dart`, así que esta feature **sí** toca `apps/mobile`; lo que no toca es la app movil del cliente (`lib/main.dart`), el `worker` ni el build `web-admin` (`AGENTS.md` §14: no mezclar rutas de comercio y administración en un mismo build web).

**Constraints**: el servidor es la fuente de verdad de los puntos; dinero y puntos en enteros; `Idempotency-Key` y `audit_log` en la escritura crítica; sin datos personales en claims ni en logs; aislamiento por `establishment_id` en la capa de aplicación (RLS supersedida); rutas finas sin reglas de negocio.

**Scale/Scope**: 7 tablas nuevas, 4 endpoints, 4 casos de uso, 4 historias (HU-10, HU-11, HU-13, HUT-02) más `preview`. Un comercio como el de la tienda de barrio; sin shard ni particionado.

## Constitution Check

*GATE: Must pass before implementation and again before review.*

- [x] `docs/openapi.yaml` actualizado antes de cualquier endpoint — FR-002; es el **primer** bloque de trabajo de la secuencia.
- [x] Backend preserva `adapters → application → domain` — el motor de cálculo va en `domain` sin imports; los use cases solo importan `domain`; el SQL queda en `adapters/out`.
- [x] Sin reglas de negocio en rutas ni en las capas de presentación/datos de Flutter — las rutas solo validan, llaman **un** use case y mapean a RFC 9457 (FR-023); Flutter recibe los puntos del servidor y no calcula (FR-010).
- [x] Tablas nuevas con RLS, políticas, `GRANT` mínimo y pruebas de aislamiento — **desviación justificada**: RLS no se incluye. CHK031 y CHK052 quedan **BLOCKED** hasta que se reintroduzca; ver *Complexity Tracking*, `research.md` §2 y SEC-002 de la spec.
- [x] Escrituras críticas con `Idempotency-Key` y `audit_log` — FR-008, FR-018, SEC-009, en la misma transacción.
- [x] Claims del JWT sin datos personales — SEC-001; el ticket firmado **no** es un claim del JWT de sesión y tampoco contiene PII.
- [x] Uploads servidos solo por la API — no aplica: esta feature no maneja archivos (los reembolsos, que sí, son de Persona 4).
- [x] `OPEN_DECISIONS` resueltas con aprobación humana registrada — las tres de `AGENTS.md` §15 que apltaban se resolvieron el 2026-10-03 y quedaron anotadas en la spec; no queda ninguna abierta. Dos de esas resoluciones **desalinean** `AGENTS.md` §8, §9 y §15 con la spec, así que actualizar ese archivo es parte de esta feature (`AGENTS.md` §12), no un extra.
- [x] **Prerrequisito bloqueante, ajeno al alcance de la feature**: el borde no sirve `/api/v1/*`. `infra/Caddyfile` usa `reverse_proxy` sin `handle_path`, y `apps/api/.dart_frog/server.dart` monta `/auth` sin prefijo, así que hoy `https://<host>/api/v1/auth/login` devuelve 404 aunque el contrato, el `Path` de la cookie (§6) y `servers.url` sean correctos. Sin el fix `handle_path /api/v1/*` los 4 endpoints de esta feature tampoco son alcanzables por el borde. **Resuelto:** snippet `(api)` con `handle_path /api/v1/*` importado en los dos vhosts, más 404 explícito para el resto de `/api/*`; `caddy validate` en verde con y sin `ADMIN_ALLOWED_IPS`, y comportamiento comprobado levantando `caddy:2.11.6-alpine` contra un upstream stub. Al probarlo aparecieron dos defectos preexistentes más del mismo vhost (arranque roto con `ADMIN_ALLOWED_IPS` vacío y filtro por IP que era código muerto), también corregidos. Detalle en `research.md` §1, §1.1 y §1.2.

## Project Structure

### Documentation (this feature)

```text
specs/003-panel-establecimiento/
├── spec.md
├── plan.md
├── research.md          # decisiones investigadas: RLS, numeración, formato del ticket, seed
├── data-model.md        # tablas, invariantes, índices, migraciones
├── contracts/
│   └── merchant-openapi-fragment.yaml   # extracto verbatim de docs/openapi.yaml
└── tasks.md
```

### Source Code (repository root)

```text
apps/api/lib/
├── domain/loyalty/
│   ├── cents.dart                    # value object de dinero (int)
│   ├── points.dart                   # value object de puntos (int)
│   ├── rounding.dart                 # FLOOR | ROUND | CEIL
│   ├── points_rule.dart              # entidad PointsRule + scope + tipo
│   ├── rule_resolver.dart            # elige 1 BASE + <=1 CAMPAIGN
│   ├── points_calculator.dart        # formula entera; preview y registro comparten
│   ├── purchase.dart                 # entidad Purchase + invariantes
│   ├── identification.dart           # claims del ticket y del token QR (puros)
│   └── loyalty_errors.dart           # LoyaltyException sobre ApiErrorCode
├── application/merchant/
│   ├── ports.dart                    # EstablishmentRepo, PointsRuleRepo, PurchaseRepo,
│   │                                 # MovementRepo, TicketSigner, RateLimiter
│   └── use_cases/
│       ├── identify_customer.dart
│       ├── preview_purchase.dart
│       ├── register_purchase.dart
│       └── list_movements.dart
├── adapters/out/
│   ├── auth/identification_signer.dart      # HMAC-SHA256: firma y verifica ticket y QR
│   ├── rate_limit/establishment_rate_limiter.dart
│   └── postgres/
│       ├── postgres_establishment_repository.dart
│       ├── postgres_points_rule_repository.dart
│       ├── postgres_purchase_repository.dart
│       └── postgres_movement_repository.dart
├── adapters/in/
│   ├── merchant_use_cases.dart       # expone los 4 use cases como un solo grafo
│   ├── errors.dart                   # + LoyaltyException -> problem+json
│   └── middleware/merchant_auth_middleware.dart  # aud + role + claims verificados
└── routes/merchant/
    ├── _middleware.dart
    ├── customers/identify.dart
    ├── purchases/index.dart          # POST /purchases
    ├── purchases/preview.dart
    └── movements/index.dart          # GET  /movements

apps/mobile/lib/
├── main_merchant_web.dart            # ya existe (stub) -> pasa a runApp real
└── features/merchant/
    ├── presentation/                 # screens, widgets, Riverpod providers
    │   ├── login_screen.dart
    │   ├── identify_screen.dart      # scanner/QR + busqueda por telefono
    │   ├── purchase_screen.dart      # montos + preview + confirmar
    │   └── movements_screen.dart     # lista paginada por cursor
    ├── application/                  # providers + estado de sesion del comercio
    └── data/                         # MerchantApiClient (http), DTO mapping

apps/api/tool/
└── seed_dev_users.dart               # usuarios dev + tokens de ticket/QR (solo dev)

packages/paseo_shared/lib/src/
├── merchant/dto.dart                 # IdentifyResult, PurchaseResult, PreviewResult,
│                                     # Movement, CursorPage<Movement>
└── errors/api_error_code.dart        # +2 codigos nuevos; 2 reservados pasan a contrato
```

**Structure Decision**: `domain/loyalty` y `application/merchant` siguen la convención ya usada por `identity`. El motor de conversión se aísla en `domain` precisamente porque es la parte que debe poder probarse sin base de datos y sin nada más. `paseo_shared` recibe solo DTOs y el enum de errores: nada de lógica. El panel web del comercio vive bajo `features/merchant` con la estructura `presentation`/`application`/`data` que `AGENTS.md` §3 fija para Flutter.

## Data / Contract / Infrastructure Impact

- **API contract**: `docs/openapi.yaml` gana el tag `Comercio` con 4 operaciones. Los paths van **relativos a `servers: [{url: /api/v1}]`**, igual que los 8 endpoints de auth que ya existen; las URL efectivas son `/api/v1/merchant/...`:
  - `POST /merchant/customers/identify` → `/api/v1/merchant/customers/identify`
  - `POST /merchant/purchases/preview` → `/api/v1/merchant/purchases/preview`
  - `POST /merchant/purchases` (requiere header `Idempotency-Key`) → `/api/v1/merchant/purchases`
  - `GET /merchant/movements` → `/api/v1/merchant/movements`
  Los archivos Dart Frog van en `routes/merchant/*.dart` sin carpeta `api/v1`: el prefijo lo aporta el borde, no el árbol de rutas. Mismo criterio que `routes/auth/*.dart`.
  Schemas nuevos: `IdentifyRequest`, `IdentifyResult`, `PreviewPurchaseRequest`, `PreviewPurchaseResult`, `RegisterPurchaseRequest`, `Purchase`, `Movement`, `MovementPage`. Se reutilizan `Problem`, `MoneyCents`, `CursorPage`, `IdempotencyKey` y `bearerAuth` ya definidos.
  **Códigos de error**: `INVALID_QR_TOKEN` y `INVALID_IDENTIFICATION_TICKET` son nuevos y entran al contrato. `CUSTOMER_NOT_FOUND` y `DUPLICATE_INVOICE` estaban marcados `reserved: true` en `ApiErrorCode` y pasan a estar en el contrato, con su prueba de snapshot actualizada.
- **Database**: tres migraciones nuevas, sin `RLS`, con `GRANT` mínimo a `paseo_app` y `REVOKE` de escritura donde no aplica. Detalle completo en `data-model.md`.
  - `V004__comercios.sql`: `establishments`, `branches`, `establishment_staff`, trigger `AFTER INSERT` que crea la sucursal "Principal".
  - `V005__conversion.sql`: `points_rules`.
  - `V006__compras_y_ledger.sql`: `purchases`, `points_ledger`, `customer_balances`, trigger de saldo, índices únicos de `(establishment_id, idempotency_key)` y `(establishment_id, invoice_ref)`, y `REVOKE UPDATE, DELETE, TRUNCATE` sobre `points_ledger` y `customer_balances`. Los triggers van `SECURITY DEFINER` para que los `GRANT` puedan quedarse en solo `SELECT`/`INSERT`.
- **Infrastructure**: una variable de entorno nueva, `IDENTIFICATION_SECRET`, usada para firmar y verificar tanto el token QR como el ticket de identificación (mismo secreto, formatos y TTL distintos). Se documenta en `infra/.env.example` y en `INFRASTRUCTURE.md` §7. Es independiente de `JWT_SECRET`: los tokens de ticket no son sesiones ni los emite el mismo componente, así que rotar uno no debe invalidar al otro.
  El seed se parte en dos, porque SQL no puede hashear contraseñas (`research.md` §6): `infra/seed/R__seed_dev.sql` —que **ya existe** como placeholder `SELECT 1;` y se reemplaza— aporta la regla `BASE` `GLOBAL` activa, una `CAMPAIGN` inerte y un comercio de ejemplo; `apps/api/tool/seed_dev_users.dart` (directorio nuevo) crea los tres usuarios reutilizando el `Argon2idPasswordHasher` de producción y imprime tokens de ticket y QR de prueba. Ambos solo con el override `dev`.
- **Security**: los cuatro endpoints exigen `aud = paseo-web-merchant` y `role ∈ {merchant_owner, merchant_cashier}`; el middleware además relee `users.status` y `users.phone_verified` desde la base, porque los claims pueden tener hasta 15 min de desfase (`AGENTS.md` §6). `establishment_id` y `branch_id` salen siempre de claims verificados, nunca del cuerpo. Rate limit por `establishment_id` en `purchases` y `preview`. Ningún log incluye tickets, tokens QR, teléfonos ni correos.
- **Notifications/jobs**: ninguno. Notificar al cliente que acumula puntos es de la feature de recompensas; el worker no se toca.

## Test Strategy

- **Domain tests** (sin base de datos, tabla de casos):
  - `points_calculator_test.dart`: las tres modalidades de redondeo, el tope, la compra mínima, el multiplicador en basis points, y los empates exactos (`.5`) en ambas etapas del cálculo. Es la prueba que sostiene FR-012.
  - `rule_resolver_test.dart`: precedencia `ESTABLISHMENT > CATEGORY > GLOBAL`, desempate por `priority`, que las campañas no se acumulen, que una campaña no aplicable se ignore, y que sin regla applicable devuelva `NO_APPLICABLE_RULE`.
  - `identification_test.dart`: el sobre firmado no se puede alterar sin romper la firma, y los TTL de 60 s (QR) y 300 s (ticket) se respetan con un reloj falso.
  - `purchase_test.dart`: `net_cents = gross_cents - discount_cents`, montos no negativos, `invoice_ref` obligatoria.
- **Integration tests** (`test/integration/`, PostgreSQL real en 5433, rol `paseo_app`):
  - `merchant_flow_test.dart`: identify por `PHONE` y por `QR` de punta a punta; compra; saldo acreditado; consulta de movimientos.
  - `purchase_idempotency_test.dart`: dos llamadas con la misma `Idempotency-Key` dejan exactamente una fila en `purchases`, una en `points_ledger` y un solo cambio de saldo; la segunda responde 200 con el cuerpo original.
  - `merchant_isolation_test.dart`: el cajero ve solo sus propias compras, el dueño ve todas las del comercio, y los datos de otro comercio no son visibles nunca.
  - `purchase_rules_test.dart`: `DUPLICATE_INVOICE` dentro del mismo comercio y aceptación del mismo `invoice_ref` en otro; `NO_APPLICABLE_RULE`; compra bajo el mínimo que no genera ledger.
  - `hut02_latency_test.dart`: mide identify + compra contra la base real y **falla** si supera 3 s (HUT-02); además calcula el p95 de 20 iteraciones y falla si supera 500 ms (spec SC-002).
  - `migration_grants_test.dart`: comprueba que `paseo_app` no tiene `UPDATE`/`DELETE` sobre `points_ledger` ni `UPDATE` sobre `customer_balances`.
- **API tests** (`test/routes/`): matriz de autorización (token `customer` y `admin` rechazados con 403; `aud` incorrecto rechazada), `problem+json` de cada código nuevo, validación del cuerpo y `Idempotency-Key` ausente rechazado.
- **Flutter tests**: mapeo de `problem+json` a mensaje visible, que la pantalla de movements pide la siguiente página al llegar al final, y un test de widget del flujo identificar -> comprar que muestra el nombre enmascarado y los puntos devueltos por el servidor.
- **Verification commands**:
  ```bash
  fvm dart format --set-exit-if-changed .
  fvm dart analyze --fatal-warnings
  cd apps/api && fvm dart test test/domain test/application test/routes
  docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d --wait db
  cd apps/api && fvm dart test test/integration
  cd apps/mobile && fvm flutter analyze && fvm flutter test
  npx --yes @redocly/cli@2 lint docs/openapi.yaml
  ```

## Complexity Tracking

> Fill only when the Constitution Check requires justification.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| `specs/README.md` gate 6 exige RLS, políticas y prueba de aislamiento en toda tabla nueva; esta feature no los incluye (SEC-002) | La regla 2.7 de `AGENTS.md` fue supersedida el 2026-10-03 con "MVP sin RLS", y `V002` ya está mergeada bajo esa decisión. Es deuda bloqueante ya reconocida, no una omisión de esta feature | Aplicar RLS solo a estas 7 tablas crearía un modelo híbrido incoherente con `V002` y `V003`, y daría una falsa sensación de aislamiento: las tablas de identidad seguirían sin RLS y el riesgo se mantiene igual |
| Se agregan `http` y `flutter_riverpod` a `apps/mobile`, que solo tenía `flutter` y `very_good_analysis` | El panel necesita cliente REST con parseo de `problem+json` y manejo de estado asíncrono; `dart:io HttpClient` no sirve en web | `ChangeNotifier` a mano se justifica para 4 pantallas, pero Personas 4 y 5 faced el mismo patrón otra vez; la decisión se tomó una vez y se documenta aquí |
| Se crea un seed de datos demo, aunque solo `admin` puede definir reglas y Persona 4 no existe | Sin una regla `GLOBAL` activa, HU-11 y HUT-02 no tienen nada contra qué calcular y siempre devolverían `NO_APPLICABLE_RULE`; la feature sería indemostrable | Prohibir el seed deja la feature sin prueba manual posible; el seed es idempotente, vive en `infra/seed/R__seed_dev.sql` y `apps/api/tool/`, y solo se aplica con el override `dev`, nunca en producción real |
| El índice de idempotencia es `(establishment_id, idempotency_key)` y no solo `idempotency_key` | Un índice global hace que dos comercios distintos se rechacen entre sí por una key coincidente, y el 409 que recibe uno le confirma al otro que esa key ya se usó: es una fuga entre inquilinos, y el aislamiento por comercio es lo único que sostiene la seguridad del MVP sin RLS | Respetar el texto literal de `9-stack` §9.5 deja el aislamiento dependiendo de que cada cliente genere claves globalmente aleatorias, que es una suposición, no una garantía |
| Se agrega `apps/api/tool/seed_dev_users.dart` | Los tres usuarios de prueba necesitan `password_hash` Argon2id, y eso no se puede calcular en SQL | Hashear dentro de la API obligaría a un endpoint de producción que devuelve credenciales; hashear en el seed violaría `AGENTS.md` §14 (prohibido cualquier algoritmo que no sea Argon2id) |
| `establishments.category_id` y `points_rules.category_id` se crean **sin clave foránea** | El catálogo de categorías es de Persona 4 y `V004`/`V005` deben aplicar solas, en ese orden, sin depender de una tabla que todavía no existe | Poner la FK ahora hace fallar `flyway migrate` en cuanto se ejecuta el bloque, y bloquear el arranque de las tres migraciones por una tabla de otra feature |
| Los triggers de sucursal Principal y de saldo se crean `SECURITY DEFINER` | Es lo que permite que `paseo_app` tenga `GRANT` de solo `SELECT` sobre `branches` y `customer_balances` y aun así la sucursal se cree sola y el saldo se mueva. Convierte §2 regla 3 ("el código de la API no escribe en `customer_balances`") en una restricción de permiso y no solo de convención | Dar `INSERT` sobre `branches` y `UPDATE` sobre `customer_balances` funciona, pero rompe el `GRANT` mínimo que SEC-002 exige y abre al rol a escribir saldos directamente. Se acepta el riesgo residual del `SECURITY DEFINER` (un `delta` negativo teórico, frenado por `CHECK (balance >= 0)`) y queda anotado en `research.md` §12 |

## Implementation Sequence

0. **Prerrequisitos de la constitution — hechos**: (a) fix del borde en `infra/Caddyfile` (`handle_path /api/v1/*` en los dos vhosts) + `caddy validate`, para que las URL del contrato sean alcanzables; (b) sincronizar `AGENTS.md` §8, §9 y §15 con las decisiones ya tomadas (teléfono sin exigir 6/7, `invoice_ref` obligatorio, sucursal "Principal" automática), porque §12 obliga a actualizarlo. Ninguno de los dos es código de esta feature, pero sin ellos queda especificación y comportamiento divergentes. Ambos cerrados el 2026-10-03; ver `research.md` §1.1 y §1.2.
1. **Contrato primero** (gate 3): `docs/openapi.yaml` con los 4 endpoints, los schemas y los 4 codigos de error; Redocly lint en verde. Extracto a `contracts/`.
2. **Migraciones** `V004`, `V005`, `V006` + seed (`R__seed_dev.sql` y `tool/seed_dev_users.dart`). Verificar que aplican desde cero con Flyway y que los `GRANT` son los mínimos.
3. **Dominio** `domain/loyalty`: `Cents`, `Points`, `Rounding`, `PointsRule`, `RuleResolver`, `PointsCalculator`, `Purchase`, `Identification`, `LoyaltyException`. Con sus pruebas unitarias.
4. **Puertos y casos de uso** `application/merchant`: `ports.dart` y los 4 use cases, con fakes en `test/application/merchant/fakes.dart`.
5. **Adaptadores de salida**: `IdentificationSigner` (HMAC), `PostgresEstablishmentRepository`, `PostgresPointsRuleRepository`, `PostgresPurchaseRepository`, `PostgresMovementRepository`, rate limiter por establecimiento.
6. **Adaptadores de entrada**: `merchant_auth_middleware`, `merchant_use_cases.dart`, extension de `errors.dart` para `LoyaltyException`, y las 4 rutas de routes/merchant/.
7. **DI**: extender `AppDependencies` con los componentes de `merchant` sin romper el grafo de `identity`.
8. **Contrato compartido**: DTOs en `paseo_shared` y los 2 codigos de error nuevos, con la prueba de snapshot actualizada.
9. **Frontend**: `MerchantApiClient` con `http`, providers con Riverpod, y las 4 pantallas; `main_merchant_web.dart` deja de ser stub.
10. **Pruebas de integración y de latencia**, y cierre con todos los comandos de verificación.

## Rollback / Forward Fix

- Las migraciones solo avanzan. Un error en `V004`, `V005` o `V006` se corrige con una migracion nueva; no se edita una ya aplicada (`AGENTS.md` §2 regla 6, y CI lo rechaza).
- El rollback de la API debe seguir siendo compatible con las migraciones ya aplicadas: como las columnas nuevas son las unicas que este feature lee, una version anterior que no las conozca simplemente no las usa.
- Si el formato del token QR resultara incompatible con lo que implemente Persona 1, el cambio se hace en `IdentificationSigner` y en el contrato, no en las tablas.
