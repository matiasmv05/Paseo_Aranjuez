# Foundation Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the Foundation phase by updating the agent audit, finishing Identity (routes, Argon2id, SMTP, rate-limit, worker), creating Flutter web entry points, and running the full verification pipeline.

**Architecture:** Four workstreams executed in sequence with verification gates. Backend work (Identity) must complete before validation. Flutter web entry points are independent but needed for full CI. Agent audit documents the final state.

**Tech Stack:** Dart 3.13, Dart Frog 1.2.6, Flutter 3.47.6, PostgreSQL 18, Flyway 13.9.0, `cryptography` 2.9.0 (Argon2id), `mailer` 7.2.0 (SMTP), `very_good_analysis` 11.

**Spec:** `AGENTS.md` (governing rules), `specs/001-identidad/spec.md`, `specs/001-identidad/plan.md`, `specs/001-identidad/tasks.md`, `INFRASTRUCTURE.md`, `docs/openapi.yaml`.

## Global Constraints

- Hexagonal boundaries: `adapters → application → domain` (no reverse deps)
- Routes: thin — validate → one use case → map to RFC 9457
- No business logic in routes
- `paseo_shared`: DTOs/enums/errors only, no domain logic
- Money in integer cents; points in integer
- JWT: ≤15 min, claims fixed, no PII, audience per app
- Argon2id via `cryptography` 2.9.0 (PHC, OWASP m=19MiB, t=2, p=1) in Isolate
- SMTP: Gmail/Google Workspace via own `SmtpEmailSender` (no Mailpit)
- SMS: console in dev, provider TBD (port `OtpSender`)
- Idempotency-Key + audit_log on critical writes
- Migrations immutable (V###); V002 no RLS (MVP)
- RLS = blocked debt; isolation via middleware
- DB_DEV_PORT=5433 for integration tests
- Unit tests: `fvm dart test test/domain test/application test/routes`
- CI: format → analyze → unit tests → openapi → migrations from zero → RLS tests (when exist) → integration

## Review Focus

1. **RLS reintroduction path**: If RLS is re-enabled, all V002 tables need `ENABLE RLS` + policies + isolation tests in `infra/tests/rls/`. Test: CI runs `infra/tests/rls/` with `paseo_app`.
2. **Cookie isolation between webs**: Merchant and Admin webs must use distinct cookie names (`__Secure-rt_merchant`, `__Secure-rt_admin`) and distinct `aud` values. Test: OpenAPI documents both; login sets correct cookie.
3. **Argon2id PHC interoperability**: Hash format must verify against reference C implementation. Test: known PHC vector in `Argon2idPasswordHasher` tests.
4. **SMTP credential handling**: `SMTP_PASSWORD` = Google App Password, never account password. Test: `SmtpEmailSender` reads from env, no hardcoded values.
5. **Integration test DB port**: Local integration tests fail if `DB_DEV_PORT=5433` not set in `infra/.env` (dev compose defaults to 5432). Test: CI explicitly sets 5433; docs/commands reflect this.

---

### Task 1: Update `docs/agent-audit.md` to Current Real State

**Files:**
- Modify: `docs/agent-audit.md`

**Interfaces:**
- Consumes: Current repo state (git, code, infra, CI)
- Produces: Updated audit document for Gate 0

- [ ] **Step 1: Read current `docs/agent-audit.md` and note all stale sections**
- [ ] **Step 2: Verify each section against actual repo (git status, file tree, CI, infra)**
- [ ] **Step 3: Rewrite `CURRENT_STATE`, `MISSING`, `CONTRADICTIONS`, `OPEN_DECISIONS`, `BLOCKERS`, `EXECUTION_ORDER`, `NEXT_GATES` with verified facts**
- [ ] **Step 4: Update dates to 03/10/2026; mark completed gates as DONE**
- [ ] **Step 5: Commit**

```bash
git add docs/agent-audit.md
git commit -m "chore(audit): update agent-audit.md to 03/10/2026 real state"
```

---

### Task 2: Implement `Argon2idPasswordHasher` (T031)

**Files:**
- Create: `apps/api/lib/adapters/out/password/argon2id_password_hasher.dart`
- Create: `apps/api/test/adapters/out/password/argon2id_password_hasher_test.dart`
- Modify: `apps/api/lib/application/identity/ports.dart` (add `PasswordHasher` port if not present)
- Modify: `apps/api/pubspec.yaml` (ensure `cryptography: ^2.9.0`)

**Interfaces:**
- Consumes: `domain/identity/password_policy.dart` (params)
- Produces: `PasswordHasher` implementation used by `RegisterCustomer`, `Login`, `ResetPassword`

- [ ] **Step 1: Write failing test with known PHC test vector**

```dart
// Verify hash format, verify() returns true for correct password, false for wrong
// Verify OWASP params: m=19456 KiB, t=2, p=1, salt 16B, hash 32B
// Verify runs in Isolate (async)
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd apps/api && fvm dart test test/adapters/out/password/argon2id_password_hasher_test.dart
```

- [ ] **Step 3: Implement `Argon2idPasswordHasher` class**

```dart
class Argon2idPasswordHasher implements PasswordHasher {
  Future<String> hash(String password) async { ... } // PHC string
  Future<bool> verify(String password, String phcHash) async { ... }
}
```

Use `cryptography` package `Argon2id` in `Isolate.run`.

- [ ] **Step 4: Run test to verify it passes**

```bash
cd apps/api && fvm dart test test/adapters/out/password/argon2id_password_hasher_test.dart
```

- [ ] **Step 5: Wire into DI (where `RegisterCustomer`/`Login`/`ResetPassword` get hasher)**

- [ ] **Step 6: Commit**

```bash
git add apps/api/lib/adapters/out/password/ apps/api/test/adapters/out/password/ apps/api/pubspec.yaml
git commit -m "feat(auth): Argon2idPasswordHasher with cryptography 2.9.0"
```

---

### Task 3: Implement `SmtpEmailSender` (T031)

**Files:**
- Create: `apps/api/lib/adapters/out/email/smtp_email_sender.dart`
- Create: `apps/api/test/adapters/out/email/smtp_email_sender_test.dart`
- Modify: `apps/api/lib/application/identity/ports.dart` (ensure `EmailSender` port exists)
- Modify: `apps/api/pubspec.yaml` (add `mailer: ^7.2.0`)

**Interfaces:**
- Consumes: `EmailSender` port, env vars `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM`
- Produces: Implementation used by `RegisterCustomer`, `ForgotPassword`, `VerifyEmail`

- [ ] **Step 1: Write failing test (mock SMTP or test against local test server)**

```dart
// Test sends email with correct from/to/subject/body
// Test uses env vars, no hardcoded credentials
// Test handles connection errors gracefully
```

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement `SmtpEmailSender` using `mailer` package**

```dart
class SmtpEmailSender implements EmailSender {
  Future<void> send(EmailMessage message) async { ... }
}
```

Configure `SmtpOptions` from env; use STARTTLS (port 587).

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Wire into DI**

- [ ] **Step 6: Commit**

```bash
git add apps/api/lib/adapters/out/email/ apps/api/test/adapters/out/email/ apps/api/pubspec.yaml
git commit -m "feat(auth): SmtpEmailSender with mailer 7.2.0"
```

---

### Task 4: Implement Console OTP/Email Senders for Dev (T031)

**Files:**
- Create: `apps/api/lib/adapters/out/otp/console_otp_sender.dart`
- Create: `apps/api/lib/adapters/out/email/console_email_sender.dart`
- Modify: DI wiring to select based on `OTP_SENDER` / `EMAIL_SENDER` env

**Interfaces:**
- Consumes: `OtpSender` / `EmailSender` ports
- Produces: Dev implementations logging to stdout

- [ ] **Step 1: Implement `ConsoleOtpSender` — logs OTP code to stdout with label**

- [ ] **Step 2: Implement `ConsoleEmailSender` — logs email content to stdout**

- [ ] **Step 3: Update DI factory to instantiate based on env (`console` vs `smtp`/`real`)**

- [ ] **Step 3: Commit**

```bash
git add apps/api/lib/adapters/out/otp/ apps/api/lib/adapters/out/email/
git commit -m "feat(auth): console OTP/Email senders for dev"
```

---

### Task 5: Implement Rate-Limit Middleware (T032)

**Files:**
- Create: `apps/api/lib/adapters/in/middleware/rate_limit_middleware.dart`
- Create: `apps/api/test/routes/rate_limit_middleware_test.dart`
- Modify: `apps/api/routes/_middleware.dart` (insert rate limiter before auth routes)

**Interfaces:**
- Consumes: `system_settings` (future) or constants for window/limit; in-memory store for MVP
- Produces: Middleware returning 429 `RATE_LIMITED` on login/OTP/forgot endpoints

- [ ] **Step 1: Write failing test — 6 requests in window → 429, 7th allowed after window**

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement sliding-window rate limiter (keyed by IP + endpoint)**

```dart
class RateLimitMiddleware {
  Handler call(Handler handler) => (context) async { ... }
}
```

Constants: login/OTP/forgot = 5 req/min per IP (documented in code).

- [ ] **Step 4: Run test to verify it passes**

- [ ] **Step 5: Insert into `_middleware.dart` chain before auth routes**

- [ ] **Step 6: Commit**

```bash
git add apps/api/lib/adapters/in/middleware/ apps/api/test/routes/rate_limit_middleware_test.dart apps/api/routes/_middleware.dart
git commit -m "feat(auth): rate-limit middleware for login/OTP/forgot"
```

---

### Task 6: Implement Auth Routes (T013–T021)

**Files:**
- Create: `apps/api/routes/auth/register.dart`
- Create: `apps/api/routes/auth/phone/verify.dart`
- Create: `apps/api/routes/auth/phone/send-otp.dart`
- Create: `apps/api/routes/auth/verify-email.dart`
- Create: `apps/api/routes/auth/login.dart`
- Create: `apps/api/routes/auth/refresh.dart`
- Create: `apps/api/routes/auth/logout.dart`
- Create: `apps/api/routes/auth/password/forgot.dart`
- Create: `apps/api/routes/auth/password/reset.dart`
- Create: `apps/api/test/routes/auth_*_test.dart` (one per route)
- Modify: `apps/api/routes/_middleware.dart` (ensure auth routes mounted)

**Interfaces:**
- Consumes: All identity use cases, `paseo_shared` DTOs, RFC 9457 mapping
- Produces: 8 HTTP endpoints matching `docs/openapi.yaml`

- [ ] **Step 1: For each route: write failing test (happy path + error cases per OpenAPI)**

```dart
// register: 201 + audit_log, 409 CONFLICT, 422 validation
// phone/verify: 200 pv=true, 400 invalid/consumed/expired/exhausted
// phone/send-otp: 200, 429 rate limit, 422 invalid phone
// verify-email: 204, 422 TOKEN_INVALID
// login: 200 tokens (body+cookie), 401 CREDENTIALS_INVALID, 403 wrong aud
// refresh: 200 rotated, 401 TOKEN_REUSE_DETECTED, 403 missing X-Paseo-Client/Origin
// logout: 204 revokes family
// password/forgot: 202 always, identical body
// password/reset: 204 token_version++ revokes family, 422 TOKEN_INVALID
```

- [ ] **Step 2: Run tests to verify they fail**

- [ ] **Step 3: Implement each route — thin: validate DTO → call use case → map result**

```dart
// Example pattern:
final body = await context.request.json();
final dto = RegisterRequest.fromJson(body);
final result = await registerCustomer.execute(dto.toInput());
return result.map(
  ok: (_) => Response.json(statusCode: 201, body: {'message': 'Registered'}),
  err: (e) => mapError(e),
);
```

- [ ] **Step 4: Run each route's tests to verify pass**

- [ ] **Step 5: Commit per route or batched**

```bash
git add apps/api/routes/auth/ apps/api/test/routes/auth_*_test.dart
git commit -m "feat(auth): routes for register, phone verify, email verify, login, refresh, logout, password reset"
```

---

### Task 7: Implement Worker Job `CleanupExpiredCredentials` (T033)

**Files:**
- Modify: `apps/api/bin/worker.dart` (add job scheduling)
- Create: `apps/api/lib/application/identity/use_cases/cleanup_expired_credentials.dart`
- Create: `apps/api/test/application/identity/cleanup_expired_credentials_test.dart`
- Create: `apps/api/test/integration/cleanup_expired_credentials_test.dart`

**Interfaces:**
- Consumes: `VerificationCodeRepository`, `PasswordResetRepository`, `RefreshTokenRepository`
- Produces: Hourly job deleting expired OTPs, password resets, QR tokens

- [ ] **Step 1: Write failing unit test (mock repos, verify delete calls)**

- [ ] **Step 2: Run test to verify it fails**

- [ ] **Step 3: Implement use case — delete where `expires_at < now()`**

- [ ] **Step 4: Implement `bin/worker.dart` — schedule hourly using `Timer.periodic`**

```dart
void main() {
  // DI setup
  Timer.periodic(Duration(hours: 1), (_) => cleanupExpiredCredentials.execute());
}
```

- [ ] **Step 5: Write integration test (insert expired rows, run job, verify deleted)**

- [ ] **Step 6: Run tests to verify pass**

- [ ] **Step 7: Commit**

```bash
git add apps/api/bin/worker.dart apps/api/lib/application/identity/use_cases/cleanup_expired_credentials.dart apps/api/test/
git commit -m "feat(worker): CleanupExpiredCredentials hourly job"
```

---

### Task 8: Create Flutter Web Entry Points

**Files:**
- Create: `apps/mobile/lib/main_merchant_web.dart`
- Create: `apps/mobile/lib/main_admin_web.dart`
- Modify: `apps/mobile/pubspec.yaml` (ensure `go_router`, `flutter_riverpod`, web entry config)

**Interfaces:**
- Consumes: `apps/mobile/lib/features/` (to be created), routing config per role
- Produces: Two buildable web apps with separate route trees

- [ ] **Step 1: Create `main_merchant_web.dart` — merchant routes only (login, dashboard, purchases, redemptions, refunds, settings)**

```dart
void main() {
  runApp(ProviderScope(child: MerchantWebApp()));
}
```

- [ ] **Step 2: Create `main_admin_web.dart` — admin routes only (rules, campaigns, users, refunds review, fraud, settings)**

```dart
void main() {
  runApp(ProviderScope(child: AdminWebApp()));
}
```

- [ ] **Step 3: Verify both build**

```bash
cd apps/mobile && fvm flutter build web -t lib/main_merchant_web.dart
cd apps/mobile && fvm flutter build web -t lib/main_admin_web.dart
```

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/main_merchant_web.dart apps/mobile/lib/main_admin_web.dart
git commit -m "feat(flutter): web entry points for merchant and admin"
```

---

### Task 9: Full Verification Pipeline

**Files:** (none — runs existing)

**Interfaces:**
- Consumes: All prior tasks complete
- Produces: Green CI-equivalent local run

- [ ] **Step 1: Format check**

```bash
fvm dart format --set-exit-if-changed .
```

- [ ] **Step 2: Analyze**

```bash
fvm dart analyze --fatal-warnings
```

- [ ] **Step 3: Unit tests (packages + api unit only)**

```bash
fvm dart test                           # packages/paseo_shared
cd apps/api && fvm dart test test/domain test/application test/routes
```

- [ ] **Step 4: OpenAPI lint**

```bash
npx --yes @redocly/cli@2 lint docs/openapi.yaml
```

- [ ] **Step 5: Migrations from zero + validate**

```bash
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml down -v
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d --wait db
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml run --rm migrate
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml run --rm migrate validate
```

- [ ] **Step 6: Integration tests (DB on 5433)**

```bash
# Ensure infra/.env has DB_DEV_PORT=5433
docker compose -f infra/docker-compose.yml -f infra/docker-compose.dev.yml up -d --wait db
cd apps/api && fvm dart test test/integration
```

- [ ] **Step 7: Flutter tests (when exist)**

```bash
cd apps/mobile && fvm flutter test
```

- [ ] **Step 8: Flutter web builds**

```bash
cd apps/mobile && fvm flutter build web -t lib/main_merchant_web.dart
cd apps/mobile && fvm flutter build web -t lib/main_admin_web.dart
```

- [ ] **Step 9: If all green, commit any generated lockfiles**

```bash
git add pubspec.lock apps/api/pubspec.lock apps/mobile/pubspec.lock
git commit -m "chore: lockfiles after foundation completion"
```

---

## Execution Order & Dependencies

```
Task 1 (audit) ──────────────────────┐
Task 2 (Argon2id) ───────────────────┤
Task 3 (SMTP) ───────────────────────┼──→ Task 6 (Auth Routes need hasher + email)
Task 4 (Console senders) ────────────┤
Task 5 (Rate limit) ─────────────────┘
Task 7 (Worker) ─────────────────────┐ (independent, can run parallel)
Task 8 (Flutter web) ────────────────┤ (independent, can run parallel)
Task 9 (Validation) ←────────────────┘ (depends on ALL above)
```

**Recommended execution:** Native (single session) — tasks are sequential with clear interfaces; subagent overhead not justified for this size. Mid-tier model can follow plan directly.

**Estimated scope:** ~15-20 new files, ~8 modified files, ~40 new tests.