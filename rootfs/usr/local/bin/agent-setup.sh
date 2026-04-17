#!/usr/bin/env bash
set -e

: "${CARGO_HOME:?CARGO_HOME is unset or empty}"
: "${NVM_DIR:?NVM_DIR is unset or empty}"
: "${BUN_INSTALL:?BUN_INSTALL is unset or empty}"

echo "Ensuring tools are installed for user $(id -un)..."

if [ ! -d "$CARGO_HOME" ]; then
    echo "Installing Cargo/Rustup..."
    RUSTUP_VERSION=1.29.0
    RUSTUP_SHA256=4acc9acc76d5079515b46346a485974457b5a79893cfb01112423c89aeb5aa10
    curl -fsSL "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init" -o /tmp/rustup-init
    echo "${RUSTUP_SHA256}  /tmp/rustup-init" | sha256sum -c -
    chmod +x /tmp/rustup-init
    /tmp/rustup-init -y
    rm /tmp/rustup-init
else
    echo "Cargo/Rustup already installed."
fi

if [ ! -d "$NVM_DIR" ]; then
    echo "Installing nvm..."
    NVM_VERSION=v0.40.1
    NVM_SHA256=abdb525ee9f5b48b34d8ed9fc67c6013fb0f659712e401ecd88ab989b3af8f53
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" -o /tmp/nvm-install.sh
    echo "${NVM_SHA256}  /tmp/nvm-install.sh" | sha256sum -c -
    bash /tmp/nvm-install.sh
    rm /tmp/nvm-install.sh
fi

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if ! nvm ls 20 >/dev/null 2>&1; then
    echo "Installing Node 20..."
    nvm install 20
fi
nvm alias default 20
nvm use default
ln -sfn "$(dirname "$(dirname "$(nvm which default)")")" "$NVM_DIR/current"

if [ ! -d "$BUN_INSTALL" ]; then
    echo "Installing Bun..."
    BUN_VERSION=1.1.20
    BUN_SHA256=6cb70ad0349a2cecc94ab2113cd1d07a5779aae77c71cab1cf20c881ac0c0775
    curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-x64.zip" -o /tmp/bun-linux-x64.zip
    echo "${BUN_SHA256}  /tmp/bun-linux-x64.zip" | sha256sum -c -
    unzip -q /tmp/bun-linux-x64.zip -d /tmp/bun-extract
    mkdir -p "${BUN_INSTALL}/bin"
    mv /tmp/bun-extract/bun-linux-x64/bun "${BUN_INSTALL}/bin/bun"
    ln -sf "${BUN_INSTALL}/bin/bun" "${BUN_INSTALL}/bin/bunx"
    rm -rf /tmp/bun-linux-x64.zip /tmp/bun-extract
fi

# If the configured storage driver doesn't match what Podman's libpod database recorded, the database
# wins and overrides storage.conf — causing a startup failure. Clear stale storage so Podman reinitializes.
CONFIGURED_DRIVER=$(awk -F'"' '/^driver/{print $2}' /etc/containers/storage.conf 2>/dev/null || true)
STORAGE_DIR="${HOME}/.local/share/containers/storage"
DB_DRIVER_FILE="${STORAGE_DIR}/db.sql"
if [ -n "$CONFIGURED_DRIVER" ] && [ -d "$STORAGE_DIR" ]; then
    # libpod records the driver in its bolt/sqlite db; the overlay dir existing when vfs is configured
    # is a reliable proxy for a mismatch from a previous overlay-based deployment.
    if [ "$CONFIGURED_DRIVER" = "vfs" ] && [ -d "${STORAGE_DIR}/overlay" ]; then
        echo "Detected stale overlay storage with vfs driver configured — clearing container storage..."
        rm -rf "$STORAGE_DIR"
    fi
fi

# This has to happen after bun, since the install script is going to install openchamber as a bun package.
echo "Installing OpenChamber..."
bun add -g @openchamber/web@latest
