# Feature Specification: 005-canjes-gamificacion

**Feature**: `005-canjes-gamificacion`
**Branch**: `persona5real`
**Created**: 2026-10-04
**Status**: Draft
**Input**: Persona 5 — Canjes, IA/Gamificación e Integraciones (HU-07, HU-12, HU-14, HU-22, HU-23, HU-24, HU-25, HU-26, HUT-05, HUT-07, HUT-08)
**Authority**: `AGENTS.md` remains the governing repository policy.

## Scope

- **Goal**: Implementar el ciclo completo y autoritativo de canjes de recompensas (generación de código de un solo uso por el cliente y validación/entrega por el comercio en terminal POS), junto con el sistema de gamificación ("wow factor": niveles de lealtad Bronce/Plata/Oro/Platinum, centro de notificaciones de puntos y promociones, bonos especiales de puntos dobles y referidos), registro de auditoría (`audit_log`) y contratos REST OpenAPI documentados.
- **Non-goals**:
  - `HU-26` (Promociones recomendadas con IA): Excluida formalmente de esta versión según MoSCoW ("Won't esta versión").
  - Modificación o liquidación financiera de transacciones bancarias directas o pasarelas de pago no contempladas en el MVP.
  - Generación de balances negativos en la cuenta del cliente (invariante innegociable `balance >= 0`).
- **Actor(s)**: `customer` | `merchant_owner` | `merchant_cashier` | `admin` | `system`
- **Applications affected**: `mobile` | `web-merchant` | `web-admin` | `api` | `packages/paseo_shared`
- **OPEN_DECISIONS**: Ninguna decisión bloqueante abierta; el canje es un movimiento de débito `REDEEM` y la validación en caja actualiza el estado del cupón a `USED` en una sola operación transaccional.

---

## User Scenarios & Testing (mandatory)

### User Story 1 - HU-07: Canjear una recompensa (Priority: Must)

Como cliente con saldo acumulado suficiente,
quiero canjear una recompensa del catálogo de un comercio participante,
para obtener un cupón con código de un solo uso y disfrutar de mi beneficio.

**Why this priority**: Es el núcleo de valor que percibe el usuario final en la plataforma de fidelización.
**Independent Test**: Desde el catálogo de beneficios ([benefits_page.dart](file:///c:/Users/HP%20NOTEBOOK/Downloads/Redesssss/Paseo_Aranjuez/apps/mobile/lib/pages/benefits_page.dart)), seleccionar un beneficio, pulsar "Canjear por 500 puntos", confirmar en el diálogo y recibir el código `PA-483921`.

**Acceptance Scenarios**:
1. **Given** un cliente con saldo de 2.450 puntos y una recompensa de 500 puntos,
   **When** solicita el canje y confirma en el diálogo,
   **Then** se descuentan 500 puntos de su saldo, se crea el cupón con estado `ISSUED`, código único (ej. `PA-483921`) con expiración (15 minutos o fin de día) y se registra en `audit_log`.
2. **Given** un cliente con saldo menor al costo en puntos de la recompensa (ej. saldo 200 pts para premio de 500 pts),
   **When** intenta canjear,
   **Then** el sistema impide el canje con código de error RFC 9457 `INSUFFICIENT_POINTS` (409) y no descuenta puntos.

---

### User Story 2 - HU-12: Validar código de canje en el comercio (Priority: Must)

Como cajero o dueño de un comercio,
quiero ingresar o escanear el código de canje presentado por el cliente,
para verificar su validez y entregar la recompensa de forma segura.

**Why this priority**: Cierra el ciclo de canje evitando fraudes o reutilizaciones indebidas.
**Independent Test**: En el terminal de caja ([merchant_pos_page.dart](file:///c:/Users/HP%20NOTEBOOK/Downloads/Redesssss/Paseo_Aranjuez/apps/mobile/lib/pages/merchant_pos_page.dart)), abrir la acción "Validar Cupón de Canje", ingresar `PA-483921`, consultar el detalle y confirmar entrega.

**Acceptance Scenarios**:
1. **Given** un cupón con estado `ISSUED` correspondiente al comercio actual,
   **When** el personal introduce el código y presiona "Validar y Entregar",
   **Then** el sistema muestra el nombre enmascarado del cliente, el beneficio, y actualiza el estado a `USED` registrando fecha/hora, `merchant_user_id` y `audit_log`.
2. **Given** un código ya usado previamente (`USED`) o inexistente,
   **When** el comercio intenta validarlo,
   **Then** el sistema rechaza la operación con `REDEMPTION_ALREADY_USED` (409) o `REDEMPTION_NOT_FOUND` (404), alertando al cajero.

---

### User Story 3 - HU-22: Niveles de Cliente / Gamificación (Priority: Could / Feature WOW)

Como cliente de Paseo Points,
quiero visualizar mi nivel de lealtad (Bronce, Plata, Oro, Platinum) y mi progreso,
para acceder a beneficios exclusivos y motivarme a acumular más puntos en Paseo Aranjuez.

**Why this priority**: Aumenta sustancialmente el engagement y la percepción de valor premium exigida por el jurado.
**Independent Test**: En la pantalla de perfil ([profile_page.dart](file:///c:/Users/HP%20NOTEBOOK/Downloads/Redesssss/Paseo_Aranjuez/apps/mobile/lib/pages/profile_page.dart)) o dashboard, visualizar la tarjeta del nivel actual (ej. "Nivel Oro • 2.450 / 3.000 pts para Platinum"), con multiplicador de acumulación y desglose de ventajas por nivel.

**Acceptance Scenarios**:
1. **Given** un cliente con 2.450 puntos acumulados,
   **When** consulta su perfil o dashboard,
   **Then** el sistema le asigna automáticamente la insignia y nivel `Oro` (1.500 - 2.999 pts), mostrando la barra de progreso (81%) hacia `Platinum` (3.000+ pts) y sus beneficios activos (ej. 1.2x en puntos).

---

### User Story 4 - HU-23, HU-24, HU-25: Notificaciones, Bonos y Referidos (Priority: Could)

Como cliente,
quiero recibir notificaciones de acumulación/promociones y participar en bonos de puntos dobles y referidos,
para maximizar el rendimiento de mis visitas a Paseo Aranjuez.

**Why this priority**: Fortalece la retención y la viralidad orgánica de la aplicación.
**Independent Test**: Abrir la campana de notificaciones del dashboard para ver alertas de puntos acreditados, el banner de puntos dobles de fin de semana, y la vista de "Invitar Amigos" con código personal de referido.

---

### User Story 5 - HU-14: Crear promociones como establecimiento (Priority: Could)

Como dueño de un comercio,
quiero proponer una nueva promoción desde mi portal de comercio,
para que el administrador la apruebe y se publique en el catálogo oficial de Paseo Points.

**Why this priority**: Permite dinamismo comercial en los locales de Paseo Aranjuez.
**Acceptance Scenarios**:
1. **Given** un usuario autenticado como `merchant_owner`,
   **When** envía título, descripción, fechas y beneficio de una promoción,
   **Then** se crea en estado `PENDING_APPROVAL` para revisión por parte del administrador.

---

## Requirements (mandatory)

### Functional Requirements

- **FR-001**: El backend DEBE exponer el endpoint `POST /customer/redemptions` para generar cupones con código único alfanumérico legible (ej. `PA-XXXXXX`), deduciendo el saldo de forma transaccional.
- **FR-002**: El backend DEBE exponer el endpoint `POST /merchant/redemptions/validate` y `POST /merchant/redemptions/complete` para que el personal verifique y marque como consumido el beneficio.
- **FR-003**: Todo cupón de canje DEBE tener estados estrictos: `ISSUED` (emitido, listo para canjear), `USED` (validado y consumido) y `EXPIRED` (vencido).
- **FR-004**: El sistema DEBE clasificar automáticamente a los clientes en 4 niveles de fidelización:
  - `Bronce`: 0 a 499 puntos.
  - `Plata`: 500 a 1.499 puntos (acceso a descuentos de temporada).
  - `Oro`: 1.500 a 2.999 puntos (multiplicador 1.2x en compras).
  - `Platinum`: 3.000+ puntos (multiplicador 1.5x, fila preferencial y eventos VIP).
- **FR-005**: Todo canje y validación DEBE emitir una entrada inmediata en `audit_log` con `user_id`, `establishment_id`, `action` y metadatos.
- **FR-006**: La documentación OpenAPI en `docs/openapi.yaml` DEBE registrar las operaciones de canjes, promociones y gamificación.

### Security, Privacy, and Integrity Requirements

- **SEC-001**: Los tokens y códigos de canje DEBEN ser de uso único, con entropía criptográficamente segura.
- **SEC-002**: El comercio solo puede validar cupones emitidos para su propio `establishment_id`.
- **SEC-003**: No exponer datos personales del cliente al comercio salvo el nombre de pila enmascarado.

---

## Success Criteria (mandatory)

- **SC-001**: Ciclo completo de canje operable de punta a punta (Cliente genera cupón -> Comercio valida código en POS -> Cupón queda invalidado para reuso).
- **SC-002**: Experiencia de gamificación y niveles integrada de forma visual y responsiva en las pantallas del cliente móvil.
- **SC-003**: 100% de cumplimiento en pruebas unitarias y de interfaz (`flutter test`).
- **SC-004**: Cero advertencias y errores en `dart analyze`.
