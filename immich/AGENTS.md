# immich — push local Mac photo folders to a self-hosted Immich server

- `sync.sh` is the only file here: a zsh uploader run on demand (or by `up`/cron), not a daemon. It shells out to the `@immich/cli` global npm binary (`immich upload`), so that CLI must be installed or the script no-ops and exits 0.
- Target server is `mir1` on the i9 box, fronted by Caddy at `IMMICH_URL` (loaded from the gitignored `immich.private.env` overlay). The script pings `/api/server/ping` first and skips cleanly if unreachable — both missing-CLI and unreachable-server are soft exits, not failures.
- `NODE_TLS_REJECT_UNAUTHORIZED=0` is set deliberately: Caddy serves a self-signed cert and Node/undici drops SNI for IP literals, so verification can't pass until DDNS + Let's Encrypt is set up. Don't "fix" this by re-enabling verify against the IP.
- What to upload lives in `SYNC_MAP` (`"<album-name>::<absolute-path>"` entries); add folders by appending there. `IGNORE_PATTERNS` skips `.xmp`/`.DS_Store`/`Thumbs.db`.
- Invariants: idempotent (server dedups by hash, no re-upload) and non-destructive (never deletes local files). Each map entry uploads recursively into its named album.
