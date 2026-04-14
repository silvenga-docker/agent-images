# AGENTS.md

Guide for AI agents editing this repository. This repo defines a hardened Docker image for AI coding agents.

## Project Structure

```
Dockerfile              # Image definition (Debian trixie-slim base)
docker-compose.yml      # Runtime config (ports, caps, volumes)
rootfs/                 # Files overlaid onto the image at build
  usr/local/bin/        # agent-setup.sh (runtime bootstrap)
  etc/s6-overlay/       # s6 service definitions
.github/workflows/      # CI — builds on push to master + weekly cron
```

## Architecture

- **Base**: Debian trixie-slim
- **Init**: s6-overlay manages services
- **User**: `agent` (uid 1000, non-root)
- **Volume**: `/home/agent` is a persistent volume
- **Services** (s6 boot order): `agent-init` (oneshot) → `opencode` (longrun, :4096) → `openchamber` (longrun, :3000)
- **External deps**: [OpenCode](https://github.com/anomalyco/opencode), [OpenChamber](https://github.com/btriapitsyn/openchamber) — pinned by version in Dockerfile/agent-setup.sh

## Security Model — HIGH SENSITIVITY

This image defines a security boundary. All changes must preserve these invariants:

### Hard Rules

- **Non-root**: Container runs as `USER agent` (uid 1000). Never add `USER root` or switch users.
- **No setuid/setgid**: All suid/sgid bits are stripped at build (`find / -perm /6000 ... chmod a-s`). Never reintroduce them.
- **Minimal capabilities**: Compose drops ALL caps, adds back only `SYS_PTRACE`, `NET_RAW`, `NET_ADMIN`. Never add `SYS_ADMIN`, `DAC_OVERRIDE`, or other privilege-escalating caps.
- **No sudo**: No sudo/doas/su is installed. Never add root escalation mechanisms.
- **TLS-only downloads**: Use `https://` for all fetched URLs. Use `--proto '=https' --tlsv1.2` for curl where supported.
- **No secrets in image**: Never bake API keys, tokens, or credentials into the Dockerfile or rootfs.

### Package Installation

- **System packages** (apt): Add to the Dockerfile only. Group related packages. Clean up apt caches in the same RUN layer.
- **User-space tools** (cargo/npm/pip/bun): Add to `agent-setup.sh` for tools needed at runtime. These install into the persistent volume under `/home/agent`.
- Prefer official package registries (apt, crates.io, npmjs, PyPI). Curl-pipe-bash installs are acceptable only from well-known installers (rustup, nvm) and must use HTTPS.
- Pin versions for reproducibility (ARG in Dockerfile, explicit version in agent-setup.sh).

## Editing Guidelines

### Dockerfile

- Each `RUN` block groups related installs. Preserve this structure.
- Minimize total layers, but split large apt-install layers into logical groups — Docker pulls layers concurrently, so multiple moderate layers download faster than one massive layer.
- Always end with apt cache cleanup: `apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin`
- Bump versions via ARGs at top of file.
- If a package needs special capabilities (like `dumpcap`), grant them via `setcap` — never via setuid.
- Test: the agent likely lacks Docker access. CI validates builds on PRs against `master`.

### rootfs/

- `agent-setup.sh`: Runs as `agent` user at container boot. Idempotent — always check before installing.
- s6 service files use execlineb syntax. Service types: `oneshot` (run-once) or `longrun` (daemon).
- Dependencies between services are declared via empty files in `dependencies.d/`.
- Services are registered in `user/contents.d/`.

### docker-compose.yml

- Ports: `4096` (OpenCode), `3000` (OpenChamber).
- `cap_drop: ALL` + selective `cap_add` is intentional. See security model above.

### README Maintenance

When packages or tools are added to (or removed from) the Dockerfile, update the "What's Inside" section of `README.md` to reflect the change.

## Conventions

- LF line endings, spaces for indent, trailing newline (see `.editorconfig`).
- Commit messages: `chore:` prefix, lowercase, concise.
- Branch: `master` is the sole release branch. CI publishes on push to master and weekly.
- CI uses a reusable workflow from `silvenga-docker/building`. Don't modify the workflow unless the upstream contract changes.

## Available Tooling in Image

The built image includes these pre-installed tools (relevant for understanding what's already available before adding new packages):

- **Languages**: Python 3, Bun, Node 20 (via nvm), Rust/Cargo (via rustup)
- **Build**: build-essential, cmake, clang, lld, pkg-config, libssl-dev, libclang-dev
- **CLI**: git, curl, wget, jq, ripgrep, fd-find, sqlite3, unzip, 7zip, gnupg, less
- **Data**: postgresql-client, redis-tools
- **Network**: openssh-client, nmap, tshark, tcpdump, socat, mtr-tiny, dnsutils, whois, proxychains4

Check existing packages before adding duplicates.

## Self-Installation of Tools

When you need a tool that isn't in the image:

1. **System-level** (requires root/apt): Add it to the appropriate `RUN` block in the Dockerfile. Group with similar packages.
2. **User-space** (cargo/npm/pip/bun): Add it to `agent-setup.sh` with an idempotent check. It installs into the persistent `/home/agent` volume at boot.
3. No approval needed per-package, but follow the security rules above.
