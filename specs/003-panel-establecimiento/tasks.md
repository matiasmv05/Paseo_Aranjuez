---
description: "Task list: Panel del Establecimiento (HU-10, HU-11, HU-13, HUT-02)"
---

# Tasks: Panel del Establecimiento (Acreditación y Canje)

**Input**: `specs/003-panel-establecimiento/spec.md` (aprobada), `specs/003-panel-establecimiento/plan.md` (aprobado), `specs/003-panel-establecimiento/research.md`, `specs/003-panel-establecimiento/data-model.md`, `docs/openapi.yaml` (Gate 3 completo), `packages/paseo_shared` actualizado, `AGENTS.md`.
**Prerequisites**: spec/plan aprobados; Gate 3 cerrado en rama `feat/003-panel-establecimiento`; `OPEN_DECISIONS` resueltas el 03/10/2026.
**Authority**: `AGENTS.md`; no se resuelven nuevas `OPEN_DECISIONS` sin aprobación explícita humana.

Verificación global tras cada tarea: `fvm dart format --set-exit-if-changed . && fvm dart analyze --fatal-warnings`. Pruebas: para dominio/application/routes usar `cd apps/api && fvm dart test test/domain test/application test/routes`. Para integración: levantar BD (5433) y `cd apps/api && fvm dart test test/integration`. Flutter: `cd apps/mobile && fvm flutter analyze && fvm flutter test`. Contrato: `npx --yes @redocly/cli@2 lint docs/openapi.yaml`.

## Phase 1: Setup Gates

- [ ] T001 Verificar que spec.md, plan.md, research.md y data-model.md están aprobados y sin `OPEN_DECISIONS` abiertas. Confirmar referencias a rama `feat/003-panel-establecimiento` y a los commits de Gate 3.
- [ ] T002 Confirmar `docs/openapi.yaml` con los 4 endpoints (tag `comercio`) ya existe en este branch (commit c995877). Ejecutar `npx --yes @redocly/cli@2 lint docs/openapi.yaml` → 0 errores, 4 warnings preexistentes aceptables.
- [ ] T003 Crear `specs/003-panel-establecimiento/contracts/merchant-openapi-fragment.yaml` con el fragmento correspondiente a los 4 endpoints. No modificar archivos fuera de `contracts/` en esta tarea.
- [ ] T004 Crear directorios necesarios: `apps/api/tool/`, `apps/api/lib/domain/loyalty/`, `apps/api/lib/application/merchant/`, `apps/api/lib/application/merchant/use_cases/`, `apps/api/lib/adapters/in/middleware/`, `apps/api/lib/adapters/out/postgres/`, `apps/api/lib/adapters/out/rate_limit/`, `apps/api/lib/adapters/out/auth/`, `apps/api/routes/merchant/customers/`, `apps/api/routes/merchant/purchases/`, `apps/api/routes/merchant/movements/`, `apps/mobile/lib/features/merchant/{presentation,application,data}`.

## Phase 2: Foundational Blocking Tasks

### Migraciones (inmutables, nuevas)

- [ ] T010 [D1] [US-Infra] `infra/migrations/V004__comercios.sql`: `establishments`, `branches`, `establishment_staff`. Trigger `AFTER INSERT` sobre `establishments` que crea sucursal "Principal". `CHECK`/FK coherentes. `GRANT` mínimos a `paseo_app` (SELECT/INSERT según necesidad). No tocar `V001`–`V003`.
- [ ] T011 [D2] [US-Infra] `infra/migrations/V005__conversion.sql`: `points_rules` con `scope`, `type`, `priority`, `points_awarded`, `amount_per_tier_cents`, `multiplier_bp`, `max_points_per_purchase`, `min_purchase_cents`, `rounding`. Índices útiles. `GRANT` mínimos a `paseo_app`.
- [ ] T012 [D3] [US-Infra] `infra/migrations/V006__compras_y_ledger.sql`: `purchases`, `points_ledger`, `customer_balances`. Trigger para mantener saldo (`SECURITY DEFINER` aceptado según plan, anotado). `CHECK (balance >= 0)`. Índices únicos: `(establishment_id, idempotency_key)` y `(establishment_id, invoice_ref)` (full unique; `invoice_ref NOT NULL`). `REVOKE UPDATE, DELETE, TRUNCATE` sobre `points_ledger`; `REVOKE UPDATE` sobre `customer_balances`. `GRANT` mínimos a `paseo_app`.
- [ ] T013 [D4] [US-Infra] Verificar migraciones desde cero: levantar BD y aplicar todas hasta V006. No modificar migraciones aplicadas.

### Seed + tooling

- [ ] T014 [S1] [US-Infra] Reemplazar `infra/seed/R__seed_dev.sql`: regla `GLOBAL` BASE activa, comercio demo con sucursal "Principal", owner/cajero/ciente verificados (solo con override `dev`). Idempotente.
- [ ] T015 [S2] [US-Infra] Crear `apps/api/tool/seed_dev_users.dart`: usa `Argon2idPasswordHasher` para crear/asegurar usuarios de demo e imprimir tokens de ticket y QR de prueba (solo dev). Añadir `dev`-only run guard.

### Contrato compartido (paseo_shared)

- [ ] T016 [SH1] [US-Shared] Confirmar `packages/paseo_shared/lib/src/errors/api_error_code.dart` ya contiene: `CUSTOMER_NOT_FOUND`, `DUPLICATE_INVOICE`, `INVALID_QR_TOKEN`, `INVALID_IDENTIFICATION_TICKET` (commits Gate 3). Añadir DTOs de merchant: `packages/paseo_shared/lib/src/merchant/dto.dart` con `IdentifyRequest`, `IdentifyResult`, `PreviewPurchaseRequest`, `PreviewPurchaseResult`, `RegisterPurchaseRequest`, `Purchase`, `Movement`, `MovementPage` usando `MoneyCents`, `CursorPage`. Exportar desde barrel si aplica.
- [ ] T017 [SH2] [US-Shared] Actualizar `packages/paseo_shared/lib/paseo_shared.dart` para exportar merchant DTOs. Verificar snapshot de `api_error_code_test.dart` sigue coherente. `fvm dart test packages/paseo_shared` → 14/14.

### Variables de entorno + docs

- [ ] T018 [DOC1] [US-Infra] Añadir `IDENTIFICATION_SECRET` a `infra/.env.example` (descripción, longitud recomendada, no commitear valor). Documentar en `INFRASTRUCTURE.md` §7 (separado de `JWT_SECRET`). Actualizar `AGENTS.md` solo si necesario para reflejar alcance documentado (verificar coherencia con decisiones ya tomadas).

**Checkpoint F1:** Migraciones aplican desde cero; contrato compartido verde; Redocly lint verde.

## Phase 3: Domain - Loyalty (sin BD)

### Value Objects y entidades

- [ ] T020 [P] [US-D1] `apps/api/lib/domain/loyalty/cents.dart`: VO entero, no negativo, `==`, `hashCode`, `toString`. Operaciones necesarias.
- [ ] T021 [P] [US-D2] `apps/api/lib/domain/loyalty/points.dart`: VO entero >= 0.
- [ ] T022 [P] [US-D3] `apps/api/lib/domain/loyalty/rounding.dart`: enum `floor|round|ceil` con método `apply(double|int)` usando aritmética entera (evitar float). Tabla de casos.
- [ ] T023 [P] [US-D4] `apps/api/lib/domain/loyalty/points_rule.dart`: entidades/typedefs para `PointsRule` (scope/type/priority/params/validity). Immutable.
- [ ] T024 [P] [US-D5] `apps/api/lib/domain/loyalty/loyalty_errors.dart`: `LoyaltyException` mapeando a `ApiErrorCode` (`NO_APPLICABLE_RULE`, `INVALID_IDENTIFICATION_TICKET`, `INVALID_QR_TOKEN`, etc.).

### Lógica de conversión (crítica)

- [ ] T025 [US-D6] [P1] `apps/api/lib/domain/loyalty/rule_resolver.dart`: precedencia `ESTABLISHMENT > CATEGORY > GLOBAL`, desempate por `priority`, como máximo 1 `CAMPAIGN` activa, no acumulación. Devuelve `(base, campaign?)` o lanza `LoyaltyException(NO_APPLICABLE_RULE)`.
- [ ] T026 [US-D7] [P1] `apps/api/lib/domain/loyalty/points_calculator.dart`: orden FR-012: `puntos_base = redondear(net_cents * puntos_otorgados / monto_por_tramo_centavos)`; `puntos = redondear(puntos_base * multiplicador_bp / 10000)`; `min(puntos, tope_puntos_por_compra)` si aplica; `0` si `net_cents < compra_minima`. Todo entero. Comparte lógica con preview/registro.
- [ ] T027 [P] [US-D8] `apps/api/lib/domain/loyalty/purchase.dart`: entidad `Purchase` + invariantes (`net_cents == gross-discount`, no negativos, `invoice_ref` obligatorio). `rule_snapshot` JSON.
- [ ] T028 [P] [US-D9] `apps/api/lib/domain/loyalty/identification.dart`: tipos puros para ticket QR y ticket identificación (claims), sin firma. TTLs (60s QR, 300s ticket) documentados.

### Tests dominio

- [ ] T029 [P] [US-TD1] Tests tabla: `rule_resolver_test.dart` cubre precedencia, desempate, campaña única, no acumulación, sin regla aplicable.
- [ ] T030 [P] [US-TD2] Tests tabla: `points_calculator_test.dart` cubre 3 redondeos, tope, mínima, multiplicador bp, empates `.5`, casos bordes.
- [ ] T031 [P] [US-TD3] Tests: `identification_test.dart` (firma inalterable, TTL 60/300, reloj falso).
- [ ] T032 [P] [US-TD4] Tests: `purchase_test.dart` (invariantes, `invoice_ref` obligatorio).

**Checkpoint D1:** `cd apps/api && fvm dart test test/domain` verde.

## Phase 4: Application - Ports y Use Cases

### Puertos

- [ ] T040 [P] [US-A1] `apps/api/lib/application/merchant/ports.dart`: `EstablishmentRepository` (obtener staff+branch, validar establecimiento), `PointsRuleRepository` (obtener reglas activas por establecimiento/categoría/global), `PurchaseRepository` (find by idempotency_key+estab, insert purchase+ledger con transacción, unique violations), `MovementRepository` (listar con filtro seller por cursor), `TicketSigner` (firma/verifica ticket identificación y QR), `RateLimiter` (por establishment_id).

### Use cases

- [ ] T041 [US-A2] `apps/api/lib/application/merchant/use_cases/identify_customer.dart`: valida QR (firma+edad 60s) o PHONE (+591 8 dígitos); exige `phone_verified`; devuelve ticket firmado + nombre enmascarado; bindea a establishment/branch.
- [ ] T042 [US-A3] `apps/api/lib/application/merchant/use_cases/preview_purchase.dart`: resuelve reglas + calcula con mismo motor; no escribe. Lanza `NO_APPLICABLE_RULE` si no aplica.
- [ ] T043 [US-A4] `apps/api/lib/application/merchant/use_cases/register_purchase.dart`: verifica ticket (5min, mismo estab/branch válido); valida invariantes (`net==gross-disc`, no negativos, invoice_ref no vacío); idempotencia por `(establishment_id,idempotency_key)` (reintento devuelve 200 body original); unique `(establishment_id,invoice_ref)` → `DUPLICATE_INVOICE`; calcula; si `points_credited==0` guarda compra sin ledger; si >0 guarda compra+ledger+CREDIT en transacción + `audit_log`. Nunca escribe saldo directamente.
- [ ] T044 [US-A5] `apps/api/lib/application/merchant/use_cases/list_movements.dart`: cursor `created_at DESC,id DESC`, limit validado, filtro seller para cashier, vacío si comercio ajeno (app layer). Mapea a DTO con nombre enmascarado.

### Fakes y tests aplicación

- [ ] T045 [P] [US-TA1] `apps/api/test/application/merchant/fakes.dart`: fakes para todos los puertos (in-memory) con reloj falso.
- [ ] T046 [P] [US-TA2] `test/application/merchant/identify_customer_test.dart`: escenarios US1 1–6.
- [ ] T047 [P] [US-TA3] `test/application/merchant/preview_purchase_test.dart`: preview vs registro coherente; sin escritura; NO_APPLICABLE_RULE.
- [ ] T048 [P] [US-TA4] `test/application/merchant/register_purchase_test.dart`: US2 1–8 + idempotencia + carrera única invoice_ref.
- [ ] T049 [P] [US-TA5] `test/application/merchant/list_movements_test.dart`: US4 1–5 + aislamiento por seller + comercio ajeno vacío.
- [ ] T050 Ejecutar `cd apps/api && fvm dart test test/application` verde.

**Checkpoint A1:** casos de uso cubiertos con fakes, tests verdes.

## Phase 5: Adapters Out (implementación real)

### Auth/firmas + rate limit

- [ ] T060 [P] [US-O1] `apps/api/lib/adapters/out/auth/identification_signer.dart`: HMAC-SHA256 para ticket identificación (TTL 300s) y QR (TTL 60s), mismo `IDENTIFICATION_SECRET`. Métodos `sign`/`verify` con reloj inyectable. No expone payload legible al cliente indebido.
- [ ] T061 [P] [US-O2] `apps/api/lib/adapters/out/rate_limit/establishment_rate_limiter.dart`: rate limit por `establishment_id` para `preview`/`purchases` (429 `RATE_LIMITED`). Implementación sencilla (in-memory o store compartido según ambiente; tests usan fake).

### Repositorios Postgres

- [ ] T062 [US-O3] `apps/api/lib/adapters/out/postgres/postgres_establishment_repository.dart`: staff+branch, validar branch pertenece a estab, obtener datos para identificar.
- [ ] T063 [US-O4] `apps/api/lib/adapters/out/postgres/postgres_points_rule_repository.dart`: cargar reglas activas (scope estab/cat/global) con filtros de vigencia.
- [ ] T064 [US-O5] `apps/api/lib/adapters/out/postgres/postgres_purchase_repository.dart`: transacción única para insertar purchase+ledger+CREDIT; detectar violación `idempotency_key` único → devolver existente; detectar `(establishment_id,invoice_ref)` único → mapear a `DUPLICATE_INVOICE`. No actualizar saldo (trigger). Insert-only ledger.
- [ ] T065 [US-O6] `apps/api/lib/adapters/out/postgres/postgres_movement_repository.dart`: query con `WHERE establishment_id=?` + seller filter si aplica, orden `created_at DESC,id DESC`, cursor opaco (base64/serializado mínimo), mapeo a DTO con nombre enmascarado.

**Checkpoint O1:** adapters compilan; fakes pueden reemplazarse.

## Phase 6: Adapters In (middleware + rutas)

### Middleware y wiring

- [ ] T070 [US-I1] `apps/api/lib/adapters/in/middleware/merchant_auth_middleware.dart`: exige `aud = paseo-web-merchant`; roles `{merchant_owner,merchant_cashier}`; consulta BD `users.status` y `users.phone_verified` (claims pueden tener 15m desfase). Extrae `establishment_id`, `branch_id` desde claims verificados. Rechaza `customer`/`admin` con 403.
- [ ] T071 [US-I2] `apps/api/lib/adapters/in/merchant_use_cases.dart`: factory/wiring que construye los 4 use cases con adapters out + signer + rate limiter + repos.
- [ ] T072 [US-I3] `apps/api/lib/adapters/in/errors.dart`: extender mapeo para `LoyaltyException` → RFC 9457 con códigos correctos (`NO_APPLICABLE_RULE`, `INVALID_QR_TOKEN`, `INVALID_IDENTIFICATION_TICKET`, `DUPLICATE_INVOICE`, `CUSTOMER_NOT_FOUND`, `PHONE_NOT_VERIFIED`, `PHONE_NOT_SUPPORTED`, `RATE_LIMITED`).

### Rutas Dart Frog

- [ ] T073 [US-R1] `apps/api/routes/merchant/_middleware.dart`: aplica `merchant_auth_middleware` (y logging sin PII). No incluye PII en logs.
- [ ] T074 [US-R2] `apps/api/routes/merchant/customers/identify.dart`: `POST`; valida body contra contrato; llama `identifyCustomer`; retorna `IdentifyResult` (200). Mapea errores.
- [ ] T075 [US-R3] `apps/api/routes/merchant/purchases/preview.dart`: `POST`; valida body; aplica rate limit por establishment; llama `previewPurchase`. Retorna 200/409 según caso.
- [ ] T076 [US-R4] `apps/api/routes/merchant/purchases/index.dart`: `POST`; requiere header `Idempotency-Key`; aplica rate limit; llama `registerPurchase`. Retorna 201 (creación) o 200 (reintento con mismo key). Mapea `DUPLICATE_INVOICE` → 409, `INVALID_IDENTIFICATION_TICKET` → 422.
- [ ] T077 [US-R5] `apps/api/routes/merchant/movements/index.dart`: `GET`; parsea `cursor`, `limit`; llama `listMovements`; retorna `CursorPage<Movement>`. Validación 422 si limit inválido.
- [ ] T078 [US-R6] Actualizar DI/registro si aplica (`AppDependencies`/bootstrap) sin romper identity. Mantener rutas finas (solo validación+mapa).

### Tests API/routes

- [ ] T079 [P] [US-TR1] `test/routes/merchant/identify_test.dart`: auth matriz (customer/admin rechazados 403, aud incorrecta 403), PHONE/QR válidos/inválidos, `PHONE_NOT_VERIFIED`, `CUSTOMER_NOT_FOUND`, `INVALID_QR_TOKEN`.
- [ ] T080 [P] [US-TR2] `test/routes/merchant/preview_test.dart`: coherente con registro, sin escritura, rate limit, `NO_APPLICABLE_RULE`.
- [ ] T081 [P] [US-TR3] `test/routes/merchant/purchase_test.dart`: idempotencia header obligatorio, 201 vs 200, `DUPLICATE_INVOICE`, `INVALID_IDENTIFICATION_TICKET`, invariantes 422.
- [ ] T082 [P] [US-TR4] `test/routes/merchant/movements_test.dart`: cursor/limit, filtro seller, comercio ajeno vacío, PII nunca expuesto.
- [ ] T083 Ejecutar `cd apps/api && fvm dart test test/routes` verde.

**Checkpoint R1:** 4 rutas funcionando con middleware; tests routes verdes.

## Phase 7: Integration + Latencia

### Tests integración (Postgres real, rol paseo_app)

- [ ] T090 [US-TI1] `test/integration/merchant_flow_test.dart`: identify PHONE/QR → purchase → saldo acreditado → movements. End-to-end.
- [ ] T091 [US-TI2] `test/integration/purchase_idempotency_test.dart`: misma Idempotency-Key → 1 compra, 1 ledger, saldo cambia una vez; segundo 200 con cuerpo original.
- [ ] T092 [US-TI3] `test/integration/merchant_isolation_test.dart`: cashier ve solo suyas; owner ve todas; otro comercio vacío. Usa rol real.
- [ ] T093 [US-TI4] `test/integration/purchase_rules_test.dart`: `DUPLICATE_INVOICE` mismo comercio / acepta otro; `NO_APPLICABLE_RULE`; compra bajo mínima sin ledger.
- [ ] T094 [US-TI5] `test/integration/hut02_latency_test.dart`: identify+purchase < 3s total, p95 < 500ms (20 iteraciones). Falla si supera umbrales.
- [ ] T095 [US-TI6] `test/integration/migration_grants_test.dart`: `paseo_app` sin UPDATE/DELETE en `points_ledger`, sin UPDATE en `customer_balances`. Verifica `GRANT` mínimos.

**Checkpoint I1:** integración verde con BD 5433.

## Phase 8: Frontend Web-Merchant

### Dependencias + cliente API

- [ ] T100 [M1] `apps/mobile/pubspec.yaml`: añadir `http: ^1.2.2` y `flutter_riverpod: ^2.6.1`. `fvm flutter pub get`. Commitear `pubspec.lock`.
- [ ] T101 [M2] `apps/mobile/lib/features/merchant/data/merchant_api_client.dart`: cliente REST con `http`, parseo `problem+json` (RFC 9457), manejo de `Idempotency-Key`, envío de ticket, cursor. Usa URLs relativas a API o configurable (coherente con Caddy).
- [ ] T102 [M3] `apps/mobile/lib/features/merchant/application/merchant_session.dart`: estado de sesión comercio (est/branch/role/seller_user_id), providers Riverpod.

### Pantallas + navegación

- [ ] T103 [M4] `apps/mobile/lib/features/merchant/presentation/login_screen.dart`: login con credenciales comercio (usa auth existente) guardando contexto merchant.
- [ ] T104 [M5] `apps/mobile/lib/features/merchant/presentation/identify_screen.dart`: identificar por PHONE (+591 validación) o QR; muestra nombre enmascarado; obtiene ticket.
- [ ] T105 [M6] `apps/mobile/lib/features/merchant/presentation/purchase_screen.dart`: ingresa `gross_cents/discount_cents/net_cents`, `invoice_ref`; llama `preview` → muestra puntos devueltos (mismo valor que registro); llama `register` con `Idempotency-Key` único; muestra resultado. No calcula puntos localmente.
- [ ] T106 [M7] `apps/mobile/lib/features/merchant/presentation/movements_screen.dart`: lista con cursor, infinite scroll al llegar al final; solo datos expuestos (nombre enmascarado, montos, puntos, fecha, sucursal).
- [ ] T107 [M8] `apps/mobile/lib/main_merchant_web.dart`: reemplazar stub por `runApp` real con providers + router para flujo login→identify→purchase→movements.

### Tests Flutter

- [ ] T108 [P] [M9] `apps/mobile/test/features/merchant/merchant_api_mapping_test.dart`: mapeo problem+json a mensajes visibles.
- [ ] T109 [P] [M10] `apps/mobile/test/features/merchant/movements_pagination_test.dart`: pide siguiente página al llegar al final.
- [ ] T110 [P] [M11] `apps/mobile/test/features/merchant/identify_purchase_flow_test.dart`: widget test del flujo muestra nombre enmascarado y puntos devueltos por servidor.
- [ ] T111 `cd apps/mobile && fvm flutter analyze && fvm flutter test` verde.

**Checkpoint M1:** panel web-merchant funcional y testeado.

## Phase 9: Cross-Cutting Verification

- [ ] T120 [V1] Formateo + análisis global: `fvm dart format --set-exit-if-changed . && fvm dart analyze --fatal-warnings`. Flutter: `cd apps/mobile && fvm flutter analyze`.
- [ ] T121 [V2] Tests por capas: `cd apps/api && fvm dart test test/domain test/application test/routes` (todos verdes).
- [ ] T122 [V3] Integración: levantar BD 5433, `cd apps/api && fvm dart test test/integration` (todos verdes).
- [ ] T123 [V4] Flutter tests: `cd apps/mobile && fvm flutter test` verde.
- [ ] T124 [V5] OpenAPI: `npx --yes @redocly/cli@2 lint docs/openapi.yaml` → 0 errores (4 warnings preexistentes OK).
- [ ] T125 [V6] Migraciones desde cero: validar con `migrate info`/aplicación limpia (coincide con CI).
- [ ] T126 [V7] Revisión de seguridad: logs sin PII (tickets/QR/teléfonos/correos), JWT sin PII, grants mínimos verificados, saldo nunca escrito por API, ledger insert-only.
- [ ] T127 [V8] Actualizar `docs/agent-audit.md` si hay cambios relevantes de estado (opcional pero coherente con plantilla).
- [ ] T128 [V9] Verificar SC-001–SC-010: HU-10/11/13/HUT-02 con tests, p95<500ms/HUT-02, cálculo compartido, idempotencia, aislamiento app-layer, contrato antes, sin PII, grants OK, web-merchant muestra mismo valor.

## Phase 10: Finalización

- [ ] T130 [F1] Revisar diff: solo archivos de esta feature. No tocar `V001`–`V003`, `lib/main.dart`, worker, web-admin.
- [ ] T131 [F2] Ejecutar todos los comandos de verificación en orden (V1–V9). Todo verde.
- [ ] T132 [F3] Confirmar rama `feat/003-panel-establecimiento` lista para PR. Incluir referencia a HU-10/HU-11/HU-13/HUT-02 en descripción.

## Dependencies & Execution Order

- Setup gates (T001–T004) antes que todo.
- Migraciones + seed + shared (T010–T018) antes que adapters/routes que dependan de esquema.
- Domain (T020–T032) bloquea Application (T040–T050).
- Application bloquea Adapters Out/In (T060–T083).
- Routes bloquean Integration (T090–T095).
- Shared/DTOs disponibles antes de Flutter (T100–T111).
- Todo antes de Cross-Cutting (T120–T132).

## Notes

- Mantener rutas finas: validación → 1 use case → mapeo RFC 9457.
- Dominio independiente de frameworks/Postgres.
- Dinero y puntos enteros. Nunca float.
- Escrituras críticas idempotentes + audit_log.
- Contrato en `docs/openapi.yaml` ya existe (Gate 3). Fragmento solo para trazabilidad.
- MVP sin RLS (deuda documentada). Aislamiento por `establishment_id` + seller en app layer.
- `invoice_ref` obligatorio; full unique `(establishment_id,invoice_ref)`.
- `SECURITY DEFINER` solo para trigger de saldo (aceptado; grant mínimo preservado).
- Preview y registro comparten `PointsCalculator` + `RuleResolver`.
- Logs sin PII. JWT sin PII.
- Frontend web-merchant **único** modificado (`main_merchant_web.dart` + features/merchant). No tocar `main.dart`, `web-admin`, worker.
- Seed solo con `dev`; users con Argon2id.
- HUT-02 medido con test de integración (no assertion trivial).