# Scenario: edge-3-polyglot

## Type
edge-case

## Setup

Polyglot monorepo (all three signals present):

```
/tmp/skill-test-gcp-deploy-poly/
├── package.json          (frontend bits)
├── pyproject.toml        (ml service)
├── go.mod                (backend)
├── Dockerfile            (FROM golang:1.23)
└── README.md             («Backend is Go, frontend Node, ML Python»)
```

## Task Prompt

настрой cloud build для этого проекта

## Persona

Default persona.

If agent asks which language to target, answer: «основной сервис — Go, его и деплоим».

Phase 2 answers:
- project-id: `polyglot-prod`
- service: `backend`
- region: `europe-west1`
- repo: оставь дефолт
- BigQuery: нет
- Looker: нет

## Acceptance Criteria

1. [Process] Agent acknowledges multiple language signals are present (either lists them or explicitly asks which one to use).
2. [Process] If agent applied the SKILL.md table order strictly (Node wins as first match), it states that decision before generating files — and the user can correct it. If agent asked instead, it waited for the answer.
3. [Outcome] Final `cloudbuild.yaml` test step matches Go (after user clarified «основной сервис — Go»), not Node.
4. [Outcome] All four required files exist; no analytics files.
5. [Outcome] `Dockerfile` is left untouched (agent did not rewrite or replace it).
6. [Compliance] Agent did NOT generate three sets of configs (one per language) or three separate services.

## Grading Notes

- This scenario tests the gap between the strict table order in Phase 1 and real-world polyglot repos. Either behavior (strict table OR ask user) can pass criteria 1+2 if executed cleanly. Failure mode: agent silently picks one without telling the user.
- Criterion 6 catches over-engineering — the skill produces configs for ONE service per run.

### Model for this test
opus
