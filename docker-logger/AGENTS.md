# docker-logger — centralized log collection for all local Docker containers

- `docker-compose.yml` — sole config. Runs `umputun/docker-logger`, which tails every container on the host (mounting `/var/run/docker.sock:ro`) and writes per-container `<name>.log` files into `./logs/`
