# qdrant — agent rules

- Volume `qdrant_data` is `external: true`. Never `docker compose down -v`.
- Image is distroless (no sh/wget/curl). No healthcheck in compose. Poll `http://localhost:6333/healthz` from host.
- Port stays `127.0.0.1:6333` (REST) / `:6334` (gRPC). No API auth — LAN exposure would be open access.
- Shared infra: many clients write collections here. Document new collection names in [README.md](README.md).

After any change:

```bash
docker compose up -d
curl -s http://localhost:6333/healthz
curl -s http://localhost:6333/collections | jq -r '.result.collections[].name'
```
