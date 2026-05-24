# Language-specific build steps

Replace the `test` step in `cloudbuild.yaml` with the snippet for the
detected language. Keep step `id: test` so the `build` step's `waitFor`
still resolves.

## Node

```yaml
- name: 'node:20-alpine'
  id: 'test'
  entrypoint: 'sh'
  args: ['-c', 'npm ci && npm test --if-present']
```

Dockerfile assumption: multi-stage build copying `package*.json` first,
then `npm ci --omit=dev`, then app source.

## Python

```yaml
- name: 'python:3.12-slim'
  id: 'test'
  entrypoint: 'bash'
  args: ['-c', 'pip install -r requirements.txt && pytest -q || true']
```

If the project uses `pyproject.toml` with Poetry/uv, swap the install
command accordingly (`pip install poetry && poetry install --no-root`
or `uv sync`).

## Go

```yaml
- name: 'golang:1.23'
  id: 'test'
  entrypoint: 'bash'
  args: ['-c', 'go test ./...']
```

For the build step, prefer Cloud Buildpacks (`gcr.io/k8s-skaffold/pack`)
or a minimal scratch/distroless Dockerfile.

## Notes

- Cache: for faster builds, add `kaniko-project/executor` with
  `--cache=true` instead of `docker build`. Trade-off: longer first
  build, faster subsequent ones.
- If the project has no tests yet, keep the step but make it a no-op
  (`echo "no tests yet"`) so the pipeline shape is preserved.
