# [CHECKLIST TYPE] Checklist: [FEATURE NAME]

**Purpose**: [Requirements/security/contract/database quality gate]
**Created**: [DATE]
**Feature**: `specs/[###-feature-name]/spec.md`
**Authority**: `AGENTS.md`

**Note**: This checklist is reviewer-owned. Mark `[x]` only when the criterion is confirmed. A checked item does not mean implementation is complete.

## Requirements Quality

- [ ] CHK001 User stories are independently testable and prioritized
- [ ] CHK002 Acceptance scenarios define observable outcomes
- [ ] CHK003 Edge, conflict, permission, and retry cases are explicit
- [ ] CHK004 `OPEN_DECISIONS` are not resolved inside the spec/plan/tasks

## Contract and API

- [ ] CHK010 Every endpoint or response change is declared in `docs/openapi.yaml` first
- [ ] CHK011 Error responses use RFC 9457 `application/problem+json` and stable `code`
- [ ] CHK012 Critical writes declare `Idempotency-Key` and expected replay behavior

## Architecture

- [ ] CHK020 Backend preserves `adapters → application → domain`
- [ ] CHK021 Routes remain thin and contain no business rules
- [ ] CHK022 Flutter changes stay within `features/<feature>/{presentation,application,data}`
- [ ] CHK023 `packages/paseo_shared` contains contracts only, not backend domain logic

## Database and Integrity

- [ ] CHK030 New schema work uses a new immutable Flyway migration
- [ ] CHK031 New tables include RLS, policies, minimum `GRANT`, and isolation tests
- [ ] CHK032 Ledger/saldo rules preserve append-only points movement and non-negative balances
- [ ] CHK033 Critical writes are transactional and audited

## Security and Privacy

- [ ] CHK040 JWT claims and logs contain no personal data
- [ ] CHK041 Web cookies/audiences remain separated by application
- [ ] CHK042 Uploads are not exposed publicly and access is authorized/audited
- [ ] CHK043 Secrets stay out of the repository and `.env` remains ignored

## Verification

- [ ] CHK050 Required tests exist and fail before implementation
- [ ] CHK051 Formatting, analysis, unit tests, integration tests, and contract checks pass
- [ ] CHK052 Database changes have clean migration validation and RLS isolation tests
- [ ] CHK053 Result is traceable to spec, plan, task, implementation, test, and PR
