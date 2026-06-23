# Scenario: edge-1-go-no-analytics

## Type
edge-case

## Setup

```
/tmp/skill-test-gcp-deploy-go/
├── go.mod                (module example.com/billing-svc; go 1.23)
├── main.go               (package main; func main() {})
└── Dockerfile            (FROM golang:1.23; minimal)
```

## Task Prompt

разверни этот сервис в google cloud

## Persona

Default persona.

Answers for Phase 2:
- project-id: `billing-stage-42`
- service name: оставь дефолт
- region: `us-central1`
- repo: оставь дефолт
- BigQuery: нет
- Looker: нет

## Acceptance Criteria

1. [Process] Agent detects Go language from `go.mod` (states it explicitly).
2. [Process] Agent reads `references/languages.md` and applies the Go snippet (`golang:1.23` image, `go test ./...` command) to the test step.
3. [Process] Agent does NOT read `references/analytics.md` (no BigQuery, no Looker requested) — verified by absence of that Read tool call.
4. [Outcome] Only four files created: `cloudbuild.yaml`, `clouddeploy.yaml`, `service.yaml`, `skaffold.yaml`.
5. [Outcome] No `bigquery/` directory, no `looker/` directory in project root.
6. [Outcome] `cloudbuild.yaml` test step uses `golang:1.23` image with `go test ./...`, not the Node or Python variant.
7. [Outcome] `clouddeploy.yaml` service name is `billing-svc` (from `go.mod` module basename) or whatever the agent picked as default — but consistent across all four files.
8. [Outcome] No `{{...}}` placeholders remain anywhere.
9. [Compliance] Agent did not create analytics files "just in case".

## Grading Notes

- Common failure mode: agents add analytics scaffolding even when user said no. Criterion 5 explicitly catches this.
- Common failure mode: agents copy the Node snippet from the example in SKILL.md without reading `languages.md`. Criterion 2 + 6 catch this.
- For criterion 7, the service name must be identical across `clouddeploy.yaml`, `service.yaml`, and the `_SERVICE` substitution in `cloudbuild.yaml`.

### Model for this test
opus
