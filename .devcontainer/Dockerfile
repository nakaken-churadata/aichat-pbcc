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

# gitleaks のインストール
RUN wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.1/gitleaks_8.18.1_linux_x64.tar.gz \
    && tar -xzf gitleaks_8.18.1_linux_x64.tar.gz \
    && mv gitleaks /usr/local/bin/ \
    && rm gitleaks_8.18.1_linux_x64.tar.gz

# Claude Code CLI のインストール
# 注: 実際のインストール方法は Claude Code の公式ドキュメントに従ってください
RUN curl -fsSL https://raw.githubusercontent.com/anthropics/claude-code/main/install.sh | bash

# 作業ディレクトリの設定
WORKDIR /workspace

# devcontainer 環境であることを示すファイルを作成
RUN touch /.devcontainer_marker

# デフォルトシェルを bash に設定
ENV SHELL=/bin/bash

# vscode ユーザーに切り替え
USER vscode
