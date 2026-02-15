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
    && rm -rf /var/lib/apt/lists/*

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

# Claude Code CLI のインストール（オプショナル）
# 注: インストールスクリプトが存在しない場合はスキップされます
# 手動インストールが必要な場合は、docs/devcontainer-setup.md を参照してください
RUN curl -fsSL https://raw.githubusercontent.com/anthropics/claude-code/main/install.sh 2>/dev/null | bash || \
    echo "⚠️  Claude Code CLI の自動インストールをスキップしました。手動インストールが必要な場合があります。"

# 作業ディレクトリの設定
WORKDIR /workspace

# devcontainer 環境であることを示すファイルを作成
RUN touch /.devcontainer_marker

# デフォルトシェルを bash に設定
ENV SHELL=/bin/bash

# vscode ユーザーに切り替え
USER vscode
