# Implementation Plan: 005-canjes-gamificacion

**Branch**: `persona5real` | **Date**: 2026-10-04 | **Spec**: `specs/005-canjes-gamificacion/spec.md`

**Input**: Feature specification from `specs/005-canjes-gamificacion/spec.md`

**Authority**: `AGENTS.md` and `.specify/memory/constitution.md` govern this plan.

## Summary

Implementación integral de la Persona 5 centrada en:
1. El ciclo completo de canje: generación de cupón en la app cliente (HU-07) y validación/consumo en el terminal POS de comercio (HU-12).
2. Gamificación interactiva: niveles de lealtad (Bronce, Plata, Oro, Platinum - HU-22), centro de notificaciones de puntos y promociones (HU-23), bono de fechas especiales (HU-24) y programa de referidos (HU-25).
3. Propuesta de promociones para comercios (HU-14).
4. DTOs compartidos en `packages/paseo_shared`, actualización del contrato REST OpenAPI (`docs/openapi.yaml`) y enlace directo con las pantallas existentes de Flutter.

## Technical Context

**Language/Version**: Dart 3.13 / Flutter 3.47.6 via FVM (`fvm dart`, `fvm flutter`)
**Primary Dependencies**: `flutter`, `paseo_shared`
**Storage**: Mock transaccional reactivo en cliente (desacoplado para posterior persistencia API) y modelos de entidad inmutables
**Testing**: `flutter test` en `apps/mobile/test` y pruebas unitarias de contratos en `packages/paseo_shared`
**Target Platform**: Android/iOS (Mobile), Web POS (Comercio), Web Admin
**Constraints**: Servidor como autoridad final, saldo `balance >= 0`, códigos de canje de uso único, no duplicación de estilos.

## Constitution Check

- [x] Contratos OpenAPI documentados en `docs/openapi.yaml`
- [x] Reglas hexagonales respetadas (Atoms -> Molecules -> Organisms -> Templates -> Pages en Flutter; DTOs en `paseo_shared`)
- [x] Sin datos personales sensibles expuestos en el código de canje ni en la vista del cajero
- [x] Código compilable y verificado con `dart analyze` y `dart format`

## Project Structure

### Documentation (this feature)

```text
specs/005-canjes-gamificacion/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code Impact

```text
packages/paseo_shared/
└── lib/src/
    └── redemptions/          # DTOs de canjes (RedemptionRequest, RedemptionResponse, ValidationResult)
apps/mobile/
├── lib/
│   ├── data/mock/mock_data.dart                      # Estado mock reactivo de canjes y niveles
│   ├── design_system/
│   │   ├── atoms/
│   │   │   └── paseo_tier_badge.dart                 # Insignia de nivel (Oro, Plata, etc.)
│   │   ├── molecules/
│   │   │   ├── customer_tier_card.dart               # Tarjeta interactiva de nivel y progreso
│   │   │   ├── notification_tile.dart                # Ítem de notificación
│   │   │   └── referral_card.dart                    # Tarjeta de "Invitar amigos"
│   │   └── organisms/
│   │       ├── merchant_redemption_validator.dart    # Modal de validación de cupones para el comercio POS
│   │       ├── merchant_promo_proposal_sheet.dart    # Formulario para proponer promociones (HU-14)
│   │       └── notifications_sheet.dart              # Centro de notificaciones interactivo
│   └── pages/
│       ├── home_dashboard_page.dart                  # Integración de campana de notificaciones y nivel
│       ├── profile_page.dart                         # Integración de tarjeta de nivel de lealtad y referidos
│       ├── benefit_detail_page.dart                  # Integración del canje reactivo con saldo dinámico
│       └── merchant_pos_page.dart                    # Botón y modal de validación de canje (HU-12)
└── test/
    ├── customer_ui_test.dart                         # Cobertura de gamificación y notificaciones
    └── merchant_redemption_test.dart                 # Cobertura del ciclo de validación de cupón
docs/
└── openapi.yaml                                      # Endpoints de /customer/redemptions y /merchant/redemptions
```

## Implementation Sequence

1. **Contratos y DTOs**: Definir endpoints en `docs/openapi.yaml` y modelos DTO en `packages/paseo_shared`.
2. **Motor de Datos Reactivo**: Extender `MockData` para permitir débitos reales de puntos al canjear y transiciones de cupones (`ISSUED` -> `USED`).
3. **Flujo de Comercio (HU-12)**: Implementar `MerchantRedemptionValidator` en `merchant_pos_page.dart`.
4. **Gamificación y Niveles (HU-22)**: Implementar `PaseoTierBadge` y `CustomerTierCard` en `profile_page.dart` y `home_dashboard_page.dart`.
5. **Notificaciones y Bonos (HU-23, HU-24, HU-25)**: Centro de notificaciones y tarjeta de referidos.
6. **Propuesta de Promociones (HU-14)**: Modal para el comercio en `merchant_pos_page.dart`.
7. **Verificación y Pruebas**: Formato, análisis y ejecución de `flutter test`.
