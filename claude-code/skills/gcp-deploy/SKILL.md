---
name: gcp-deploy
description: |
  Generates Google Cloud deployment configs: cloudbuild.yaml (Cloud Build),
  clouddeploy.yaml (Cloud Deploy with dev/prod stages), service.yaml (Cloud Run),
  with optional BigQuery ingestion schema and Looker dashboard.

  Use when: "настрой деплой в gcp", "разверни в google cloud", "gcp deploy",
  "deploy to google cloud", "cloud run pipeline", "cloud build pipeline",
  "настрой cloud run", "настрой cloud build", "/gcp-deploy"
---

# GCP Deploy

Generates minimal, working GCP deployment configs for Node / Python / Go projects.
Pipeline: source → Cloud Build → Artifact Registry → Cloud Deploy → Cloud Run (dev → prod).
Optionally adds BigQuery table schema and Looker dashboard for analytics.

## Phase 1: Detect Language

Read the project root and check for these signals:

| Signal                                          | Language |
|-------------------------------------------------|----------|
| `package.json`                                  | node     |
| `pyproject.toml` / `requirements.txt` / `Pipfile` | python |
| `go.mod`                                        | go       |

- Exactly one row matches → use that language.
- Multiple rows match (polyglot repo) → list the matches to the user and ask
  which service to deploy. Do not silently pick the first row.
- No rows match → ask the user which language to target.

**Checkpoint:** language identified, project root path noted.

## Phase 2: Gather Parameters

Ask the user (one block, not one-by-one):

1. GCP `project-id`
2. Service name (kebab-case, ≤63 chars) — default in this priority:
   `package.json` `name`, then `pyproject.toml` `project.name`, then the
   basename of the `go.mod` module path, then the project directory name.
   Sanitize to kebab-case and trim to ≤63 chars.
3. Region — default: `us-central1`
4. Artifact Registry repo name — default: `containers`
5. Add BigQuery analytics? (y/n)
6. Add Looker dashboard? (y/n) — only meaningful if BigQuery=y

Collect answers before writing anything. If the user has a `.claude/skills/project-knowledge/references/deployment.md`, read it first — values there override defaults.

**Checkpoint:** all six answers captured.

## Phase 3: Generate Configs

Write these files to the project root, substituting captured parameters
(`{{PROJECT_ID}}`, `{{SERVICE_NAME}}`, `{{REGION}}`, `{{REPO}}`):

1. `cloudbuild.yaml` — copy from [templates/cloudbuild.yaml](templates/cloudbuild.yaml).
   Adjust the language-specific test step using guidance from
   [references/languages.md](references/languages.md) (per-language test/build commands).

2. `clouddeploy.yaml` — copy from [templates/clouddeploy.yaml](templates/clouddeploy.yaml).
   Two targets: `{{SERVICE_NAME}}-dev` (auto) and `{{SERVICE_NAME}}-prod` (requireApproval: true).

3. `service.yaml` — copy from [templates/service.yaml](templates/service.yaml).
   Leave `serviceAccountName` as a TODO placeholder — the user fills it after
   creating the SA. Same for any env vars.

4. `skaffold.yaml` — copy from [templates/skaffold.yaml](templates/skaffold.yaml).
   Cloud Deploy needs this to render the manifest per stage.

**If BigQuery=y**, also write `bigquery/schema.json` from
[templates/bigquery-schema.json](templates/bigquery-schema.json), and follow
setup from [references/analytics.md](references/analytics.md) (table location,
ingestion patterns).

**If Looker=y**, also write `looker/dashboard.lookml` from
[templates/looker-dashboard.lookml](templates/looker-dashboard.lookml).
See [references/analytics.md](references/analytics.md) for connection wiring.

Scope: produce only the GCP-side configs listed above. GitHub Actions
workflows and Cloud Build triggers belong to the `deploy-pipeline` skill.

**Checkpoint:** all required files written; optional files written iff requested.

## Phase 4: Output Summary

Print a short summary for the user:

```
Generated GCP configs in {project-root}:
  cloudbuild.yaml      — Cloud Build pipeline ({language})
  clouddeploy.yaml     — Cloud Deploy: dev → prod (manual approval)
  service.yaml         — Cloud Run service manifest
  skaffold.yaml        — Skaffold render config
  [bigquery/schema.json]
  [looker/dashboard.lookml]

TODOs left for you:
  - service.yaml: set serviceAccountName (create SA with roles/run.invoker, roles/artifactregistry.reader)
  - service.yaml: fill env vars
  - cloudbuild.yaml: confirm $_REGION, $_REPO substitutions
  - Create Artifact Registry repo: gcloud artifacts repositories create {{REPO}} --repository-format=docker --location={{REGION}}
  - Register pipeline: gcloud deploy apply --file=clouddeploy.yaml --region={{REGION}}
```

**Checkpoint:** summary printed; user knows the remaining TODOs.

## Final Check

Before finishing, verify:
- [ ] Language detected (or asked); all 6 parameters captured
- [ ] All four required files (cloudbuild, clouddeploy, service, skaffold) written
- [ ] Optional analytics files written only if requested
- [ ] Placeholders substituted with actual values (no leftover `{{...}}`)
- [ ] TODO list printed for the user

## Appendix: Up-to-date Docs

When uncertain about current GCP schemas (Google revs them often), fetch the
official source:

- Cloud Build: https://cloud.google.com/build/docs/build-config-file-schema
- Cloud Deploy: https://cloud.google.com/deploy/docs/config-files
- Cloud Run YAML: https://cloud.google.com/run/docs/reference/yaml/v1
- BigQuery schema: https://cloud.google.com/bigquery/docs/schemas

If a GCP MCP server is configured (`~/.claude.json` → mcpServers), prefer its
tools over WebFetch for live docs.
