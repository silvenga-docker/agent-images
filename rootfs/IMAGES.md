# Agent Environment

Agent workloads (OpenCode, OpenChamber) run as `agent` (uid 1000) inside a Debian Trixie container. The container init (PID 1) and Docker daemon run as root — no escalation path to root is available.

## Constraints

- **No root access.** sudo, su, and privilege escalation are not available.
- **System files are ephemeral.** Changes to `/usr`, `/etc`, `/bin`, `/lib`, and other system paths are wiped when the image is rebuilt. Do not modify system directories.
- **Persistent storage.** `/home/agent` is a persistent Docker volume; files here survive restarts and reboots.
- **Temporary storage.** `/tmp` is available for scratch work. Contents may or may not survive container restarts — treat it as unreliable between runs. It is sized as a Docker volume (many GB), not memory-backed.

## Installed Tools

**CLI**
`git`, `curl`, `jq`, `less`, `unzip`, `7z`/`7zz`, `b3sum`, `gnupg`, `ripgrep` (`rg`), `fdfind` (`fd-find`), `bsdextrautils` (`hexdump`, `col`, etc.)

**Data**
`sqlite3`, `psql` (PostgreSQL client), `redis-cli`

**Network**
`openssh-client`, `nmap`, `mtr`, `socat`, `proxychains4`, `tshark`, `tcpdump` (`dumpcap` has `cap_net_raw`), `dig`/`nslookup`, `whois`

**Build**
`gcc`, `g++`, `clang`, `lld`, `cmake`, `make`, `pkg-config`, `libssl-dev`, `libclang-dev`

**Runtimes** (user-space, persistent in `/home/agent`)
- `python3`, `pip` (`python3-pip`), `pipx`
- Rust / Cargo: `~/.cargo` — `cargo`, `rustc`, `rustup`
- Node 20 / npm / npx: `~/.nvm/current/bin`
- Bun: `~/.bun` — `bun`, `bunx`

**Containers**
`docker`, `docker compose` — inner Docker daemon runs inside this container (Docker-in-Docker)

## PATH

```
~/.cargo/bin
~/.bun/bin
~/.nvm/current/bin
~/.local/bin
/usr/local/bin  (and standard system paths)
```

## Installing New Tools

`apt` and system directories are off-limits. Install tools user-scoped:

| Method | Command | Destination |
|--------|---------|-------------|
| Rust binary | `cargo install <crate>` | `~/.cargo/bin` |
| Node package | `bun add -g <pkg>` or `npm install -g <pkg>` | `~/.bun/bin` |
| Python package | `pip install --user <pkg>` | `~/.local/lib`; binary in `~/.local/bin` |
| Python app | `pipx install <pkg>` | `~/.local/bin` |
| Static binary | Download to `~/.local/bin` and `chmod +x` | `~/.local/bin` |

For other install locations, add to `~/.bashrc` and re-source.

## Restarting the Container

Run `reboot` (or `/usr/local/bin/reboot`) to halt the container. If Docker is configured with a restart policy (`restart: always` or `restart: unless-stopped`), the container restarts automatically. Contents of `/tmp` may or may not persist across restarts.
