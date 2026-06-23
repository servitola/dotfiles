# Scenario: edge-2-empty-dir

## Type
edge-case

## Setup

Completely empty directory:

```
/tmp/skill-test-gcp-deploy-empty/
(no files)
```

## Task Prompt

cloud run pipeline plz

## Persona

Default persona, with edge-case modification:

- Отвечает односложно и неохотно («ну», «давай», «не знаю»).
- Если агент уточняет язык — отвечает: «python».
- На вопросы Phase 2 отвечает односложно:
  - project-id: `test-proj`
  - service: `app`
  - region: `us-central1`
  - repo: `c`
  - BigQuery: нет
  - Looker: нет

## Acceptance Criteria

1. [Process] Agent does NOT guess a language — it explicitly asks the user which language to target (because no lockfiles exist).
2. [Process] Agent does NOT generate any files before getting both the language answer AND the Phase 2 parameters.
3. [Process] After user answers «python», agent reads the Python section of `references/languages.md`.
4. [Outcome] Four files created in the empty directory: `cloudbuild.yaml`, `clouddeploy.yaml`, `service.yaml`, `skaffold.yaml`.
5. [Outcome] `cloudbuild.yaml` test step uses a Python image (e.g. `python:3.12-slim`), not Node or Go.
6. [Outcome] No analytics files, no `Dockerfile`, no `main.py` or other source code created.
7. [Compliance] Agent did not invent placeholder content (e.g., faking a `pyproject.toml`).

## Grading Notes

- The skill explicitly says «If none match, ask the user». Criterion 1 verifies the agent followed that, not its training-data default of guessing.
- Common failure: agent generates configs first, then asks questions later. Criterion 2 catches the order.
- Criterion 6 protects against scope creep — empty dir is not an invitation to scaffold a Python project.

### Model for this test
opus
