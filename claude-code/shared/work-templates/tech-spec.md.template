---
created: YYYY-MM-DD
status: draft | approved
branch: dev
size: S | M | L
---

# Tech Spec: {Feature Name}

## Solution

Technical approach. (Длина зависит от задачи — без ограничений.)

## Architecture

### What we're building/modifying

- **Component A** — purpose
- **Component B** — purpose

### How it works

Data flow, interactions, sequence.

### Shared resources

Heavy resources shared across components (ML models, DB connection pools, browser instances, API clients).
If none — write "None".

| Resource | Owner (creates) | Consumers | Instance count |
|----------|----------------|-----------|----------------|
| example: FastEmbedEmbedding | main.py | Indexer, QueryEngine | 1 (singleton) |

## Decisions

### Decision 1: [topic]
**Decision:** what we chose
**Rationale:** why
**Alternatives considered:** what else, why rejected

### Decision 2: ...

## Data Models

DB schemas, interfaces, types. Skip if N/A.

## Dependencies

### New packages
- `package-name` — purpose

### Using existing (from project)
- `module-name` — how

## Testing Strategy

**Feature size:** S / M / L

### Unit tests
- Scenario 1: what we test
- Scenario 2: ...

### Integration tests
- Scenario 1 (if M/L feature, or if needed)
- "None" (if S feature and agreed with user)

### E2E tests
- Critical flow 1 (if L feature)
- "None" (if S/M and not needed)

## Agent Verification Plan

**Source:** user-spec "Как проверить" section.

### Verification approach
How agent verifies beyond automated tests.
Per-task smoke checks are specified in each task's Verify-smoke / Verify-user fields in Implementation Tasks.
Post-deploy checks are described in the Post-deploy verification task description.

### Tools required
Playwright MCP, Telegram MCP, curl, bash — which are needed.

## Risks

| Risk | Mitigation |
|------|-----------|
| Risk 1 | What we do |

## User-Spec Deviations

<!-- Document every place where tech-spec deviates from, extends, or reinterprets user-spec.
     Each entry needs: requirement ID, what user-spec says, what tech-spec does, why, approval status.
     If no deviations — write "None". -->

None

<!-- Example entries:
- **US-3 (Push notifications):** user-spec says "real-time push", tech-spec uses polling every 5s instead. Reason: push infrastructure adds 2 weeks, polling meets latency requirements. → [PENDING USER APPROVAL]
- **Added: Rate limiting** (not in user-spec). Reason: public API endpoint needs protection from abuse. → [PENDING USER APPROVAL]
-->

## Acceptance Criteria

Технические критерии приёмки (дополняют пользовательские из user-spec):

- [ ] API возвращает корректные коды ответов (200, 201, 400, 404, 500)
- [ ] Миграции БД применяются и откатываются без ошибок
- [ ] Все тесты проходят (unit, integration если есть)
- [ ] Нет регрессий в существующих тестах
- [ ] ...

## Implementation Tasks

<!-- Tasks are brief scope descriptions. AC, TDD, and detailed steps are created during task-decomposition.

     Verify-smoke: concrete executable checks the agent runs during implementation — no deployment needed.
     Types: command (curl, python -c, docker build), MCP tool (Playwright, Telegram),
     API call (OpenRouter, external services), local server check, agent with test prompt.
     Verify-user: agent asks user to verify something (UI, behavior, experience).
     Both fields optional — omit if task is internal logic fully covered by tests. -->

### Wave 1 (независимые)

#### Task 1: [Name]
- **Description:** Создать REST-эндпоинт для регистрации пользователей. Нужен для MVP авторизации. Результат: POST /api/users возвращает 201.
- **Skill:** code-writing
- **Reviewers:** code-reviewer, security-auditor, test-reviewer
- **Verify-smoke:** `curl -X POST localhost:3000/api/users -d '{"name":"test","email":"test@test.com"}' -H 'Content-Type: application/json'` → 201
- **Files to modify:** `src/api/users.ts`, `src/models/user.ts`
- **Files to read:** `src/api/index.ts`, `src/middleware/auth.ts`

#### Task 2: [Name]
- **Description:** Добавить форму создания пользователя (name, email, role). Связывает UI с API из Task 1. Результат: заполненная форма отправляет POST /api/users.
- **Skill:** code-writing
- **Reviewers:** code-reviewer, test-reviewer
- **Verify-user:** open localhost:3000/users → form renders, submit creates user
- **Files to modify:** `src/components/UserForm.tsx`
- **Files to read:** `src/components/BaseForm.tsx`, `src/hooks/useValidation.ts`

### Wave 2 (зависит от Wave 1)

#### Task 3: [Name]
- **Description:** Интегрировать отправку welcome-email при создании пользователя. Асинхронно, не блокирует основной flow. Результат: после POST /api/users уходит email.
- **Skill:** code-writing
- **Reviewers:** code-reviewer, security-auditor, test-reviewer
- **Files to modify:** `src/services/notification.ts`
- **Files to read:** `src/api/users.ts`, `src/config/services.ts`

### Audit Wave

<!-- Full-feature audit: 3 auditors review all code in parallel. Always present. -->
<!-- Auditors read code and write reports. If issues found — lead spawns a fixer, auditors become reviewers. -->

#### Task N-2: Code Audit
- **Description:** Full-feature code quality audit. Read all source files created/modified in this feature (from decisions.md + tech-spec "Files to modify"). Review holistically for cross-component issues: duplicate resource initialization, shared resources compliance with Architecture decisions, architectural consistency. Write audit report.
- **Skill:** code-reviewing
- **Reviewers:** none

#### Task N-1: Security Audit
- **Description:** Full-feature security audit. Read all source files created/modified in this feature. Analyze for OWASP Top 10 across all components, cross-component auth/data flow. Write audit report.
- **Skill:** security-auditor
- **Reviewers:** none

#### Task N: Test Audit
- **Description:** Full-feature test quality audit. Read all test files created in this feature. Verify coverage, meaningful assertions, test pyramid balance across all components. Write audit report.
- **Skill:** test-master
- **Reviewers:** none

### Final Wave

<!-- QA is always present. Deploy and Post-deploy — only if applicable for this feature. -->

#### Task N: Pre-deploy QA
- **Description:** Acceptance testing: run all tests, verify acceptance criteria from user-spec and tech-spec
- **Skill:** pre-deploy-qa
- **Reviewers:** none

#### Task N+1: Deploy (if applicable)
- **Description:** Deploy + verify logs
- **Skill:** infrastructure
- **Reviewers:** none

#### Task N+2: Post-deploy verification (if applicable)
- **Description:** Live environment verification:
  - [verification step 1] — tool: [Telegram MCP / curl / bash]
  - [verification step 2] — tool: [tool]
  Tools: [list of required MCP tools / curl / bash]
- **Skill:** post-deploy-qa
- **Reviewers:** none
