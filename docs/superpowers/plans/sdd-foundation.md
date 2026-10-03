# SDD Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Crear la base mínima de SDD/Spec Kit para que cualquier feature posterior tenga constitución, plantillas y punto de entrada de especificaciones antes de tocar código de producto.

**Architecture:** Cambio no conductual de fundación documental. No introduce arquitectura nueva; materializa el flujo ya exigido por `AGENTS.md`: constitución → `specs/<feature>/` (spec, plan, tareas) → implementación. Se mantiene `AGENTS.md` como fuente de verdad y solo se referencia/resume, sin duplicar decisiones.

**Tech Stack:** Markdown, GitHub Spec Kit layout observado, Git.

**Spec:** `docs/agent-audit.md` (EXECUTION_ORDER, paso 3) + `AGENTS.md` + `9-stack-tecnologico-paseo-points.md` Anexo B.

## Global Constraints

- `AGENTS.md` gana cuando exista conflicto; las plantillas no deben contradecirlo.
- No se resuelven decisiones abiertas; cualquier campo abierto se marca explícitamente como pendiente.
- No se introduce lógica de producto, endpoints, migraciones, infraestructura ni código Dart/Flutter.
- Toda plantilla debe exigir trazabilidad requirement → spec → plan → tasks → implementation → tests.
- Toda plantilla API debe recordar que `docs/openapi.yaml` se actualiza antes que rutas.
- Toda plantilla de base de datos debe recordar RLS, `GRANT`, pruebas de aislamiento e inmutabilidad de migraciones.
- El repositorio está en Windows + PowerShell; los comandos de verificación deben funcionar ahí.
- No se instalan herramientas ni plugins externos no auditados.

## Review Focus

- **Duplicación de verdad:** una plantilla puede copiar reglas y quedar desactualizada; por eso la constitución local apunta a `AGENTS.md` y solo resume invariantes. Test: `grep` verifica referencia a `@AGENTS.md`/`AGENTS.md`.
- **Falsos requisitos resueltos:** una plantilla puede convertir decisiones abiertas en cerradas; los campos abiertos deben permanecer `OPEN`/`NEEDS CLARIFICATION`. Test: buscar que el plan/templates nombren la lista de decisiones abiertas sin resolverlas.
- **Spec sin pruebas:** una spec de feature podría omitir criterios verificables; la plantilla debe hacerlos obligatorios. Test: `spec-template.md` incluye `Acceptance Scenarios`, `Functional Requirements`, `Success Criteria` y sección de pruebas.
- **Cambio de API sin contrato:** una plantilla puede permitir implementar rutas antes de OpenAPI; debe bloquear eso. Test: `plan-template.md` y `tasks-template.md` mencionan `docs/openapi.yaml` como gate.
- **Tabla sin RLS:** una plantilla de tareas puede olvidar RLS/grants/pruebas; debe incluir gate explícito. Test: `tasks-template.md` incluye tarea obligatoria de migración con RLS/GRANT/prueba cuando aplique.

---

### Task 1: Create Spec Kit memory

**Files:**
- Create: `.specify/memory/constitution.md`

**Interfaces:**
- Consumes: `AGENTS.md`, `INFRASTRUCTURE.md`, `9-stack-tecnologico-paseo-points.md`.
- Produces: Constitución local que los futuros specs/plans/templates pueden citar sin reemplazar `AGENTS.md`.

- [ ] **Step 1: Create parent directory**

Run: `New-Item -ItemType Directory -Path ".specify/memory" -Force`
Expected: `.specify/memory/` exists.

- [ ] **Step 2: Write constitution**

Create `.specify/memory/constitution.md` with a concise project constitution that:
- declares `AGENTS.md` as governing policy;
- records the non-negotiable invariants from `AGENTS.md` §2, §5–§11;
- records that open decisions remain open until human resolution;
- defines governance/amendment rules by reference to `AGENTS.md` updates.

Expected content anchors:
- `AGENTS.md`
- `points_ledger`
- `Idempotency-Key`
- `audit_log`
- `RLS`
- `docs/openapi.yaml`
- `Open decisions remain OPEN`

- [ ] **Step 3: Verify constitution anchors**

Run:
```powershell
Select-String -Path ".specify/memory/constitution.md" -Pattern "AGENTS.md","points_ledger","Idempotency-Key","audit_log","RLS","docs/openapi.yaml"
```
Expected: each pattern is found.

- [ ] **Step 4: Commit task**

Run:
```powershell
git add .specify/memory/constitution.md
git commit -m "docs(spec-kit): add project constitution memory"
```
Expected: commit succeeds.

---

### Task 2: Create Spec Kit templates

**Files:**
- Create: `.specify/templates/spec-template.md`
- Create: `.specify/templates/plan-template.md`
- Create: `.specify/templates/tasks-template.md`
- Create: `.specify/templates/checklist-template.md`

**Interfaces:**
- Consumes: GitHub Spec Kit template structure observed under `templates/` and the project rules in `AGENTS.md`.
- Produces: Reusable Spanish templates for `spec.md`, `plan.md`, `tasks.md`, and checklist validation of future features.

- [ ] **Step 1: Create templates directory**

Run: `New-Item -ItemType Directory -Path ".specify/templates" -Force`
Expected: `.specify/templates/` exists.

- [ ] **Step 2: Write four templates**

Create the templates with Spanish section headings and required placeholders for:
- feature metadata (`Feature`, `Branch`, `Date`, `Status`, `Input`);
- user scenarios and acceptance scenarios;
- requirements, entities, success criteria, assumptions/open decisions;
- technical context, constitution check, structure decision, complexity tracking;
- phased tasks, dependencies, parallel opportunities, verification commands;
- checklist items for contract, architecture, database/RLS, security, tests, CI.

Required anchors across the set:
- `docs/openapi.yaml`
- `RLS`
- `GRANT`
- `Idempotency-Key`
- `RFC 9457`
- `OPEN_DECISIONS`
- `AGENTS.md`

- [ ] **Step 3: Verify template anchors**

Run:
```powershell
$files = @(".specify/templates/spec-template.md", ".specify/templates/plan-template.md", ".specify/templates/tasks-template.md", ".specify/templates/checklist-template.md")
foreach ($f in $files) { Select-String -Path $f -Pattern "AGENTS.md" | Out-Null }
Select-String -Path ".specify/templates/plan-template.md" -Pattern "docs/openapi.yaml","RLS","GRANT"
Select-String -Path ".specify/templates/tasks-template.md" -Pattern "docs/openapi.yaml","Idempotency-Key","RFC 9457","OPEN_DECISIONS"
```
Expected: all commands return matches and no `Select-String` errors occur.

- [ ] **Step 4: Commit task**

Run:
```powershell
git add .specify/templates
git commit -m "docs(spec-kit): add SDD templates"
```
Expected: commit succeeds.

---

### Task 3: Create specs entry point

**Files:**
- Create: `specs/README.md`

**Interfaces:**
- Consumes: `.specify/memory/constitution.md`, `.specify/templates/*.md`, `AGENTS.md`.
- Produces: Human/agent-facing entry point explaining where future feature specs live and what must be approved before implementation.

- [ ] **Step 1: Create specs directory**

Run: `New-Item -ItemType Directory -Path "specs" -Force`
Expected: `specs/` exists.

- [ ] **Step 2: Write specs README**

Create `specs/README.md` with:
- directory convention `specs/<feature>/`;
- required files per feature: `spec.md`, `plan.md`, `tasks.md`, optional `research.md`, `data-model.md`, `contracts/`;
- approval gate: human approves spec and plan before implementation;
- verification gates from `AGENTS.md` §16;
- explicit note that `docs/openapi.yaml` precedes endpoints.

- [ ] **Step 3: Verify README anchors**

Run:
```powershell
Select-String -Path "specs/README.md" -Pattern "spec.md","plan.md","tasks.md","docs/openapi.yaml","OPEN_DECISIONS"
```
Expected: all anchors are found.

- [ ] **Step 4: Commit task**

Run:
```powershell
git add specs/README.md
git commit -m "docs(specs): add feature specification entry point"
```
Expected: commit succeeds.

---

### Task 4: Audit update and verification

**Files:**
- Modify: `docs/agent-audit.md`
- Verify: all files created by Tasks 1–3

**Interfaces:**
- Consumes: final state of Tasks 1–3.
- Produces: audit state updated only for facts that are true after implementation.

- [ ] **Step 1: Run whitespace validation**

Run: `git diff --check`
Expected: no output / exit code 0.

- [ ] **Step 2: Verify created file layout**

Run:
```powershell
$paths = @(
  ".specify/memory/constitution.md",
  ".specify/templates/spec-template.md",
  ".specify/templates/plan-template.md",
  ".specify/templates/tasks-template.md",
  ".specify/templates/checklist-template.md",
  "specs/README.md"
)
foreach ($p in $paths) { if (-not (Test-Path -LiteralPath $p)) { throw "Missing $p" } }
```
Expected: no exception.

- [ ] **Step 3: Update audit for factual new state**

Modify `docs/agent-audit.md` so that `CURRENT_STATE`, `MISSING`, `AGENT_SYSTEM_GAPS`, `BLOCKERS`, and `NEXT_GATES` no longer claim that `.specify/` and `specs/` remain absent after this change. Do not mark API/DB/CI as implemented.

- [ ] **Step 4: Commit task**

Run:
```powershell
git add docs/agent-audit.md
git commit -m "docs(audit): record SDD foundation state"
```
Expected: commit succeeds.

---

## Dependencies & Execution Order

1. Task 1 creates constitution memory.
2. Task 2 can start after Task 1 exists, but must not contradict it.
3. Task 3 depends on Task 2 template paths.
4. Task 4 runs last.

Tasks 1–3 change different files and could be parallelized after their shared conventions are fixed, but serialized execution is safer because Task 2 templates must cite Task 1 constitution and Task 3 must cite both.

## Verification

Final verification before review:

```powershell
git diff --check
Get-ChildItem -Recurse .specify, specs | Select-Object FullName
Select-String -Path ".specify/memory/constitution.md" -Pattern "AGENTS.md","RLS","Idempotency-Key","audit_log"
Select-String -Path ".specify/templates/tasks-template.md" -Pattern "docs/openapi.yaml","RLS","GRANT","Idempotency-Key","RFC 9457"
git status --short --branch
```

Expected:
- Markdown/text whitespace check passes.
- All `.specify` and `specs` entry files exist.
- No open decision is marked resolved.
- No product code, migration, OpenAPI endpoint, infrastructure service, dependency, or security behavior was added.

## Self-Review

- **Spec coverage:** This plan covers only `.specify/`, `specs/README.md`, and factual audit update. It does not attempt `docs/openapi.yaml`, monorepo, infrastructure, migrations, CI, or feature code.
- **Step scan:** Each step writes or verifies one artifact set. No step resolves an open decision.
- **Type consistency:** File names and anchors are consistent across tasks and verification.
- **Review focus coverage:** Anchors and verification commands explicitly check constitution truth, API contract gate, database RLS gate, test/acceptance sections, and open decisions.
- **Proportion:** The plan is intentionally larger than the artifact set because the repository requires traceable gates, but implementation content remains minimal Markdown scaffolding.
