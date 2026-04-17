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

The compose file exposes ports `4096` and `3000`, mounts a persistent volume at `/home/agent`, and drops all capabilities except `SYS_PTRACE`, `NET_RAW`, `NET_ADMIN`, `SETUID`, and `SETGID`. Each granted capability and disabled security feature is documented inline in `docker-compose.yml`.

## Security Posture

All capabilities beyond the default Docker set are granted for specific, narrow purposes (rootless Podman UID mapping, network tooling, debuggers). The seccomp filter and SELinux labeling are disabled to support rootless container-in-container execution.

Protection against kernel privilege-escalation exploits (e.g. namespace escape via 0-day) is explicitly out of scope. This image assumes a patched host kernel. If that assumption does not hold, run with an additional isolation layer (VM, gVisor, etc.).

## Known Limitations

- Inner container port mapping to the host is not supported (Docker networking limitation). Use shared volumes under `/home/agent` for data exchange.

## License

See [LICENSE](LICENSE).
