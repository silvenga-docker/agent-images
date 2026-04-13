#!/usr/bin/env bash
set -e

echo "Ensuring tools are installed for user $(id -un)..."

# Install Cargo (Rustup) if missing
if [ ! -d "$CARGO_HOME" ]; then
    echo "Installing Cargo/Rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
else
    echo "Cargo/Rustup already installed."
fi

# Install nvm and node 20 if missing
if [ ! -d "$NVM_DIR" ]; then
    echo "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# Load nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node 20
if ! nvm ls 20 >/dev/null 2>&1; then
    echo "Installing Node 20..."
    nvm install 20
fi
nvm alias default 20
nvm use default
ln -sfn "$(dirname "$(dirname "$(nvm which default)")")" "$NVM_DIR/current"

# Install OpenChamber
echo "Ensuring OpenChamber is installed..."
curl -fsSL https://raw.githubusercontent.com/btriapitsyn/openchamber/main/scripts/install.sh | bash

# Add opencode completion to .bashrc
if ! grep -q "opencode completion" ~/.bashrc 2>/dev/null; then
    echo "Adding opencode completion to .bashrc..."
    opencode completion >> ~/.bashrc
fi
