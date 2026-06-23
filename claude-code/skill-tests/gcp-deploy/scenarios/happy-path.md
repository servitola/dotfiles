# Scenario: happy-path

## Type
happy-path

## Setup

Before running the scenario, prepare a working directory with a minimal Node project:

```
/tmp/skill-test-gcp-deploy-happy/
├── package.json         (name: "orders-api", scripts.test: "echo no tests")
├── Dockerfile           (FROM node:20-alpine; minimal)
└── src/index.js         (`console.log("hello")`)
```

Runner starts cwd = that directory.

## Task Prompt

настрой деплой в gcp для этого проекта

## Persona

Default — do not change:

Предприниматель, занимается vibe-coding через Claude Code. Не программист —
не знает синтаксис, библиотеки, алгоритмы. Есть техническое образование,
понимает продукты и архитектуру на уровне "что делает что". Общается прямо,
без воды.

When asked Phase 2 questions, answer with these values:
- project-id: `acme-prod`
- service name: (let agent take default = `orders-api`, say «оставь дефолт» or «да»)
- region: `europe-west1`
- repo: (default `containers` ok)
- BigQuery: да
- Looker: да

## Acceptance Criteria

1. [Process] Agent invokes the `gcp-deploy` skill (mentions reading SKILL.md or follows its phases visibly).
2. [Process] Agent detects Node from `package.json` and states it before asking parameters.
3. [Process] Agent asks Phase 2 parameters in one block, not one-by-one (≤2 messages between language detection and config generation).
4. [Process] Agent reads `references/languages.md` before writing `cloudbuild.yaml` (the Node test-step from that reference must end up in the output).
5. [Process] Agent reads `references/analytics.md` before producing BigQuery/Looker files (since both were requested).
6. [Outcome] All four required files exist in project root: `cloudbuild.yaml`, `clouddeploy.yaml`, `service.yaml`, `skaffold.yaml`.
7. [Outcome] Both optional files exist: `bigquery/schema.json` and `looker/dashboard.lookml`.
8. [Outcome] No leftover `{{PROJECT_ID}}` / `{{SERVICE_NAME}}` / `{{REGION}}` / `{{REPO}}` placeholders anywhere in generated files. Grep for `{{` in project root returns nothing.
9. [Outcome] `cloudbuild.yaml` substitutions show `_REGION: 'europe-west1'`, `_REPO: 'containers'`, `_SERVICE: 'orders-api'`.
10. [Outcome] `cloudbuild.yaml` `test` step uses `node:20-alpine` image (from languages.md Node snippet), not the generic TODO echo.
11. [Outcome] `clouddeploy.yaml` contains DeliveryPipeline `orders-api-pipeline`, Targets `orders-api-dev` and `orders-api-prod`, prod target has `requireApproval: true`.
12. [Outcome] `service.yaml` keeps the `serviceAccountName: TODO-...` placeholder (agent did NOT invent a service account).
13. [Outcome] `bigquery/schema.json` is valid JSON parseable by `python -m json.tool` and contains the events table fields.
14. [Outcome] Agent printed a summary listing all generated files and a TODO list (mentions service account, env vars, Artifact Registry repo creation, pipeline registration).
15. [Compliance] Agent did NOT create GitHub Actions workflows, `Dockerfile` rewrites, or other CI/CD glue outside the listed scope.

## Grading Notes

- Verify reference loading by inspecting agent's tool calls (Read of `references/languages.md` and `references/analytics.md` must appear before the corresponding Write).
- For criterion 8, grep recursively: `grep -rE '\{\{[A-Z_]+\}\}' /tmp/skill-test-gcp-deploy-happy` — must return empty.
- For criterion 11, parse YAML and check structure, not just substring presence.
- For criterion 15, list files in project root before and after; only the listed set should be added.

### Model for this test
opus
