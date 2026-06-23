# Scenario: edge-4-pre-supplied-params

## Type
edge-case

## Setup

```
/tmp/skill-test-gcp-deploy-presupplied/
├── pyproject.toml        (name = "api", minimal)
├── api/__init__.py       (empty)
└── Dockerfile            (FROM python:3.12-slim)
```

## Task Prompt

настрой деплой в gcp, проект acme-prod, сервис api, регион europe-west1, без аналитики

## Persona

Default persona, with edge-case modification:

- Отвечает компактно, всё сразу одной фразой.
- Раздражается, если задают вопросы про то, что уже сказал.
- Если агент задаёт вопрос про project-id / service / region / BigQuery / Looker — отвечает: «я уже всё сказал, не задавай вопросы повторно».
- На вопрос про Artifact Registry repo (единственный недостающий параметр) — отвечает: «дефолт».

## Acceptance Criteria

1. [Process] Agent detects Python from `pyproject.toml`.
2. [Process] Agent recognizes pre-supplied values (project-id, service, region, no analytics) from the opening message and does NOT re-ask them.
3. [Process] Agent asks ONLY for the missing parameter (Artifact Registry repo name), not the full 6-question block.
4. [Outcome] `cloudbuild.yaml` substitutions: `_REGION: 'europe-west1'`, `_SERVICE: 'api'`, `_REPO: 'containers'`.
5. [Outcome] `clouddeploy.yaml` Targets reference `projects/acme-prod/locations/europe-west1`.
6. [Outcome] No analytics files created (user said «без аналитики»).
7. [Outcome] `cloudbuild.yaml` test step uses Python image (`python:3.12-slim` or similar from languages.md).
8. [Compliance] Agent did not ask a single redundant question.

## Grading Notes

- This is the most valuable scenario: it tests whether the skill's Phase 2 «одним блоком 6 вопросов» rule is robust against partial pre-supply, or degenerates into a checklist that ignores context.
- Failure mode: agent reads the skill literally and asks all 6 questions despite 4 of them being answered. Criteria 2+3+8 catch this.
- For criterion 8, count agent messages between «начал работу» and «генерирую файлы». Should be exactly 1 question (about repo).

### Model for this test
opus
