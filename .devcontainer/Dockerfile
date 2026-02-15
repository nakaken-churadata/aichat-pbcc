# ベースイメージ: Node.js 20 with Debian
FROM mcr.microsoft.com/devcontainers/javascript-node:20-bookworm

# 環境変数
ENV DEBIAN_FRONTEND=noninteractive

# システムパッケージの更新と必要なツールのインストール
RUN apt-get update && apt-get install -y \
    git \
    tmux \
    curl \
    wget \
    vim \
    jq \
    python3 \
    python3-pip \
    iptables \
    ipset \
    aggregate \
    dnsutils \
    && rm -rf /var/lib/apt/lists/*

# ロケール設定と日本語フォントのインストール
RUN apt-get update && apt-get install -y \
    locales \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i -E 's/# (ja_JP.UTF-8)/\1/' /etc/locale.gen \
    && sed -i -E 's/# (en_US.UTF-8)/\1/' /etc/locale.gen \
    && locale-gen

# 環境変数の設定（ロケール）
ENV LANG=ja_JP.UTF-8 \
    LC_ALL=ja_JP.UTF-8 \
    LANGUAGE=ja_JP:en

# gitleaks のインストール（マルチアーキテクチャ対応）
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        GITLEAKS_ARCH="x64"; \
    elif [ "$ARCH" = "arm64" ]; then \
        GITLEAKS_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.1/gitleaks_8.18.1_linux_${GITLEAKS_ARCH}.tar.gz && \
    tar -xzf gitleaks_8.18.1_linux_${GITLEAKS_ARCH}.tar.gz && \
    mv gitleaks /usr/local/bin/ && \
    rm gitleaks_8.18.1_linux_${GITLEAKS_ARCH}.tar.gz

# Claude Code CLI のインストール（npmパッケージを使用）
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# PATH に追加（npmグローバルパッケージのパス）
ENV PATH="/home/node/.local/bin:/usr/local/share/npm-global/bin:${PATH}"

# 作業ディレクトリの設定
WORKDIR /workspace

# devcontainer 環境であることを示すファイルを作成
RUN touch /.devcontainer_marker

# デフォルトシェルを bash に設定
ENV SHELL=/bin/bash

# node ユーザーに切り替え（ベースイメージのデフォルトユーザー）
USER node
