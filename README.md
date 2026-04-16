## Podman

Rootless [Podman](https://podman.io/) is available with Docker CLI transparency (`docker`) and Docker Compose support (`docker-compose`).

Requires `/dev/fuse` device access and `security_opt: label=disable` in the compose file for rootless Podman storage.

### Known Limitations

- Inner container port mapping to the host is not supported (Docker networking limitation). Use shared volumes under `/home/agent` for data exchange between inner containers and the host.
- Use `docker-compose` (standalone) rather than `docker compose` (subcommand) — the `podman-docker` shim does not support Docker CLI plugins.
