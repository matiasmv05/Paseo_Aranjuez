# Implementation Tasks: 005-canjes-gamificacion

**Feature**: `005-canjes-gamificacion`
**Branch**: `persona5real`
**Date**: 2026-10-04
**Spec**: `specs/005-canjes-gamificacion/spec.md`
**Plan**: `specs/005-canjes-gamificacion/plan.md`

## Task Checklist

### Phase 1: Contratos y DTOs Compartidos
- [x] **T001**: Añadir especificación OpenAPI en `docs/openapi.yaml` para:
  - `POST /customer/redemptions` (HU-07)
  - `POST /merchant/redemptions/validate` (HU-12)
  - `POST /merchant/redemptions/complete` (HU-12)
  - `POST /merchant/promotions/propose` (HU-14)
- [x] **T002**: Crear DTOs de canjes y promociones en `packages/paseo_shared/lib/src/redemptions/`.
- [x] **T003**: Exportar nuevos DTOs en `packages/paseo_shared/lib/paseo_shared.dart`.

### Phase 2: Estado y Mock Engine Reactivo
- [x] **T004**: Extender `MockData` en `apps/mobile/lib/data/mock/mock_data.dart` con soporte de:
  - Registro y consulta de cupones de canje (`MockRedemptionCoupon`, estados `issued`, `used`, `expired`).
  - Débito transaccional de saldo al confirmar canje.
  - Modelo de niveles de fidelización (`CustomerTier`: Bronce, Plata, Oro, Platinum) con cálculo dinámico según saldo y beneficios asociados.
  - Modelo y lista de notificaciones activas (`MockNotification`).
  - Código y sistema de referidos (`MockReferral`).

### Phase 3: Componentes de Gamificación y Notificaciones
- [x] **T005**: Crear átomo `PaseoTierBadge` en `apps/mobile/lib/design_system/atoms/paseo_tier_badge.dart`.
- [x] **T006**: Crear molécula `CustomerTierCard` en `apps/mobile/lib/design_system/molecules/customer_tier_card.dart` con barra de progreso y beneficios por nivel.
- [x] **T007**: Crear organismo `NotificationsSheet` en `apps/mobile/lib/design_system/organisms/notifications_sheet.dart` con alertas interactivas.
- [x] **T008**: Crear molécula `ReferralCard` en `apps/mobile/lib/design_system/molecules/referral_card.dart` para bonos de referidos.

### Phase 4: Integración en Frontend Cliente
- [x] **T009**: Integrar `CustomerTierCard` y `ReferralCard` en `apps/mobile/lib/pages/profile_page.dart`.
- [x] **T010**: Conectar campana de notificaciones de `home_dashboard_page.dart` con `NotificationsSheet`.
- [x] **T011**: Actualizar `benefit_detail_page.dart` para que el canje debite el saldo y genere un cupón rastreable en `MockData`.

### Phase 5: Flujo de Validación de Comercio POS (HU-12) y Propuesta de Promociones (HU-14)
- [x] **T012**: Crear organismo `MerchantRedemptionValidator` en `apps/mobile/lib/design_system/organisms/merchant_redemption_validator.dart` (validar cupón por código/QR, mostrar datos del cliente/beneficio y marcar como usado).
- [x] **T013**: Crear organismo `MerchantPromoProposalSheet` en `apps/mobile/lib/design_system/organisms/merchant_promo_proposal_sheet.dart` (proponer nueva promoción para aprobación del admin).
- [x] **T014**: Añadir botones de acceso a "Validar Cupón de Canje" y "Proponer Promoción" en `apps/mobile/lib/pages/merchant_pos_page.dart`.

### Phase 6: Pruebas y Validación Final
- [x] **T015**: Crear prueba unitaria y de widgets `apps/mobile/test/redemptions_gamification_test.dart` validando el ciclo completo de canje (generar -> validar en POS -> revalidación rechazada).
- [x] **T016**: Actualizar `customer_ui_test.dart` y `merchant_pos_ui_test.dart` para verificar el centro de notificaciones, la barra de canjes en POS y la tarjeta de nivel.
- [x] **T017**: Ejecutar `fvm dart format --set-exit-if-changed .`, `fvm dart analyze apps/mobile` y `fvm flutter test`.
