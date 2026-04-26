# agent-images

beep boop - I'm a bot, building my own container image.

This is an opinionated agent container image for personal use in experimenting with agentic workflows. It packages a Debian-based environment with the tooling an AI coding agent typically needs — runtimes, network utilities, debugging tools, and an init system — so you can drop it into a compose stack and start iterating.

## What's Inside

- **Base**: Debian Trixie (slim), running under Sysbox with Docker-in-Docker support.
- **Init**: [s6-overlay](https://github.com/just-containers/s6-overlay) for process supervision.
- **Runtimes**: Python 3, Bun, Node 20 (via nvm), plus Rust build toolchain (cmake, clang, lld).
- **Dev Tools**: Git, ripgrep, fd, jq, sqlite3, PostgreSQL client, Redis client.
- **Network**: nmap, mtr, tshark, tcpdump, socat, proxychains4, dnsutils.
- **Browser**: Google Chrome stable (headless-capable, for Playwright/MCP browser tools).
- **Agent**: [OpenCode](https://github.com/anomalyco/opencode) pre-installed.
- **Containers**: Docker CE (`docker`, `docker compose`) via the official Docker apt repository.

## Usage

```bash
docker compose up -d
```

## OpenCode Configuration

Configure OpenCode to load the in-container tool reference by adding the following to your `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": ["/IMAGES.md"]
}
```

This instructs OpenCode to include `/IMAGES.md` (the authoritative tool reference baked into the image) as context for every session.

The compose file exposes ports `4096` and `3000`, mounts a persistent volume at `/home/agent` and a separate Docker image cache volume at `/var/lib/docker`. `/tmp` is an anonymous Docker volume — content may survive container restarts but should be treated as ephemeral. Run `reboot` to halt the container (triggers a restart if Docker is configured with a restart policy). By default it runs with `privileged: true` to allow Docker-in-Docker. When running under [Sysbox](https://github.com/nestybox/sysbox), replace `privileged: true` with `runtime: sysbox-runc` in `docker-compose.yml`.

## Security Posture

This image is designed to run under the [Sysbox](https://github.com/nestybox/sysbox) container runtime, which provides VM-like isolation. The Docker daemon runs as root inside the container; application services (opencode, openchamber) run as the unprivileged `agent` user (uid 1000) via `s6-setuidgid`.

Sysbox runtime 0-day exploits are out of scope. No additional capability grants, seccomp overrides, or SELinux workarounds are needed when running under Sysbox.

## Known Limitations

- Inner container port mapping to the host is not supported (Docker networking limitation). Use shared volumes under `/home/agent` for data exchange.

## License

See [LICENSE](LICENSE).
