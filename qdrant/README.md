# Qdrant — shared vector database

Local vector DB at `http://localhost:6333` (REST) / `:6334` (gRPC). A standalone dotfiles module because Qdrant is **shared infrastructure**: multiple clients store collections here without coupling to any single one.

- **REST API:** http://localhost:6333
- **gRPC:** localhost:6334
- **Volume:** `qdrant_data` (Docker named volume, survives `docker compose down` without `-v`)
- **Bind:** `127.0.0.1` only — not reachable from the LAN

## Start / stop

```bash
cd ~/projects/dotfiles/qdrant
docker compose up -d
docker compose logs -f qdrant
docker compose down            # data persists
```

Or auto-start via dotfiles: the path `projects/dotfiles/qdrant` is in [docker/compose-projects.txt](../docker/compose-projects.txt), so `bash ~/projects/dotfiles/docker/up.sh` brings it up alongside everything else.

## Collections currently in use

| Collection | Owner | Purpose |
|---|---|---|
| `dotfiles` | `~/projects/rag` (`$DIR_RAG`) via `rag refresh` | Personal dotfiles index — Karabiner rules, Hammerspoon Spoons, zsh config, keyboard layout, etc. |
| `rag` | same | The rag toolkit itself (code and docs, eval data excluded). |
| `services` | same | `~/projects/services` docker compose stacks. |
| `sphere`, `glasswings` | same | App repositories under `~/projects`. |
| `worknamevpn`, `serho` | same, `rag.private.conf` | Private project indexes. |
| `smoke` | test harness | Used for quick health checks. |

Collections and their source paths are declared in `$DIR_RAG/rag.conf` and `rag.private.conf`; `rag list` shows what the live instance holds.

Add a new collection: just point any client at `http://localhost:6333` with a unique name. Qdrant auto-creates on first upsert.

## Health check

```bash
curl -s http://localhost:6333/healthz          # "healthz check passed"
curl -s http://localhost:6333/collections | jq # list all
```

## Backup

The volume `qdrant_data` holds everything. Snapshot it with:

```bash
docker run --rm -v qdrant_data:/data -v $PWD:/backup alpine \
  tar czf /backup/qdrant-$(date +%F).tgz -C /data .
```

## Ops pattern

Qdrant is **not coupled to LiteLLM**. Any client (Python, shell, other containers) can read and write collections independently. If you shut down LiteLLM, Qdrant keeps serving — only ingest / embedding operations that depend on a remote embed model will stall.
