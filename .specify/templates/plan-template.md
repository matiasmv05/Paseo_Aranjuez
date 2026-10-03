# Implementation Plan: [FEATURE]

**Branch**: `[feat/<id-historia>-descripcion]` | **Date**: [DATE] | **Spec**: `specs/[###-feature-name]/spec.md`

**Input**: Feature specification from `specs/[###-feature-name]/spec.md`

**Authority**: `AGENTS.md` and `.specify/memory/constitution.md` govern this plan.

## Summary

[Primary requirement and technical approach in 2–3 sentences. Do not resolve `OPEN_DECISIONS`.]

## Technical Context

**Language/Version**: Dart/Flutter via FVM (`fvm dart`, `fvm flutter`) or NEEDS CLARIFICATION
**Primary Dependencies**: [Existing packages only unless the plan explicitly adds a dependency]
**Storage**: PostgreSQL via Flyway when applicable; otherwise N/A
**Testing**: `dart test`, integration tests against PostgreSQL, Flutter tests, API contract tests
**Target Platform**: API/worker/mobile/web-merchant/web-admin
**Constraints**: server authoritative, integer cents/points, RLS, auditability, idempotency
**Scale/Scope**: [Expected data/feature scope]

## Constitution Check

*GATE: Must pass before implementation and again before review.*

- [ ] `docs/openapi.yaml` updated before any endpoint implementation
- [ ] Backend preserves `adapters → application → domain`
- [ ] No business rules in routes or Flutter presentation/data layers
- [ ] New tables include RLS, policies, minimum `GRANT`, and isolation tests
- [ ] Critical writes include `Idempotency-Key` and `audit_log`
- [ ] JWT claims contain no personal data
- [ ] Uploads are served only by the API with authorization and audit, when applicable
- [ ] `OPEN_DECISIONS` remain open or have explicit human approval recorded in the spec

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── spec.md
├── plan.md
├── research.md          # optional
├── data-model.md        # optional
├── contracts/           # optional; mirror relevant docs/openapi.yaml changes
└── tasks.md
```

### Source Code (repository root)

```text
apps/
├── api/
│   ├── bin/{server,worker}.dart
│   └── lib/{domain,application,adapters/{in,out}}/
└── mobile/
    └── lib/features/<feature>/{presentation,application,data}/
packages/
└── paseo_shared/          # DTOs, enums, contract errors only
```

**Structure Decision**: [Concrete paths used by this feature. Delete unused paths.]

## Data / Contract / Infrastructure Impact

- **API contract**: [None or exact `docs/openapi.yaml` operations]
- **Database**: [None or migration/version, RLS, grants, indexes, constraints]
- **Infrastructure**: [None or Compose/Caddy/env changes; `.env.example` required for new variables]
- **Security**: [Authn/authz, cookies/audiences, uploads, rate limits, logging]
- **Notifications/jobs**: [None or worker/use-case impact]

## Test Strategy

- **Domain tests**: [Table-based cases, if any]
- **Integration tests**: [PostgreSQL/RLS/idempotency/concurrency cases, if any]
- **API tests**: [Contract, authorization matrix, RFC 9457 errors, uploads]
- **Flutter tests**: [State, routing/guards, critical widgets]
- **Verification commands**: [Exact repository commands]

## Complexity Tracking

> Fill only when the Constitution Check requires justification.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [Rule] | [Need] | [Reason] |

## Implementation Sequence

[High-level ordered tasks; the executable detail belongs in `tasks.md`.]

## Rollback / Forward Fix

- Migrations only move forward; an error is fixed by a new migration.
- API rollback must remain compatible with migrations already applied.
