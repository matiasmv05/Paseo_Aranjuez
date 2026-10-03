# Feature Specification: [FEATURE NAME]

**Feature**: `[###-feature-name]`
**Branch**: `[feat/<id-historia>-descripcion]`
**Created**: [DATE]
**Status**: Draft | Review | Approved | Blocked
**Input**: User description: "$ARGUMENTS"
**Authority**: `AGENTS.md` remains the governing repository policy.

## Scope

- **Goal**: [One sentence describing the user-visible outcome]
- **Non-goals**: [What is explicitly out of scope]
- **Actor(s)**: `customer` | `merchant_owner` | `merchant_cashier` | `admin` | `system`
- **Applications affected**: `mobile` | `web-merchant` | `web-admin` | `api` | `worker`
- **OPEN_DECISIONS**: [List open decisions this feature depends on; do not resolve them here]

## User Scenarios & Testing *(mandatory)*

### User Story 1 - [Brief Title] (Priority: P1)

[Plain-language user journey]

**Why this priority**: [Reason]

**Independent Test**: [How this story can be tested and demonstrated alone]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]
2. **Given** [boundary/error state], **When** [action], **Then** [expected stable `code`/outcome]

[Add more independently testable stories as needed]

### Edge Cases

- [Boundary condition and expected result]
- [Error or conflict and expected `problem+json` code]
- [Permission/RLS isolation case]
- [Idempotency/retry case, if it is a critical write]

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST [specific capability]
- **FR-002**: System MUST [validation or authorization rule]
- **FR-003**: When API behavior changes, `docs/openapi.yaml` MUST be updated before routes are implemented
- **FR-004**: Critical writes MUST use `Idempotency-Key` and `audit_log` when required by `AGENTS.md`

### Security, Privacy, and Integrity Requirements

- **SEC-001**: JWT claims MUST NOT contain personal data
- **SEC-002**: New data MUST define RLS policies, `GRANT` rules, and isolation tests when it introduces tables or access paths
- **SEC-003**: Uploads MUST NOT be exposed publicly; access goes through the API with authorization and audit when applicable
- **SEC-004**: Logs MUST NOT contain passwords, OTPs, tokens, full phone numbers, or full email addresses

### Key Entities *(include if data is involved)*

- **[Entity]**: [Meaning, invariants, relationships]
- **[Ledger movement]**: [Only if points move; define `points_ledger` movement type and reversibility]

## API and Contract Impact

- [ ] No API impact
- [ ] `docs/openapi.yaml` update required before implementation
- [ ] New/changed RFC 9457 error code required
- [ ] Cursor pagination, UTC timestamps, or integer-cent amounts affected

## Database Impact

- [ ] No database impact
- [ ] New Flyway migration required: `infra/migrations/V[NNN]__*.sql`
- [ ] RLS/policies/`GRANT` required in the same change
- [ ] RLS isolation test required
- [ ] Migration immutability check affected

## Success Criteria *(mandatory)*

- **SC-001**: [Measurable outcome]
- **SC-002**: [Test/contract/migration outcome]
- **SC-003**: [Security/privacy outcome]

## Assumptions

- [Documented assumption]
- **OPEN**: [Any unresolved decision that blocks implementation]

## Definition of Done

- [ ] Spec reviewed and approved by a human
- [ ] Plan written and approved
- [ ] Tasks written and traceable
- [ ] Contract updated before implementation, if API changes
- [ ] Tests written before behavior changes
- [ ] Security, RLS, audit, and idempotency rules checked when applicable
