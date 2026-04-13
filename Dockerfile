FROM debian:trixie-slim AS base

ARG URL_7Z=https://github.com/ip7z/7zip/releases/download/26.00/7z2600-linux-x64.tar.xz
ARG S6_OVERLAY_VERSION=3.2.2.0
ARG OPENCODE_VERSION=1.4.3

RUN set -xe \
    && apt-get update \
    && apt-get dist-upgrade -y \
    # Common
    && apt-get install -y \
    wget \
    xz-utils \
    apt-transport-https \
    bash \
    ca-certificates \
    curl \
    git \
    less \
    openssh-client \
    python3 \
    build-essential \
    pkg-config \
    libssl-dev \
    ripgrep \
    fd-find \
    # Rust build deps
    cmake \
    clang \
    lld \
    libclang-dev \
    # General CLI
    jq \
    sqlite3 \
    unzip \
    dnsutils \
    # Dev Tooling \
    postgresql-client \
    redis-tools \
    # Python
    python3-pip \
    pipx \
    # Network debugging \
    whois \
    nmap \
    mtr-tiny \
    tshark \
    tcpdump \
    socat \
    # Proxying \
    proxychains4 \
    # 7zz
    && wget ${URL_7Z} -O 7z.tar.xz \
    && tar xvf 7z.tar.xz -C /tmp/ \
    && install /tmp/7zz /usr/bin/7zz \
    && install /tmp/7zz /usr/bin/7z \
    && rm 7z.tar.xz \
    # Init
    && wget https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz -O s6-overlay-noarch.tar.xz \
    && wget https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz -O s6-overlay-x86_64.tar.xz \
    && tar -C / -Jxpf s6-overlay-noarch.tar.xz \
    && tar -C / -Jxpf s6-overlay-x86_64.tar.xz \
    && rm s6-overlay-noarch.tar.xz \
    && rm s6-overlay-x86_64.tar.xz \
    # Cleanup
    && apt-get purge -y apt-transport-https \
    && apt-get autoremove -y --purge \
    && apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

RUN curl -fsSL https://bun.sh/install | bash \
    && install /root/.bun/bin/bun /usr/local/bin/bun \
    && ln -s bun /usr/local/bin/bunx \
    && rm -rf /root/.bun

RUN groupadd -g 1000 agent \
    && useradd -u 1000 -g 1000 -m -s /bin/bash agent \
    && chown -R agent:agent /home/agent

RUN curl -L -O https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-x64.tar.gz \
    && tar xvf opencode-linux-x64.tar.gz \
    && install opencode /usr/local/bin/opencode \
    && rm opencode-linux-x64.tar.gz opencode

COPY rootfs/ /
RUN chmod +x /usr/local/bin/agent-setup.sh \
    && mkdir -p /run /var/run \
    && chown -R agent:agent /run \
    && chown -R agent:agent /var/run \
    && chown -R agent:agent /command \
    && chown -R agent:agent /package \
    && chown -R agent:agent /etc/s6-overlay

# Ensure no setuid/setgid bits are set.
RUN find / -perm /6000 -type f -exec chmod a-s {} \; 2>/dev/null || true

LABEL org.opencontainers.image.authors="Mark Lopez <m@silvenga.com>" \
    org.opencontainers.image.source="https://github.com/silvenga-docker/agent-images"

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_KEEP_ENV=1 \
    PAGER=cat \
    BUN_INSTALL="/home/agent/.bun" \
    CARGO_HOME="/home/agent/.cargo" \
    NVM_DIR="/home/agent/.nvm" \
    PATH="/home/agent/.cargo/bin:/home/agent/.bun/bin:/home/agent/.nvm/current/bin:/home/agent/.local/bin:${PATH}"

USER agent
WORKDIR /home/agent
VOLUME [ "/home/agent" ]

ENTRYPOINT ["/init"]
