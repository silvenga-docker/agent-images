# agent-images

beep boop - I'm a bot, building my own container image.

This is an opinionated agent container image for personal use in experimenting with agentic workflows. It packages a Debian-based environment with the tooling an AI coding agent typically needs — runtimes, network utilities, debugging tools, and an init system — so you can drop it into a compose stack and start iterating.

## What's Inside

- **Base**: Debian Trixie (slim), running rootless under an unprivileged `agent` user.
- **Init**: [s6-overlay](https://github.com/just-containers/s6-overlay) for process supervision.
- **Runtimes**: Python 3, Bun, plus Rust build toolchain (cmake, clang, lld).
- **Dev Tools**: Git, ripgrep, fd, jq, sqlite3, PostgreSQL client, Redis client.
- **Network**: nmap, mtr, tshark, tcpdump, socat, proxychains4, dnsutils.
- **Agent**: [OpenCode](https://github.com/anomalyco/opencode) pre-installed.
- **Containers**: Rootless [Podman](https://podman.io/) with Docker CLI transparency (`docker`, `docker compose`, `docker-compose`).

## Usage

```bash
docker compose up -d
```

> **Note**: The compose file requires `/dev/fuse` device access, `security_opt: label=disable` (SELinux), and `security_opt: seccomp=unconfined` (to allow user namespaces for rootless Podman). See `docker-compose.yml`.

The compose file exposes ports `4096` and `3000`, mounts a persistent volume at `/home/agent`, and drops all capabilities except `SYS_PTRACE`, `NET_RAW`, and `NET_ADMIN`.

## Known Limitations

- Inner container port mapping to the host is not supported (Docker networking limitation). Use shared volumes under `/home/agent` for data exchange.

## License

See [LICENSE](LICENSE).
