# Specs — Paseo Points

`specs/` contiene las especificaciones de features siguiendo el flujo SDD del repositorio: constitución (`AGENTS.md` y `.specify/memory/constitution.md`) → spec → plan → tasks → implementación → pruebas → revisión.

## Convención

Cada feature vive en su propio directorio:

```text
specs/<feature>/
├── spec.md              # Requerido; qué construir y por qué
├── plan.md              # Requerido antes de implementar; cómo construirlo
├── tasks.md             # Requerido para ejecutar por tareas
├── research.md          # Opcional; decisiones investigadas
├── data-model.md        # Opcional; entidades, invariantes, migraciones previstas
├── quickstart.md        # Opcional; cómo demostrar/verificar la feature
└── contracts/           # Opcional; extractos o artefactos derivados del contrato
```

Usa las plantillas de `.specify/templates/`.

## Gates obligatorios

1. **Spec aprobada por humano** antes del plan.
2. **Plan aprobado por humano** antes de implementar.
3. `docs/openapi.yaml` se actualiza **antes** de cualquier endpoint.
4. Las decisiones marcadas en `AGENTS.md` como abiertas permanecen en `OPEN_DECISIONS` hasta que el humano las resuelva explícitamente.
5. Ningún cambio de comportamiento se implementa sin spec y prueba.
6. Si hay cambio de esquema, la migración incluye RLS, políticas, `GRANT` mínimos y prueba de aislamiento.
7. Las escrituras críticas usan `Idempotency-Key` y `audit_log` cuando el contrato o `AGENTS.md` lo exigen.
8. La definición de terminado de `AGENTS.md` §16 se cumple antes de dar una feature por completa.

## Trazabilidad mínima

Cada PR debe poder enlazar: requisito/HU → `spec.md` → `plan.md` → `tasks.md` → cambios → pruebas → CI.

## Estado inicial

Este directorio fue creado como fundación SDD. Todavía no contiene specs de features; crear la primera spec antes de implementar comportamiento.
