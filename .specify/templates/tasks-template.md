---
description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `specs/[###-feature-name]/`
**Prerequisites**: approved `spec.md`, approved `plan.md`, and any required `research.md`, `data-model.md`, `contracts/`
**Authority**: `AGENTS.md`; resolve no `OPEN_DECISIONS` without explicit human approval.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story code (US1, US2, ...)
- Include exact file paths and verification commands

## Phase 1: Setup Gates

- [ ] T001 Confirm spec and plan are approved and `OPEN_DECISIONS` are unchanged or explicitly resolved by the human
- [ ] T002 Create/update `docs/openapi.yaml` before implementing any endpoint
- [ ] T003 Create/update feature docs under `specs/[###-feature]/`

## Phase 2: Foundational Blocking Tasks

- [ ] T004 If schema changes: create a new immutable `infra/migrations/V###__*.sql` with RLS, policies, minimum `GRANT`, and isolation tests
- [ ] T005 If persistence changes: add integration tests against PostgreSQL using the application role
- [ ] T006 If critical writes change: add `Idempotency-Key`, audit logging, and conflict behavior tests
- [ ] T007 If API errors change: add RFC 9457 `application/problem+json` responses with stable `code`
- [ ] T008 If auth changes: validate role/audience/claims and no PII in JWT

**Checkpoint**: Foundation gates pass before any user-story implementation.

## Phase 3: User Story 1 - [Title] (Priority: P1)

**Goal**: [Story outcome]
**Independent Test**: [How this story is verified alone]

### Tests for User Story 1

- [ ] T010 [P] [US1] Add failing domain/use-case test in `apps/api/test/...`
- [ ] T011 [P] [US1] Add failing contract/API/RLS test when applicable in `apps/api/test/...`
- [ ] T012 [P] [US1] Add failing Flutter state/widget/guard test when applicable in `apps/mobile/test/...`

### Implementation for User Story 1

- [ ] T013 [US1] Implement the smallest domain/application change in the approved layer
- [ ] T014 [US1] Implement thin adapter/route or Flutter data/presentation integration
- [ ] T015 [US1] Run the story's tests and required repository verification commands

**Checkpoint**: User Story 1 works independently and is testable.

## Phase N: Cross-Cutting Verification

- [ ] T090 Run formatting, static analysis, unit tests, integration tests, API contract validation, and architecture checks available in the repository
- [ ] T091 If database behavior changed: run migrations from scratch and RLS isolation tests
- [ ] T092 If security/auth/uploads changed: run security-focused verification and secret scanning
- [ ] T093 Update `docs/agent-audit.md` or the feature docs when repository state changes

## Dependencies & Execution Order

- Setup gates block all implementation tasks.
- Database migrations and contract updates precede implementation that depends on them.
- Tests precede behavior changes.
- Tasks marked [P] touch different files and have no hidden dependency.

## Notes

- Keep routes thin: validation → one use case → result mapping.
- Keep backend domain independent of frameworks and PostgreSQL.
- Money and points use integer arithmetic only.
- Critical writes are idempotent and audited.
- Affected APIs must exist in `docs/openapi.yaml` before implementation.
- Use stable RFC 9457 error codes from the contract.
