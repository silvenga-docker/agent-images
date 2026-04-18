FROM debian:trixie-slim AS base

ARG URL_7Z=https://github.com/ip7z/7zip/releases/download/26.00/7z2600-linux-x64.tar.xz
ARG URL_7Z_SHA256=c74dc4a48492cde43f5fec10d53fb2a66f520e4a62a69d630c44cb22c477edc6
ARG S6_OVERLAY_VERSION=3.2.2.0
ARG S6_OVERLAY_NOARCH_SHA256=85848f6baab49fb7832a5557644c73c066899ed458dd1601035cf18e7c759f26
ARG S6_OVERLAY_X86_64_SHA256=5a09e2f1878dc5f7f0211dd7bafed3eee1afe4f813e872fff2ab1957f266c7c0
ARG OPENCODE_VERSION=1.4.3
ARG OPENCODE_SHA256=34d503ebb029853293be6fd4d441bbb2dbb03919bfa4525e88b1ca55d68f3e17

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -xe \
    && apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
        xz-utils \
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
        gnupg \
        libcap2-bin \
        cmake \
        clang \
        lld \
        libclang-dev \
        jq \
        sqlite3 \
        unzip \
        dnsutils \
        postgresql-client \
        redis-tools \
        python3-pip \
        pipx \
        whois \
        nmap \
        mtr-tiny \
        tshark \
        tcpdump \
        socat \
        proxychains4 \
    && curl -fsSL ${URL_7Z} -o /tmp/7z.tar.xz \
    && echo "${URL_7Z_SHA256}  /tmp/7z.tar.xz" | sha256sum -c - \
    && tar xf /tmp/7z.tar.xz -C /tmp/ \
    && install /tmp/7zz /usr/bin/7zz \
    && install /tmp/7zz /usr/bin/7z \
    && rm /tmp/7z.tar.xz /tmp/7zz \
    && curl -fsSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz -o /tmp/s6-overlay-noarch.tar.xz \
    && echo "${S6_OVERLAY_NOARCH_SHA256}  /tmp/s6-overlay-noarch.tar.xz" | sha256sum -c - \
    && curl -fsSL https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz -o /tmp/s6-overlay-x86_64.tar.xz \
    && echo "${S6_OVERLAY_X86_64_SHA256}  /tmp/s6-overlay-x86_64.tar.xz" | sha256sum -c - \
    && tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz \
    && rm /tmp/s6-overlay-noarch.tar.xz /tmp/s6-overlay-x86_64.tar.xz

RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian trixie stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        containerd.io \
        docker-ce \
        docker-ce-cli \
        docker-compose-plugin \
        fuse-overlayfs \
    && apt-get -q clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /var/cache/apt/*.bin

RUN groupadd -g 1000 agent \
    && useradd -u 1000 -g 1000 -m -s /bin/bash agent \
    && usermod -aG docker agent \
    && chown -R agent:agent /home/agent \
    && curl -fsSL https://github.com/sst/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-x64.tar.gz -o /tmp/opencode.tar.gz \
    && echo "${OPENCODE_SHA256}  /tmp/opencode.tar.gz" | sha256sum -c - \
    && tar xf /tmp/opencode.tar.gz -C /tmp/ \
    && install /tmp/opencode /usr/local/bin/opencode \
    && rm /tmp/opencode.tar.gz /tmp/opencode

COPY rootfs/ /
RUN chmod +x /usr/local/bin/agent-setup.sh \
    && mkdir -p /run /var/run

LABEL org.opencontainers.image.authors="Mark Lopez <m@silvenga.com>" \
    org.opencontainers.image.source="https://github.com/silvenga-docker/agent-images"

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_KEEP_ENV=1 \
    PAGER=cat \
    BUN_INSTALL="/home/agent/.bun" \
    CARGO_HOME="/home/agent/.cargo" \
    NVM_DIR="/home/agent/.nvm" \
    PATH="/home/agent/.cargo/bin:/home/agent/.bun/bin:/home/agent/.nvm/current/bin:/home/agent/.local/bin:${PATH}"

RUN setcap cap_net_raw,cap_net_admin=eip /usr/bin/dumpcap

WORKDIR /home/agent
VOLUME [ "/home/agent" ]

ENTRYPOINT ["/init"]
